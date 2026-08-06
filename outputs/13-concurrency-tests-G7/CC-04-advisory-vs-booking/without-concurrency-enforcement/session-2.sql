-- ============================================================================
-- CC-04 -- SESSION 2 (WITHOUT enforcement)  [advisory recording side]
-- Records a NEW advisory maintenance record for the space/period of Session 1's
-- booking. With locking removed, this recording commits between Session 1's
-- snapshot read and its acknowledgement recording, so the booking is created
-- with advisory_acknowledged = NULL while an advisory was already active at
-- booking time (BR-45/BR-46 violation). Compare advisory_acknowledged across the
-- two session outputs.
-- Launch this while Session 1 is waiting at its WAITFOR DELAY.
-- ============================================================================
USE [CS486_Booking_System];
GO

WAITFOR DELAY '00:00:02';

PRINT 'Session 2: record advisory maintenance 08:00-12:00 for space X-100.';
EXEC dbo.usp_record_maintenance
    @reporter_id         = N'U-402',
    @space_code          = N'X-100',
    @assigned_staff_id   = N'FM-403',
    @problem_description = N'Projector lamp flickering',
    @start_time          = '2026-09-01 08:00:00',
    @impact_level        = N'advisory';
GO

SELECT maintenance_id, space_code, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
   AND start_time >= '2026-09-01 00:00'
   AND start_time <  '2026-09-02 00:00'
 ORDER BY maintenance_id;
GO