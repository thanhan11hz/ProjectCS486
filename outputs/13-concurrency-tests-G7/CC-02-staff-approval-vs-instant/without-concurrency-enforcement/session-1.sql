-- ============================================================================
-- CC-02 -- SESSION 1 (WITHOUT enforcement)  [staff approval path]
-- Session 2 (instant booking) starts FIRST and passes its unlocked availability
-- check against an empty window, then commits its approved booking. This session
-- waits 3s, prepares a PENDING booking for the same space/period and approves it
-- with the UNLOCKED procedure. The approval's re-validation passes because Session
-- 2's instant booking is not yet committed/visible; the approval then commits a
-- SECOND approved booking that overlaps Session 2's. Both approved bookings exist
-- for the same space -- BR-14 / BR-50 is violated across the two booking paths.
--
-- Run this in Query window 1, then session-2.sql in Query window 2 (Session 2 must
-- start first, as in the enforcement variant).
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

DECLARE @pending_id INT;
INSERT INTO dbo.bookings
    (requester_id, space_code, requested_start_time, requested_end_time,
     purpose, expected_participants, status)
VALUES
    (N'U-201', N'X-100', '2026-09-01 09:00:00', '2026-09-01 11:00:00',
     N'seminar', 25, N'pending');
SET @pending_id = SCOPE_IDENTITY();
PRINT N'Prepared pending booking #' + CAST(@pending_id AS VARCHAR(20));
PRINT 'Session 1: staff approves the pending booking.';

-- @pending_id must stay in the same batch as the EXEC (T-SQL variables do not
-- survive a GO batch separator).
EXEC dbo.usp_approve_pending_booking
    @booking_id   = @pending_id,
    @approver_id  = N'FM-301';
GO

-- With enforcement absent, this approval COMMITS even though Session 2's instant
-- booking for the same space/period was already approved: two overlapping rows.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO