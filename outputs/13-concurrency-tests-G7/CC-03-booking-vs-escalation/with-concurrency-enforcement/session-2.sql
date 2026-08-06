-- ============================================================================
-- CC-03 -- SESSION 2 (WITH enforcement)  [escalation side]
-- Escalates the space's advisory maintenance record to out-of-service. Because
-- escalation also takes the space-row UPDLOCK + HOLDLOCK, it BLOCKS behind the
-- concurrent instant booking (Session 1) until that booking commits. Only then
-- does the escalation perform its UPDATE and its BR-48 identification of affected
-- approved bookings -- so the identification reads the freshly committed booking
-- and returns it. No booking is missed (BR-48) and no approved booking exists on
-- a period that was out-of-service at booking time (BR-44).
--
-- Launch this in Query window 2 one second after session-1.sql is started.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

-- Let Session 1 (instant booking) reach its in-procedure delay first.
WAITFOR DELAY '00:00:02';
GO

-- Find the advisory maintenance record prepared for space X-100. Declared in the
-- SAME batch as the EXEC (T-SQL variables do not survive a GO separator).
DECLARE @mtn_id INT =
    (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
      WHERE space_code = N'X-100' AND impact_level = N'advisory'
      ORDER BY maintenance_id DESC);
PRINT N'Escalating advisory maintenance #' + CAST(@mtn_id AS VARCHAR(20));
PRINT 'Session 2: escalate advisory maintenance to out-of-service.';
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-302';
GO

-- With enforcement, the BR-48 result set above contains Session 1's approved
-- booking (it committed before the escalation). The maintenance record is now
-- out-of-service.
SELECT maintenance_id, space_code, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
 ORDER BY maintenance_id;
GO