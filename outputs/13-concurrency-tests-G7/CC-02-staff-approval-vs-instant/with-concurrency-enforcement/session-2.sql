-- ============================================================================
-- CC-02 -- SESSION 2 (WITH enforcement)  [instant booking path]
-- Submits an instant booking for the SAME space (X-100) and period (09:00-11:00)
-- as Session 1's pending approval. Because both booking paths take the SAME
-- space-row UPDLOCK + HOLDLOCK, this session acquires the space lock FIRST (it
-- starts before Session 1 reaches its approval EXEC), waits out its internal
-- delay, then INSERTs and commits an APPROVED booking. Session 1's approval is
-- then serialised behind it and rejected.
--
-- Run this in Query window 2 straight after starting session-1.sql (Session 2
-- must reach its EXEC before Session 1's approval EXEC).
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

PRINT 'Session 2: instant booking 09:00-11:00 for X-100 (U-202).';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-202',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'workshop',
    @expected_participants = 30;
GO

-- This session's booking is now approved; Session 1's approval will be rejected.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO