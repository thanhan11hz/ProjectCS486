-- ============================================================================
-- CC-02 -- SESSION 2 (WITHOUT enforcement)  [instant booking path]
-- Submits an instant booking for the SAME space/period as Session 1's pending
-- approval. With the availability check unlocked, this session passes its check
-- against the empty window, then commits its APPROVED booking. Session 1's
-- UNLOCKED approval then passes its re-validation against a state that does not
-- yet include this booking and commits a SECOND approved booking. Together the
-- two sessions produce TWO overlapping approved bookings for the same space,
-- violating BR-14 / BR-50 across the two booking paths.
--
-- Launch this in Query window 2 straight after starting session 1 (it must reach
-- its EXEC before Session 1's approval).
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

SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO