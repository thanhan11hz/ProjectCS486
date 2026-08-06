-- ============================================================================
-- CC-04 -- SESSION 2 (WITHOUT enforcement)  [advisory recording side]
-- Records a NEW advisory maintenance record (08:00-12:00) for the space/period of
-- Session 1's booking using the UNLOCKED procedure. Because no space lock is
-- taken, this recording COMMITS between Session 1's advisory snapshot and the
-- booking's COMMIT. The booking then finalises with advisory_acknowledged = NULL
-- while the advisory was already active at booking time (BR-45/BR-46 violation).
--
-- Launch this in Query window 2 one second after session-1.sql is started.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

WAITFOR DELAY '00:00:02';
GO

PRINT 'Session 2: record advisory maintenance 08:00-12:00 for space X-100.';
EXEC dbo.usp_record_maintenance
    @reporter_id         = N'U-402',
    @space_code          = N'X-100',
    @assigned_staff_id   = N'FM-403',
    @problem_description = N'Projector lamp flickering',
    @start_time          = '2026-09-01 08:00:00',
    @impact_level        = N'advisory';
GO

-- This advisory committed while Session 1's booking was still uncommitted.
SELECT maintenance_id, space_code, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
   AND start_time >= '2026-09-01 00:00'
   AND start_time <  '2026-09-02 00:00'
 ORDER BY maintenance_id;
GO