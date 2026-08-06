-- ============================================================================
-- CC-05 -- SESSION 2 (WITH enforcement)  [downgrade side]
-- Downgrades the SAME open maintenance record while Session 1 escalates it.
-- With UPDLOCK on the record, the two operations serialize: whichever commits
-- first becomes the other's fresh starting level, so each decision is applied to
-- the last-committed value and neither is lost (BR-47).
-- Launch this while Session 1 is waiting at its WAITFOR DELAY.
-- ============================================================================
USE [CS486_Booking_System];
GO

WAITFOR DELAY '00:00:02';

DECLARE @mtn_id INT =
    (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
      WHERE space_code = N'X-100' ORDER BY maintenance_id DESC);

PRINT 'Session 2: downgrade maintenance to advisory.';
EXEC dbo.usp_downgrade_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-503';
GO

SELECT maintenance_id, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
 ORDER BY maintenance_id;
GO