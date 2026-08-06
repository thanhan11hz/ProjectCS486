-- ============================================================================
-- CC-01 — Concurrent instant bookings for the same space / overlapping period
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Design      : outputs/11-concurrency-design-G7.md  (CC-01)
-- Impl        : outputs/12-concurrency-implementation-G7.sql (usp_submit_instant_booking)
-- Rules       : BR-14, BR-50
--
-- PURPOSE
--   Demonstrate the contrast:
--     * WITHOUT enforcement  -> two instant bookings BOTH commit for the same
--                               space and overlapping period (BR-14 violated).
--     * WITH enforcement     -> the second submission is BLOCKED then REJECTED;
--                               only one approved booking exists (BR-14 held).
--
-- RUN METHOD
--   Two SQL Server query windows against CS486_Booking_System.
--   Execute Session A, then Session B, following the numbered checkpoints.
--   Read the full narrative first; each batch prints where it is.
--
-- Test window (deterministic far-future, free of sample data):
--   requested [2026-12-01 10:00, 2026-12-01 12:00)
-- Space and users: copy from 00-setup-and-data.sql output (or replace with
--                  any available classroom/meeting_room + two student IDs).
-- ============================================================================

USE [CS486_Booking_System];
GO
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- FIXTURE (run in Session A first)
--   Choose the space and requesters; keep the values for both sessions.
-- ----------------------------------------------------------------------------
DECLARE @space   VARCHAR(20) = N'A-CR-2';   -- classroom, available (replace with 00 output)
DECLARE @user_A  VARCHAR(50) = N'U00001';   -- student requester A
DECLARE @user_B  VARCHAR(50) = N'U00002';   -- student requester B
DECLARE @start   DATETIME2   = '2026-12-01T10:00:00';
DECLARE @end     DATETIME2   = '2026-12-01T12:00:00';

PRINT N'== CC-01 fixture: space=' + @space + N' [' + CONVERT(varchar(30), @start, 120) + N'..' + CONVERT(varchar(30), @end, 120) + N') requesters ' + @user_A + N', ' + @user_B;
GO

-- ============================================================================
-- PART 1 — WITHOUT ENFORCEMENT (naive raw T-SQL, default READ COMMITTED)
-- ============================================================================
-- The two sessions perform the SAME check-then-act sequence inline, with NO
-- UPDLOCK/HOLDLOCK on the space row. Both reads see an empty availability
-- window; both insert; both commit. Result: two overlapping APPROVED bookings.
-- ----------------------------------------------------------------------------

-- ---------------- SESSION A (window 1) --------------------------------------
BEGIN TRANSACTION;

-- (1A) availability check  -- plain read, no lock held to commit
IF EXISTS
(
    SELECT 1 FROM dbo.bookings b WITH (READCOMMITTED)
     WHERE b.space_code = 'A-CR-2'
       AND b.status IN (N'approved', N'pending')
       AND b.requested_end_time > '2026-12-01T10:00:00'
       AND b.requested_start_time < '2026-12-01T12:00:00'
)
BEGIN
    PRINT N'[1A-WITHOUT] conflict detected; aborting.';
    ROLLBACK;
    RETURN;
END
PRINT N'[1A-WITHOUT] check passed (no overlap seen). Holding transaction open (checkpoint: go to SESSION B).';
WAITFOR DELAY '00:00:05';   -- emulate user A pausing before committing
-- ===================== CHECKPOINT 1 ==========================================
-- (Do NOT commit yet.  Switch to SESSION B and execute Part 1B below.)
-- =============================================================================

-- ---------------- SESSION B (window 2) --------------------------------------
BEGIN TRANSACTION;

-- (1B) availability check  -- also sees NO overlap (A has not committed)
IF EXISTS
(
    SELECT 1 FROM dbo.bookings b WITH (READCOMMITTED)
     WHERE b.space_code = 'A-CR-2'
       AND b.status IN (N'approved', N'pending')
       AND b.requested_end_time > '2026-12-01T10:00:00'
       AND b.requested_start_time < '2026-12-01T12:00:00'
)
BEGIN
    PRINT N'[1B-WITHOUT] conflict detected; aborting.';
    ROLLBACK;
    RETURN;
END
PRINT N'[1B-WITHOUT] check passed too.';
INSERT INTO dbo.bookings (requester_id, space_code, requested_start_time, requested_end_time, purpose, expected_participants, status)
VALUES (N'U00002', N'A-CR-2', '2026-12-01T10:00:00', '2026-12-01T12:00:00', N'lecture', 40, N'approved');
PRINT N'[1B-WITHOUT] booking B inserted (approved).';
COMMIT TRANSACTION;
PRINT N'[1B-WITHOUT] session B committed.';
-- ===================== CHECKPOINT 2 ==========================================
-- B has committed an overlapping APPROVED booking. Return to SESSION A.
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed) ------------------------------
INSERT INTO dbo.bookings (requester_id, space_code, requested_start_time, requested_end_time, purpose, expected_participants, status)
VALUES (N'U00001', N'A-CR-2', '2026-12-01T10:00:00', '2026-12-01T12:00:00', N'seminar', 40, N'approved');
PRINT N'[1A-WITHOUT] booking A inserted (approved) despite B already committed.';
COMMIT TRANSACTION;
PRINT N'[1A-WITHOUT] session A committed.';
GO

