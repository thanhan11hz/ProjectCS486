-- ============================================================================
-- CC-01 -- SESSION 2 (WITH enforcement)
-- Second user submits an instant booking for the SAME space/time as Session 1.
-- Because Session 1 holds the UPDLOCK + HOLDLOCK on the space row, this session
-- BLOCKS at the availability check until Session 1 commits, then reads the
-- FRESH committed state (now containing Session 1's booking) and is rejected
-- with BR-14/BR-50. The double booking is PREVENTED.
--
-- Launch this while Session 1's EXEC is still waiting/executing.
-- ============================================================================
USE [CS486_Booking_System];
GO

WAITFOR DELAY '00:00:03';

PRINT 'Session 2: submitting instant booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-102',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'lecture',
    @expected_participants = 15;
GO

-- If enforcement is working this should never print an approved booking for
-- an overlapping second period. The SELECT shows the (single) final booking.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO