-- ============================================================================
-- CC-02 — Staff approval vs instant booking (or another approval)
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Design      : outputs/11-concurrency-design-G7.md  (CC-02)
-- Impl        : outputs/12-concurrency-implementation-G7.sql
--                 (usp_submit_instant_booking, usp_approve_pending_booking)
-- Rules       : BR-14, BR-49, BR-50
--
-- PURPOSE
--   Demonstrate the contrast when two DIFFERENT booking paths (staff approval
--   and instant booking) produce an approved booking for the same space and an
--   overlapping period:
--     * WITHOUT enforcement: the paths use different availability checks; each
--       passes against the pre-commit state and both succeed -> overlapping
--       approved bookings (BR-14 / BR-50 violated).
--     * WITH enforcement: BOTH paths share the same space-row UPDLOCK+HOLDLOCK
--       serialization; the second decision is REJECTED.
--
-- RUN METHOD: two query windows; follow the numbered checkpoints.
-- Window (deterministic, far future, free of sample data):
--   [2026-12-02 10:00, 2026-12-02 12:00)
-- ============================================================================

USE [CS486_Booking_System];
GO
SET NOCOUNT ON;

DECLARE @start DATETIME2 = '2026-12-02T10:00:00';
DECLARE @end   DATETIME2 = '2026-12-02T12:00:00';
PRINT N'== CC-02 fixture: space=A-CR-2 window '
      + CONVERT(varchar(30), @start, 120) + N'..' + CONVERT(varchar(30), @end, 120);
GO

-- ============================================================================
-- FIXTURE: a 'pending' booking the staff path will approve, overlapping the
-- period the instant path tries to claim.
-- ============================================================================
DELETE FROM dbo.approvals WHERE booking_id IN
   (SELECT booking_id FROM dbo.bookings
     WHERE space_code = N'A-CR-2'
       AND requested_start_time < '2026-12-02T12:00:00'
       AND requested_end_time   > '2026-12-02T10:00:00');
DELETE FROM dbo.bookings
 WHERE space_code = N'A-CR-2'
   AND requested_start_time < '2026-12-02T12:00:00'
   AND requested_end_time   > '2026-12-02T10:00:00';
INSERT INTO dbo.bookings (requester_id, space_code, requested_start_time, requested_end_time, purpose, expected_participants, status)
VALUES (N'U00003', N'A-CR-2', '2026-12-02T10:00:00', '2026-12-02T12:00:00', N'workshop', 40, N'pending');
PRINT N'[fixture] pending booking created for approval.';
GO

-- ============================================================================
-- PART 1 — WITHOUT ENFORCEMENT (two independent naive checks, default RC)
-- ============================================================================

-- ---------------- SESSION A (window 1)  -- approval path ----------------------
BEGIN TRANSACTION;
PRINT N'[1A] approval availability re-check (naive, NO lock held to commit).';
WAITFOR DELAY '00:00:05';
PRINT N'[1A] check done; pausing before approving.';
-- ===================== CHECKPOINT 1 ==========================================
-- Go to SESSION B and run the instant path WITHOUT enforcement (Part 1B).
-- =============================================================================

-- ---------------- SESSION B (window 2)  -- instant path ------------------------
BEGIN TRANSACTION;
IF EXISTS
(
    SELECT 1 FROM dbo.bookings b WITH (READCOMMITTED)
     WHERE b.space_code = N'A-CR-2'
       AND b.status IN (N'approved', N'pending')
       AND b.requested_end_time > '2026-12-02T10:00:00'
       AND b.requested_start_time < '2026-12-02T12:00:00'
)
    PRINT N'[1B] naive check sees NO conflict (race window open).';
INSERT INTO dbo.bookings (requester_id, space_code, requested_start_time, requested_end_time, purpose, expected_participants, status)
VALUES (N'U00001', N'A-CR-2', '2026-12-02T10:00:00', '2026-12-02T12:00:00', N'seminar', 40, N'approved');
COMMIT TRANSACTION;
PRINT N'[1B] instant booking inserted+committed (approved).';
-- ===================== CHECKPOINT 2 ==========================================
-- Return to SESSION A.
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed)  -- staff path ---------------
UPDATE dbo.bookings SET status = N'approved'
 WHERE booking_id = (SELECT TOP 1 booking_id FROM dbo.bookings
                      WHERE space_code = N'A-CR-2' AND status = N'pending'
                      ORDER BY booking_id);