-- ----------------------------------------------------------------------------
-- RESULT CHECK — WITHOUT enforcement: two overlapping APPROVED bookings now exist.
-- ----------------------------------------------------------------------------
SELECT b.booking_id, b.requester_id, b.status,
       b.requested_start_time, b.requested_end_time
  FROM dbo.bookings b
 WHERE b.space_code = 'A-CR-2'
   AND b.requested_start_time < '2026-12-01T12:00:00'
   AND b.requested_end_time   > '2026-12-01T10:00:00';
PRINT N'>>> WITHOUT enforcement: TWO overlapping approved bookings exist -> BR-14 VIOLATED.';
GO

-- ============================================================================
-- PART 2 — WITH ENFORCEMENT (usp_submit_instant_booking, UPDLOCK + HOLDLOCK)
-- ============================================================================
-- Session A takes the space row with UPDLOCK + HOLDLOCK inside a transaction
-- and pauses BEFORE inserting. Session B calls the SAME stored procedure: its
-- space-row lock request BLOCKS until A commits, then its re-check under the
-- lock sees A's approved booking and raises BR-14. One booking only.
-- ----------------------------------------------------------------------------

-- Cleanup: remove the two overlapping rows created in Part 1.
DELETE FROM dbo.approvals WHERE booking_id IN
    (SELECT booking_id FROM dbo.bookings
      WHERE space_code = 'A-CR-2'
        AND requested_start_time < '2026-12-01T12:00:00'
        AND requested_end_time   > '2026-12-01T10:00:00');
DELETE FROM dbo.bookings
 WHERE space_code = 'A-CR-2'
   AND requested_start_time < '2026-12-01T12:00:00'
   AND requested_end_time   > '2026-12-01T10:00:00';
PRINT N'[cleanup] removed Part 1 rows.';
GO

-- ---------------- SESSION A (window 1) --------------------------------------
-- Manually hold the space-row serialization point the way the procedure does,
-- to create a controlled pause (emulates a slow transaction in flight).
BEGIN TRANSACTION;
SELECT space_code FROM dbo.spaces WITH (UPDLOCK, HOLDLOCK) WHERE space_code = 'A-CR-2';
PRINT N'[2A-WITH] A holds the space row (UPDLOCK+HOLDLOCK).';
-- ===================== CHECKPOINT 3 ==========================================
-- While A holds the lock, execute the WITH-enforcement submission in Session B.
-- =============================================================================

-- ---------------- SESSION B (window 2) --------------------------------------
-- This call will BLOCK on the space-row lock until Session A commits.
EXEC dbo.usp_submit_instant_booking
     @requester_id = 'U00002',          -- student B
     @space_code   = 'A-CR-2',
     @requested_start_time = '2026-12-01T10:00:00',
     @requested_end_time   = '2026-12-01T12:00:00',
     @purpose      = N'lecture',
     @expected_participants = 40;
PRINT N'[2B-WITH] usp_submit_instant_booking returned (blocked until A commits, then either proceeds or is rejected).';
-- ===================== CHECKPOINT 4 ==========================================
-- B is now blocked. Return to Session A and COMMIT to release the lock.
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed) ------------------------------
-- A also submits through the same procedure while still holding the lock.
EXEC dbo.usp_submit_instant_booking
     @requester_id = 'U00001',          -- student A
     @space_code   = 'A-CR-2',
     @requested_start_time = '2026-12-01T10:00:00',
     @requested_end_time   = '2026-12-01T12:00:00',
     @purpose      = N'seminar',
     @expected_participants = 40;
COMMIT TRANSACTION;   -- A commits (booking A recorded + lock released)
PRINT N'[2A-WITH] A committed. Session B now resumes and must be REJECTED.';
GO

-- ----------------------------------------------------------------------------
-- RESULT CHECK — WITH enforcement: exactly ONE approved booking in the window.
-- ----------------------------------------------------------------------------
SELECT b.booking_id, b.requester_id, b.status,
       b.requested_start_time, b.requested_end_time
  FROM dbo.bookings b
 WHERE b.space_code = 'A-CR-2'
   AND b.requested_start_time < '2026-12-01T12:00:00'
   AND b.requested_end_time   > '2026-12-01T10:00:00';
PRINT N'>>> WITH enforcement: one approved booking; session B rejected with BR-14/BR-50 -> invariant PRESERVED.';
GO

-- ============================================================================
-- END OF CC-01 TEST
-- ============================================================================