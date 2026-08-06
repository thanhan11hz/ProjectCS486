-- ============================================================================
-- CC-05 -- WITHOUT concurrency enforcement (lost update)
-- Procedures: usp_escalate_maintenance_impact + usp_downgrade_maintenance_impact
-- with all isolation-level statements and locking hints REMOVED. The current
-- level is read with a plain unlocked SELECT; two concurrent level changes
-- therefore read the SAME "advisory", both write their own value, and the LAST
-- WRITER silently overwrites the OTHER's committed decision (lost update, BR-47).
-- ============================================================================
USE [CS486_Booking_System];
GO
IF OBJECT_ID(N'dbo.usp_escalate_maintenance_impact', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_escalate_maintenance_impact;
IF OBJECT_ID(N'dbo.usp_downgrade_maintenance_impact', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_downgrade_maintenance_impact;
GO

CREATE PROCEDURE dbo.usp_escalate_maintenance_impact
    @maintenance_id INT,
    @staff_id       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_code     VARCHAR(20);
        DECLARE @start_time     DATETIME2;
        DECLARE @completion     DATETIME2;
        DECLARE @current_level  VARCHAR(20);

        SELECT @space_code     = m.space_code,
               @start_time     = m.start_time,
               @completion     = m.completion_time,
               @current_level  = m.impact_level
          FROM dbo.maintenance_records m                      -- (hint removed)
         WHERE m.maintenance_id = @maintenance_id
           AND m.status IN (N'reported', N'in_progress');

        IF @space_code IS NULL
        BEGIN
            RAISERROR(N'BR-47: maintenance record not found or not open.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s                                    -- (hint removed)
         WHERE s.space_code = @space_code;

        IF @current_level <> N'advisory'
        BEGIN
            RAISERROR(N'BR-47: only advisory records escalate to out-of-service.', 16, 1);
            ROLLBACK;
            RETURN;
        END;

        UPDATE dbo.maintenance_records
           SET impact_level = N'out_of_service'
         WHERE maintenance_id = @maintenance_id
           AND status IN (N'reported', N'in_progress');

        COMMIT TRANSACTION;
        PRINT N'Maintenance #' + CAST(@maintenance_id AS VARCHAR(40))
              + N' escalated to out_of_service.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE PROCEDURE dbo.usp_downgrade_maintenance_impact
    @maintenance_id INT,
    @staff_id       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @current_level VARCHAR(20), @status VARCHAR(20);
        SELECT @current_level = m.impact_level, @status = m.status
          FROM dbo.maintenance_records m                      -- (hint removed)
         WHERE m.maintenance_id = @maintenance_id;

        IF @status = N'completed'
        BEGIN
            RAISERROR(N'BR-47: the impact level of a completed maintenance '
                      + N'record cannot be changed.', 16, 1);
            ROLLBACK;
            RETURN;
        END;

        UPDATE dbo.maintenance_records
           SET impact_level = N'advisory'
         WHERE maintenance_id = @maintenance_id;

        COMMIT TRANSACTION;
        PRINT N'Maintenance #' + CAST(@maintenance_id AS VARCHAR(40))
              + N' downgraded to advisory.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO