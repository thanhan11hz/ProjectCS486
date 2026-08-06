-- ============================================================================
-- CC-04 -- SESSION 2 (WITH enforcement)  [advisory recording side]
-- A staff member records a NEW advisory maintenance record for space X-100 that
-- covers the period of Session 1's booking. Because usp_record_maintenance also
-- takes the space-row UPDLOCK + HOLDLOCK, this recording blocks until Session 1's
-- booking snapshot + acknowledgement commits. Result: if the advisory had
-- committed before the snapshot it is acknowledged; otherwise it lands after the
-- acknowledgement and is outside the booking-time window. No booking can carry a
-- NULL acknowledgement while the advisory was active at booking time.
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