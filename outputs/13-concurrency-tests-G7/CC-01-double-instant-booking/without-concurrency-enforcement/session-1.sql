-- ============================================================================
-- CC-01 -- SESSION 1 (WITHOUT enforcement)
-- Same double-instant-booking scenario, but the procedure now runs a plain
-- UNLOCKED availability check followed by an in-procedure WAITFOR DELAY. Session 1
-- passes the check against an empty window and then sleeps (in its transaction,
-- but holding NO locks), so Session 2 can also pass the check while Session 1's
-- booking is still uncommitted and invisible.
--
-- Run procedure.sql once first (or deploy it), then run this in Query window 1
-- and, ~2 seconds later, session-2.sql in Query window 2.
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

PRINT 'Session 1: instant booking 09:00-11:00 for X-100 (U-101).';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-101',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'student_activity',
    @expected_participants = 20;
GO

-- Final state from Session 1's perspective.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO