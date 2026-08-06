-- ============================================================================
-- CC-02 -- SESSION 1 (WITH enforcement)  [staff approval path]
-- Session 2 (instant booking) starts FIRST and holds the space-row lock while it
-- waits inside its procedure. This session waits 3s, prepares a PENDING booking
-- for the same space/period, then attempts to approve it. The approval procedure
-- re-validates availability under the SAME space-row UPDLOCK + HOLDLOCK, so it
-- BLOCKS behind Session 2's instant booking. When Session 2 commits, Session 1
-- re-reads the fresh state, finds the approved instant booking and is REJECTED
-- (BR-14 / BR-50). Only ONE approved booking exists.
--
-- Run this in Query window 1, then run session-2.sql in Query window 2 straight
-- away (Session 2 must start BEFORE this session reaches its EXEC, so it gets the
-- space lock first).
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

-- Clean the test space for a deterministic run.
DELETE a FROM dbo.approvals a
  JOIN dbo.bookings b ON b.booking_id = a.booking_id
 WHERE b.space_code = N'X-100';
DELETE s FROM dbo.sessions s
  JOIN dbo.bookings b ON b.booking_id = s.booking_id
 WHERE b.space_code = N'X-100';
DELETE FROM dbo.bookings WHERE space_code = N'X-100';
DELETE FROM dbo.maintenance_records WHERE space_code = N'X-100';
GO

-- Prepare the pending booking that Session 1 will (try to) approve.
DECLARE @pending_id INT;
INSERT INTO dbo.bookings
    (requester_id, space_code, requested_start_time, requested_end_time,
     purpose, expected_participants, status)
VALUES
    (N'U-201', N'X-100', '2026-09-01 09:00:00', '2026-09-01 11:00:00',
     N'seminar', 25, N'pending');
SET @pending_id = SCOPE_IDENTITY();
PRINT N'Prepared pending booking #' + CAST(@pending_id AS VARCHAR(20));
PRINT 'Session 1: staff approves the pending booking (expect BR-14/BR-50 rejection).';

-- @pending_id must stay in the same batch as the EXEC (T-SQL variables do not
-- survive a GO batch separator).
EXEC dbo.usp_approve_pending_booking
    @booking_id   = @pending_id,
    @approver_id  = N'FM-301';
GO

-- Final state: exactly ONE approved booking (Session 2's). The pending booking
-- from this session remains pending (its approval was rejected).
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO