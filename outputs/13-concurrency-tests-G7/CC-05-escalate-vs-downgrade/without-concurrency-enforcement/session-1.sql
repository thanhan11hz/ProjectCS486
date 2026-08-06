-- ============================================================================
-- CC-05 -- SESSION 1 (WITHOUT enforcement)  [escalation side]
-- Same scenario, without locking. Session 1 reads the advisory level, then
-- escalates to out-of-service. If Session 2 concurrently reads the same
-- "advisory" value and commits its write last, Session 1's decision is
-- silently overwritten -- the final level reflects whichever writer committed
-- last, not the last-committed CHANGE (lost update / BR-47 violation).
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

-- Clean the test space for a deterministic run (test space X-100 is created by
-- data-init.sql; bookings are removed before maintenance for FK safety).
DELETE FROM dbo.bookings WHERE space_code = N'X-100';
DELETE FROM dbo.maintenance_records WHERE space_code = N'X-100';
GO

DECLARE @mtn_id INT;
INSERT INTO dbo.maintenance_records
    (reporter_id, space_code, assigned_staff_id, problem_description,
     start_time, status, impact_level)
VALUES
    (N'U-501', N'X-100', N'FM-502', N'Broken window latch',
     '2026-09-01 08:00:00', N'reported', N'advisory');
SET @mtn_id = SCOPE_IDENTITY();
PRINT N'Prepared advisory record maintenance_id = ' + CAST(@mtn_id AS VARCHAR(20));

-- Start the escalation promptly (1s) so Session 2 (delay 2s) reads the same
-- "advisory" value while Session 1 is inside its read -> write WAITFOR DELAY.
WAITFOR DELAY '00:00:01';

PRINT 'Session 1: escalate maintenance to out-of-service.';
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-502';
GO

-- With no enforcement, the final level reflects whichever writer committed last
-- (here Session 2's downgrade overwrites this escalation) -- a lost update.
SELECT maintenance_id, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
 ORDER BY maintenance_id;
GO