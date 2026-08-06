-- ============================================================================
-- CC-01 -- SESSION 2 (WITH enforcement)
-- Second user submits an instant booking for the SAME space/time as Session 1.
-- While Session 1 still holds the space-row UPDLOCK + HOLDLOCK (it is inside the
-- WAITFOR DELAY inside its procedure), this session's procedure BLOCKS at the
-- space-row lock the moment it begins. Once Session 1 commits, Session 2 obtains
-- the lock, re-reads the availability and finds Session 1's approved booking
-- overlapping the period -> it raises BR-14/BR-50 and rolls back.
-- The double booking is PREVENTED: only ONE approved booking exists.
--
-- Launch this in Query window 2 a few seconds after starting session-1.sql.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

PRINT 'Session 2: instant booking 09:00-11:00 for X-100 (U-102).';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-102',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'lecture',
    @expected_participants = 15;
GO

-- With enforcement active, this second booking is rejected; only Session 1's
-- booking exists. (An error message from the BR-14/BR-50 check is expected.)
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO