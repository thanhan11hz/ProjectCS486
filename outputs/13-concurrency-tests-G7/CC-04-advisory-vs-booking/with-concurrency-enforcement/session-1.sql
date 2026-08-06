-- ============================================================================
-- CC-04 -- SESSION 1 (WITH enforcement)  [booking creation side]
-- A user submits a pending booking for space X-100 (09:00-11:00) which has NO
-- active advisory maintenance at the start. While Session 2 concurrently
-- records a NEW advisory maintenance record for the same space/period, Session 1
-- holds the space-row UPDLOCK + HOLDLOCK through the snapshot + acknowledgement
-- step. The advisory therefore commits either BEFORE the snapshot (it is
-- acknowledged) or AFTER the acknowledgement (outside the booking-time window).
-- ============================================================================
USE [CS486_Booking_System];
GO

IF NOT EXISTS (SELECT 1 FROM dbo.spaces WHERE space_code = N'X-100')
    INSERT INTO dbo.spaces (space_code, space_type) VALUES (N'X-100', N'classroom');
GO

WAITFOR DELAY '00:00:03';

PRINT 'Session 1: submit pending booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_booking_pending
    @requester_id          = N'U-401',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'training',
    @expected_participants = 18;
GO

SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status, advisory_acknowledged
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO