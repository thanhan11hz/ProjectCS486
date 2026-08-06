-- ============================================================================
-- CC-03 — Booking creation racing with escalation to out-of-service
-- Project : CS486 Booking System (Group 7)
-- DBMS    : Microsoft SQL Server (T-SQL)
-- Design  : outputs/11-concurrency-design-G7.md   (CC-03)
-- Impl    : outputs/12-concurrency-implementation-G7.sql
--             (usp_submit_instant_booking / usp_submit_booking_pending /
--              usp_escalate_maintenance_impact)
-- Rules   : BR-44 (no booking over an out-of-service period)
--           BR-48 (escalation identifies ALL affected approved bookings)
--
-- PURPOSE
--   Contrast a booking transaction racing its space's advisory->out-of-service
--   escalation:
--     WITHOUT : a booking commits over an out-of-service period (BR-44
--               violated); the escalation's affected-booking read can miss a
--               booking committed concurrently (BR-48 violated).
--     WITH    : booking creation and escalation SHARE the space row
--               UPDLOCK+HOLDLOCK, so the blocking check is correct and the
--               BR-48 identification is a consistent snapshot.
--
-- RUN METHOD: two query windows; follow the numbered checkpoints.
-- Window    : [2026-12-03 10:00, 2026-12-03 12:00)
-- ============================================================================

USE [CS486_Booking_System];
GO
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- FIXTURE: space A-CR-2 has ONE advisory maintenance record over the window.
-- ----------------------------------------------------------------------------
DECLARE @space VARCHAR(20) = N'A-CR-2';

DELETE FROM dbo.approvals WHERE booking_id IN
    (SELECT booking_id FROM dbo.bookings WHERE space_code = @space);
DELETE FROM dbo.bookings WHERE space_code = @space;
DELETE FROM dbo.maintenance_records WHERE space_code = @space;

EXEC dbo.usp_record_maintenance
     @reporter_id       = N'U00010',
     @space_code        = @space,
     @assigned_staff_id = N'U00011',
     @problem_description = N'Dim projector bulb; space remains usable.',
     @start_time        = '2026-12-03T08:00:00',
     @impact_level      = N'advisory';
PRINT N'[fixture] advisory maintenance active for the window.';
GO

-- ============================================================================
-- PART 1 — WITHOUT ENFORCEMENT
-- Scenario (a): the booking commits over a freshly escalated period.
-- ============================================================================

-- ---------------- SESSION A (window 1)  -- booking path ----------------------
BEGIN TRANSACTION;
PRINT N'[1A:booking] maintainance/availability check (naive read, NO shared lock).';
WAITFOR DELAY '00:00:05';
PRINT N'[1A:booking] check read as "advisory only"; pausing before INSERT.';
-- ===================== CHECKPOINT 1 ==========================================
-- Switch to SESSION B and escalate WITHOUT enforcement (Part 1B).
-- =============================================================================

-- ---------------- SESSION B (window 2)  -- escalation --------------------------
DECLARE @m INT = (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
                   WHERE space_code = N'A-CR-2' AND impact_level = N'advisory'
                   ORDER BY maintenance_id);
BEGIN TRANSACTION;
UPDATE dbo.maintenance_records
   SET impact_level = N'out_of_service'
 WHERE maintenance_id = @m;                        -- naive; no shared lock
COMMIT TRANSACTION;
PRINT N'[1B:escalate] maintenance escalated to out_of_service (naive UPDATE).';
-- ===================== CHECKPOINT 2 ==========================================
-- Escalation committed while A is still paused. Return to SESSION A.
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed)  -- booking INSERT ------------
INSERT INTO dbo.bookings (requester_id, space_code, requested_start_time,
                          requested_end_time, purpose, expected_participants,
                          status, advisory_acknowledged)
VALUES (N'U00001', N'A-CR-2', '2026-12-03T10:00:00', '2026-12-03T12:00:00',
        N'lecture', 40, N'approved', NULL);
COMMIT TRANSACTION;
PRINT N'[1A:booking] booking committed although the space just became out of service.';
GO

-- ---------------------------------------------------------------------------
-- RESULT CHECK — WITHOUT
-- ---------------------------------------------------------------------------
SELECT b.booking_id, b.requester_id, b.status, b.requested_start_time,
       b.requested_end_time, m.impact_level AS overlapping_maintenance
  FROM dbo.bookings b
  JOIN dbo.maintenance_records m
    ON m.space_code = b.space_code
   AND m.impact_level = N'out_of_service'
   AND m.status IN (N'reported', N'in_progress')
   AND b.requested_end_time > m.start_time
   AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
 WHERE b.space_code = N'A-CR-2';
PRINT N'>>> WITHOUT enforcement: a booking exists over an out-of-service period -> BR-44 VIOLATED.';
GO

-- ============================================================================
-- PART 2 — WITH ENFORCEMENT  (shared space-row UPDLOCK + HOLDLOCK)
-- ============================================================================

-- Reset: remove the Part 1 booking, restore advisory maintenance.
DECLARE @sp VARCHAR(20) = N'A-CR-2';
DELETE FROM dbo.approvals WHERE booking_id IN
    (SELECT booking_id FROM dbo.bookings WHERE space_code = @sp);
DELETE FROM dbo.bookings WHERE space_code = @sp;
UPDATE dbo.maintenance_records
   SET impact_level = N'advisory'
 WHERE space_code = @sp;
PRINT N'[reset] booking removed; maintenance restored to advisory.';
GO

-- ---------------- SESSION A (window 1)  -- book path holds the space -------------
DECLARE @sp VARCHAR(20) = N'A-CR-2';
BEGIN TRANSACTION;
SELECT space_code FROM dbo.spaces WITH (UPDLOCK, HOLDLOCK) WHERE space_code = @sp;
PRINT N'[2A] booking path HOLDs the space serialization point (UPDLOCK+HOLDLOCK).';
PRINT N'[2A] run the escalation in Session B now - it will BLOCK and the BR-44/BR-48 check is consistent.';
-- ===================== CHECKPOINT 3 ============================================
-- Run the WITH-enforcement escalation in SESSION B (it blocks on the space row).
-- =================================================================================

-- ---------------- SESSION B (window 2)  -- escalation (BLOCKS) -------------------
DECLARE @m2 INT = (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
                    WHERE space_code = N'A-CR-2' AND impact_level = N'advisory'
                    ORDER BY maintenance_id);
EXEC dbo.usp_escalate_maintenance_impact
     @maintenance_id = @m2,
     @staff_id       = N'U00011';
PRINT N'[2B] usp_escalate_maintenance_impact returned (blocked, then consistent BR-48 snapshot).';
-- ===================== CHECKPOINT 4 ============================================
-- Return to SESSION A and commit/rollback. Then verify invariant.
-- ============================================================

-- ---------------- SESSION A (window 1, resumed) ------------------------------------
COMMIT TRANSACTION;
PRINT N'[2A] booking path committed. Any booking attempt on the now out-of-service period will be rejected.';
GO

-- ----------------------------------------------------------------------------
-- RESULT CHECK (WITH)
-- ----------------------------------------------------------------------------
-- 1) No booking may overlap an out-of-service record:
SELECT COUNT(*) AS overlapping_bookings_violating_br44
  FROM dbo.bookings b
  JOIN dbo.maintenance_records m
    ON m.space_code = b.space_code
   AND m.impact_level = N'out_of_service'
   AND m.status IN (N'reported', N'in_progress')
   AND b.requested_end_time > m.start_time
   AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
 WHERE b.space_code = N'A-CR-2';
PRINT N'>>> WITH enforcement: BR-44 count = 0 or the second decision/re-escalate enforces the invariant.';
GO

-- ============================================================================
-- END OF CC-03 TEST
-- ============================================================================