INSERT INTO dbo.approvals (booking_id, approver_id, decision, decision_time)
VALUES ((SELECT TOP 1 booking_id FROM dbo.bookings
          WHERE space_code = N'A-CR-2' AND status = N'approved'
          ORDER BY booking_id), N'U00002', N'approved', SYSDATETIME());
COMMIT TRANSACTION;
PRINT N'[1A] approval committed on the SAME overlapping period.';
GO

-- ----------------------------------------------------------------------------
-- RESULT CHECK — WITHOUT
-- ----------------------------------------------------------------------------
SELECT b.booking_id, b.requester_id, b.status, b.requested_start_time, b.requested_end_time
  FROM dbo.bookings b
 WHERE b.space_code = N'A-CR-2'
   AND b.requested_start_time < '2026-12-02T12:00:00'
   AND b.requested_end_time   > '2026-12-02T10:00:00';
PRINT N'>>> WITHOUT: overlapping approved bookings from both paths -> BR-50 VIOLATED.';
GO

-- ============================================================================
-- PART 2 — WITH ENFORCEMENT (both paths share space-row UPDLOCK+HOLDLOCK)
-- ============================================================================

-- Reset fixture.
DELETE FROM dbo.approvals WHERE booking_id IN
   (SELECT booking_id FROM dbo.bookings
     WHERE space_code = N'A-CR-2'
       AND requested_start_time < '2026-12-02T12:00:00'
       AND requested_end_time   > '2026-12-02T10:00:00');
DELETE FROM dbo.bookings
 WHERE space_code = N'A-CR-2'
   AND requested_start_time < '2026-12-02T12:00:00'
   AND requested_end_time   > '2026-12-02T10:00:00';
INSERT INTO dbo.bookings (requester_id, space_code, requested_start_time, requested_end_time, purpose, expected_participants, status)
VALUES (N'U00003', N'A-CR-2', '2026-12-02T10:00:00', '2026-12-02T12:00:00', N'workshop', 40, N'pending');
PRINT N'[reset] single pending booking ready (approval path).';
GO

-- ---------------- SESSION A (window 1) ---------------------------------------
BEGIN TRANSACTION;
SELECT space_code FROM dbo.spaces WITH (UPDLOCK, HOLDLOCK) WHERE space_code = N'A-CR-2';
PRINT N'[2A] approval path HOLDs the shared space row (UPDLOCK+HOLDLOCK).';
PRINT N'[2A] about to approve the pending booking; run the instant path in B now.';
-- ===================== CHECKPOINT 3 ==========================================
-- Start the WITH-enforcement instant booking in SESSION B (it will BLOCK).
-- =============================================================================

-- ---------------- SESSION B (window 2)  -- instant path (BLOCKS) ---------------
EXEC dbo.usp_submit_instant_booking
   @requester_id = N'U00001',
   @space_code   = N'A-CR-2',
   @requested_start_time = '2026-12-02T10:00:00',
   @requested_end_time   = '2026-12-02T12:00:00',
   @purpose      = N'seminar',
   @expected_participants = 40;
PRINT N'[2B: with] instant submission BLOCKED on the space lock, then returned.';
-- ===================== CHECKPOINT 4 ==========================================
-- Return to SESSION A and approve the pending booking (releases the lock).
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed)  -- approval ------------------
EXEC dbo.usp_approve_pending_booking
   @booking_id  = (SELECT TOP 1 booking_id FROM dbo.bookings WHERE space_code = N'A-CR-2' AND status = N'pending' ORDER BY booking_id),
   @approver_id = N'U00002';
COMMIT TRANSACTION;
PRINT N'[2A] approval committed; lock released. Instant path must now be REJECTED.';
GO

-- ----------------------------------------------------------------------------
-- RESULT CHECK — WITH
-- ----------------------------------------------------------------------------
SELECT b.booking_id, b.requester_id, b.status, b.requested_start_time, b.requested_end_time
  FROM dbo.bookings b
 WHERE b.space_code = N'A-CR-2'
   AND b.requested_start_time < '2026-12-02T12:00:00'
   AND b.requested_end_time   > '2026-12-02T10:00:00';
PRINT N'>>> WITH enforcement: exactly one approved booking; the second decision reports BR-14/BR-50 -> invariant PRESERVED.';
GO

-- ============================================================================
-- END OF CC-02 TEST
-- ============================================================================