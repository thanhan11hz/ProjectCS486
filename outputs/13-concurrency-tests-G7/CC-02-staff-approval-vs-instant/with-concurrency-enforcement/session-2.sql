-- ============================================================================
-- CC-02 -- SESSION 2 (WITH enforcement)  [instant booking path]
-- Submits an instant booking for the same space X-100, same period 09:00-11:00.
-- Because both booking paths take the SAME space-row UPDLOCK + HOLDLOCK, this
-- instant submission serializes with Session 1's approval: one of them blocks
-- and then, seeing the other's committed booking, is rejected.
-- Launch this while Session 1 is still waiting at its WAITFOR DELAY.
-- ============================================================================
USE [CS486_Booking_System];
GO

WAITFOR DELAY '00:00:02';

PRINT 'Session 2: instant booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-202',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'workshop',
    @expected_participants = 30;
GO

SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO