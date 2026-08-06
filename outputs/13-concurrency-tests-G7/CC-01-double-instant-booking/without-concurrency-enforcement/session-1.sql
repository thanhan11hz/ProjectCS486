-- ============================================================================
-- CC-01 -- SESSION 1 (WITHOUT enforcement)
-- Same scenario as the with-enforcement test, but the procedure now performs a
-- plain unlocked availability check. Session 1 starts, checks availability,
-- inserts its booking, and waits before committing so that Session 2 can run
-- its check WHILE Session 1 is still uncommitted.
-- ============================================================================
USE [CS486_Booking_System];
GO

WAITFOR DELAY '00:00:03';

PRINT 'Session 1: submitting instant booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-101',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'study_group',
    @expected_participants = 20;
GO

-- Final state.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO