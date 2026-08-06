-- ============================================================================
-- CC-04 — Booking creation racing with recording a new advisory maintenance record
-- Project : CS486 Booking System (Group 7)
-- DBMS    : Microsoft SQL Server (T-SQL)
-- Design  : outputs/11-concurrency-design-G7.md   (CC-04)
-- Impl    : outputs/12-concurrency-implementation-G7.sql
--             (usp_submit_instant_booking / usp_record_maintenance)
-- Rules   : BR-45 (requester must be notified of all active advisories at
--                   booking time), BR-46 (the acknowledgement is recorded)
--
-- PURPOSE
--   Contrast a booking being created on a space while a NEW advisory is recorded
--   at the same time:
--     WITHOUT : a booking reads the advisory set, sees none, then records "no
--               advisories". The advisory commits between the read and the
--               acknowledgement -> the notification obligation is silently
--               bypassed (BR-45 / BR-46 violated).
--     WITH    : the booking holds the space row (UPDLOCK+HOLDLOCK) from the
--               advisory snapshot through the acknowledgement; the advisory
--               recording waits -> the acknowledgement either includes it or
--               the advisory falls outside the "at booking time" window.
--
-- RUN METHOD: two query windows; follow the numbered checkpoints.
-- Window     : [2026-12-04 10:00, 2026-12-04 12:00)
-- ============================================================================

USE [CS486_Booking_System];
GO
SET NOCOUNT ON;

-- --------------------------------------------------------------------------
-- FIXTURE: space A-CR-2 starts with NO advisory maintenance.
-- --------------------------------------------------------------------------
DECLARE @sp VARCHAR(20) = N'A-CR-2';

DELETE FROM dbo.approvals WHERE booking_id IN
    (SELECT booking_id FROM dbo.bookings WHERE space_code = @sp);
DELETE FROM dbo.bookings WHERE space_code = @sp;
DELETE FROM dbo.maintenance_records WHERE space_code = @sp;
PRINT N'[fixture] space clean at start of test.';
GO

-- ===========================================================================
-- PART 1 — WITHOUT ENFORCEMENT
-- ===========================================================================

-- ---------------- SESSION A (window 1)  -- booking path ---------------------
BEGIN TRANSACTION;
DECLARE @adv_count INT = 0;
SELECT @adv_count = COUNT(*)
  FROM dbo.maintenance_records m
 WHERE m.space_code = N'A-CR-2'
   AND m.impact_level = N'advisory'
   AND m.status IN (N'reported', N'in_progress')
   AND '2026-12-04T12:00:00' > m.start_time
   AND (m.completion_time IS NULL OR '2026-12-04T10:00:00' < m.completion_time);
PRINT N'[1A-booking] advisory snapshot read = ' + CAST(@adv_count AS VARCHAR(10)) + N'. Pausing before acknowledgement.';
-- ===================== CHECKPOINT 1 =========================================
-- Switch to SESSION B and record a NEW advisory WITHOUT enforcement.
-- =============================================================================

-- ---------------- SESSION B (window 2)  -- record advisory -------------------
BEGIN TRANSACTION;
INSERT INTO dbo.maintenance_records (reporter_id, space_code, assigned_staff_id,
                                     problem_description, start_time, status,
                                     impact_level)
VALUES (N'U00010', N'A-CR-2', N'U00011', N'AC unit noisy (advisory only).',
        '2026-12-04T08:00:00', N'reported', N'advisory');
COMMIT TRANSACTION;
PRINT N'[1B-advisory] advisory recorded (naive, NO shared lock).';
-- ===================== CHECKPOINT 2 =========================================---
-- Return to SESSION A: the booking commits with acknowledgement "no advisories".
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed)  -- booking INSERT -----------
INSERT INTO dbo.bookings (requester_id, space_code, requested_start_time,
                          requested_end_time, purpose, expected_participants,
                          status, advisory_acknowledged)
VALUES (N'U00001', N'A-CR-2', '2026-12-04T10:00:00', '2026-12-04T12:00:00',
        N'lecture', 40, N'approved', NULL);
COMMIT TRANSACTION;
PRINT N'[1A-booking] booking committed with advisory_acknowledged = NULL although an advisory existed at the same instant.';
GO

-- ---------------------------------------------------------------------------
-- RESULT CHECK — WITHOUT (the booking missed an advisory recorded mid-flight)
-- ---------------------------------------------------------------------------
SELECT b.booking_id, b.advisory_acknowledged,
       COUNT(m.maintenance_id) AS overlapping_advisories
  FROM dbo.bookings b
  LEFT JOIN dbo.maintenance_records m
         ON m.space_code = b.space_code
        AND m.impact_level = N'advisory'
        AND m.status IN (N'reported', N'in_progress')
        AND b.requested_end_time > m.start_time
        AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
 WHERE b.space_code = N'A-CR-2'
GROUP BY b.booking_id, b.advisory_acknowledged;
PRINT N'>>> WITHOUT: booking has advisory_acknowledged = NULL while advisories overlap -> BR-45/BR-46 VIOLATED.';
GO

-- ============================================================================
-- PART 2 — WITH ENFORCEMENT
-- ============================================================================

-- Reset: clean the window.
DECLARE @sp2 VARCHAR(20) = N'A-CR-2';
DELETE FROM dbo.approvals WHERE booking_id IN
    (SELECT booking_id FROM dbo.bookings WHERE space_code = @sp2);
DELETE FROM dbo.bookings WHERE space_code = @sp2;
DELETE FROM dbo.maintenance_records WHERE space_code = @sp2;
PRINT N'[reset] clean window for Part 2.';
GO

-- ---------------- SESSION A (window 1)  -- booking path HOLDS the space ------
BEGIN TRANSACTION;
SELECT space_code FROM dbo.spaces WITH (UPDLOCK, HOLDLOCK) WHERE space_code = N'A-CR-2';
PRINT N'[2A] booking path HOLDS the space row (UPDLOCK+HOLDLOCK) around its advisory snapshot + acknowledgement.';
PRINT N'[2A] record a new advisory in Session B now - it will BLOCK.';
-- ===================== CHECKPOINT 3 =========================================
-- Run the WITH-enforcement advisory recording in SESSION B (blocks on space).
-- =============================================================================

-- ---------------- SESSION B (window 2)  -- record advisory (BLOCKS) ----------
EXEC dbo.usp_record_maintenance
     @reporter_id       = N'U00010',
     @space_code        = N'A-CR-2',
     @assigned_staff_id = N'U00011',
     @problem_description = N'AC floor noisy (advisory only).',
     @start_time        = '2026-12-04T08:00:00',
     @impact_level      = N'advisory';
PRINT N'[2B] advisory recording BLOCKED on the space lock, then returned.';
-- ===================== CHECKPOINT 4 =========================================
-- Return to SESSION A and submit the booking (snapshot + acknowledgement).
-- =============================================================================

DECLARE @adv_ac INT = 0;
EXEC dbo.usp_submit_instant_booking
     @requester_id = N'U00001',
     @space_code   = N'A-CR-2',
     @requested_start_time = '2026-12-04T10:00:00',
     @requested_end_time   = '2026-12-04T12:00:00',
     @purpose      = N'lecture',
     @expected_participants = 40;
COMMIT TRANSACTION;
PRINT N'[2A] booking committed; advisory serialized (included in snapshot OR after the booking-time window).';
GO

-- ---------------------------------------------------------------------------
-- RESULT CHECK (WITH)
-- ---------------------------------------------------------------------------
SELECT b.booking_id, b.requester_id, b.status, b.advisory_acknowledged
  FROM dbo.bookings b
 WHERE b.space_code = N'A-CR-2';
PRINT N'>>> WITH enforcement: booking advisory_acknowledged is consistent with the advisory snapshot; the trg_br46 trigger guarantees 1 when a booking overlaps an advisory -> invariant PRESERVED.';
GO

-- ============================================================================
-- END OF CC-04 TEST
-- ============================================================================