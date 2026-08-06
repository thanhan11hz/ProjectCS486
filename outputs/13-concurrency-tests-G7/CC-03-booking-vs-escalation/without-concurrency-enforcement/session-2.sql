-- ============================================================================
-- CC-03 -- SESSION 2 (WITHOUT enforcement)  [escalation side]
-- Escalates the space's advisory maintenance to out-of-service with NO locking.
-- Because the escalation happens against an unlocked space, it can complete
-- its BR-48 affected-booking identification BEFORE a concurrent booking commits;
-- the booking then commits afterwards on the now-out-of-service space and is
-- neither rejected by BR-44 (it already validated) nor found by the
-- identification (BR-48). The invariant is violated.
-- Launch this while Session 1 is waiting at its WAITFOR DELAY.
-- ============================================================================
USE [CS486_Booking_System];
GO

DECLARE @mtn_id INT =
    (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
      WHERE space_code = N'X-100' AND impact_level = N'advisory'
      ORDER BY maintenance_id DESC);
PRINT N'Escalating advisory maintenance #' + CAST(@mtn_id AS VARCHAR(20));

WAITFOR DELAY '00:00:02';

PRINT 'Session 2: escalate advisory maintenance to out-of-service.';
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-302';
GO

-- With enforcement OFF, an overlapping booking may still be present for this
-- now-out-of-service period.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
   AND status = N'approved'
 ORDER BY booking_id;
GO