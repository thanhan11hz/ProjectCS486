-- ============================================================================
-- CC-04 -- SESSION 2 (WITH enforcement)  [advisory recording side]
-- A staff member records a NEW advisory maintenance record for space X-100
-- covering the period of Session 1's booking (08:00-12:00). Because
-- usp_record_maintenance also takes the space-row UPDLOCK + HOLDLOCK, this
-- recording BLOCKS behind Session 1's pending booking (which is inside the
-- WAITFOR DELAY between its INSERT and COMMIT). Only after the booking commits
-- does the advisory record commit -- so it lands AFTER the booking's
-- acknowledgement and is outside the booking-time window (Q-05). No booking ever
-- carries a NULL acknowledgement while an advisory was active at booking time.
--
-- Launch this in Query window 2 one second after session-1.sql is started.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
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

-- The advisory was recorded AFTER Session 1's booking committed (it blocked
-- behind the space lock).
SELECT maintenance_id, space_code, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
   AND start_time >= '2026-09-01 00:00'
   AND start_time <  '2026-09-02 00:00'
 ORDER BY maintenance_id;
GO