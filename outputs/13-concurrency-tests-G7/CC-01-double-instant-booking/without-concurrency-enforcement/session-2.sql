-- ============================================================================
-- CC-01 -- SESSION 2 (WITHOUT enforcement)
-- Because the availability check is a plain unlocked read that releases its
-- lock immediately, Session 2 does NOT block on Session 1. Both sessions see an
-- empty availability window and both commit, producing TWO overlapping approved
-- bookings for the same space -- the double-booking conflict is reproduced.
-- ============================================================================
USE [CS486_Booking_System];
GO

WAITFOR DELAY '00:00:04';

PRINT 'Session 2: submitting instant booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-102',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'lecture',
    @expected_participants = 15;
GO

-- With enforcement absent, BOTH bookings are now approved and overlap.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO