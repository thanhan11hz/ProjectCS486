USE [CS486_Booking_System];
GO
SET NOCOUNT ON;

DECLARE @mtn_id INT =
(
    SELECT TOP 1 maintenance_id
    FROM dbo.maintenance_records
    WHERE space_code = N'X-100'
      AND impact_level = N'advisory'
    ORDER BY maintenance_id DESC
);

PRINT N'Escalating advisory maintenance #' + CAST(@mtn_id AS VARCHAR(20));
PRINT N'Session 2: escalate advisory maintenance to out-of-service.';

EXEC dbo.usp_escalate_maintenance_impact
    @maintenance_id = @mtn_id,
    @staff_id = N'FM-302';

SELECT
    maintenance_id,
    space_code,
    impact_level,
    status,
    start_time,
    completion_time
FROM dbo.maintenance_records
WHERE maintenance_id = @mtn_id;
GO