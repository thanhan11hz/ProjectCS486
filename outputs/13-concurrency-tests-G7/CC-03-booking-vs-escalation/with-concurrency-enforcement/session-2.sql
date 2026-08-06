-- ============================================================================
-- CC-03 -- SESSION 2 (WITH enforcement)  [escalation side]
-- Escalates the space's advisory maintenance record to out-of-service. Because
-- escalation also takes the space-row UPDLOCK + HOLDLOCK, it serializes with the
-- concurrent booking (Session 1): the escalation cannot commit halfway through
-- the booking's BR-44 check, and the BR-48 identification of affected approved
-- bookings cannot miss a booking that committed concurrently.
-- Launch this while Session 1 is waiting at its WAITFOR DELAY.
-- ============================================================================
USE [CS486_Booking_System];
GO

-- Find the advisory maintenance record prepared for space X-100.
DECLARE @mtn_id INT =
    (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
      WHERE space_code = N'X-100' AND impact_level = N'advisory'
      ORDER BY maintenance_id DESC);
PRINT N'Escalating advisory maintenance #' + CAST(@mtn_id AS VARCHAR(20));

WAITFOR DELAY '00:00:02';

PRINT 'Session 2: escalate advisory maintenance to out-of-service.';
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-302';
GO

-- Result set: should be empty if the booking committed before the escalation
-- began, or the affected-booking list if it committed first. Either way, no
-- approved booking ever overlaps an out-of-service period (BR-44).
SELECT maintenance_id, space_code, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
 ORDER BY maintenance_id;
GO