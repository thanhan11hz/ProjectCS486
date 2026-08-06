-- ============================================================================
-- CC-01 -- SESSION 2 (WITHOUT enforcement)
-- Because the availability check is a plain unlocked read that retains no lock,
-- this session does NOT block on Session 1. It reads the same pre-commit "empty"
-- availability window (Session 1's booking is still uncommitted and therefore
-- invisible), passes its own check, waits out its internal delay and then INSERTs
-- and commits a second approved booking. BOTH bookings are now approved and
-- overlap for the same space -- the double-booking conflict is reproduced (BR-14).
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

-- With enforcement absent, BOTH bookings are approved and overlap: two rows with
-- status = approved covering the same period for the same space.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO