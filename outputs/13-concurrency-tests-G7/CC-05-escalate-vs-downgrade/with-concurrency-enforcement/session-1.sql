-- ============================================================================
-- CC-05 -- SESSION 1 (WITH enforcement)  [escalation side]
-- A maintenance record for space X-100 starts as ADVISORY. This session escalates
-- it to out-of-service while Session 2 concurrently downgrades the SAME record.
-- The escalation reads the record with UPDLOCK (printing the value it read),
-- holds the lock through the in-procedure WAITFOR DELAY, then escalates and
-- commits. Session 2's downgrade blocks on the UPDLOCK, so it only proceeds after
-- this escalation commits and re-reads the FRESH out_of_service level.
--
-- Run procedure.sql once first, then run this in Query window 1 and session-2.sql
-- in Query window 2 a second later.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

-- Clean the test space for a deterministic run.
DELETE FROM dbo.maintenance_records WHERE space_code = N'X-100';
DELETE FROM dbo.bookings WHERE space_code = N'X-100';
GO

-- Prepare an ADVISORY maintenance record (open, reported).
DECLARE @mtn_id INT;
INSERT INTO dbo.maintenance_records
    (reporter_id, space_code, assigned_staff_id, problem_description,
     start_time, status, impact_level)
VALUES
    (N'U-501', N'X-100', N'FM-502', N'Broken window latch',
     '2026-09-01 08:00:00', N'reported', N'advisory');
SET @mtn_id = SCOPE_IDENTITY();
PRINT N'Prepared advisory record maintenance_id = ' + CAST(@mtn_id AS VARCHAR(20));

-- @mtn_id must stay in the same batch as the EXEC (T-SQL variables do not
-- survive a GO batch separator).
WAITFOR DELAY '00:00:01';

PRINT 'Session 1: escalate maintenance to out-of-service.';
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-502';
GO

-- With enforcement, Session 1's escalation took effect (out_of_service) and
-- Session 2's downgrade was applied afterwards to the FRESH value. Check the
-- printed read levels for the evidence.
SELECT maintenance_id, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
 ORDER BY maintenance_id;
GO