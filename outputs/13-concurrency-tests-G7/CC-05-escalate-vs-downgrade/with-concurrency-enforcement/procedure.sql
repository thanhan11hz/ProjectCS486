-- ============================================================================
-- CC-05 -- CONCURRENT ESCALATION / DOWNGRADE OF THE SAME MAINTENANCE RECORD
-- Variant: WITH concurrency enforcement (lost-update prevention)
-- Procedures: usp_escalate_maintenance_impact + usp_downgrade_maintenance_impact
-- in the enforcement form (copied verbatim from outputs/12-concurrency-
-- implementation-G7.sql). Both read the maintenance record with UPDLOCK, so two
-- concurrent level changes cannot lose one another: each decision is applied to
-- the FRESH, last-committed level (BR-47).
-- ============================================================================
USE [CS486_Booking_System];
GO
IF OBJECT_ID(N'dbo.usp_escalate_maintenance_impact', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_escalate_maintenance_impact;
IF OBJECT_ID(N'dbo.usp_downgrade_maintenance_impact', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_downgrade_maintenance_impact;
GO

-- ----------------------------------------------------------------------------
-- usp_escalate_maintenance_impact  (OP-05, CC-05 side)
-- ----------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_escalate_maintenance_impact
    @maintenance_id INT,
    @staff_id       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

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
          FROM dbo.maintenance_records m WITH (UPDLOCK)
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
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- Escalation rule: only advisory -> out_of_service.
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

-- ----------------------------------------------------------------------------
-- usp_downgrade_maintenance_impact  (OP-06, CC-05 side)
-- ----------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_downgrade_maintenance_impact
    @maintenance_id INT,
    @staff_id       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Updated-level UPDLOCK read to prevent lost updates (BR-47).
        DECLARE @current_level VARCHAR(20), @status VARCHAR(20);
        SELECT @current_level = m.impact_level, @status = m.status
          FROM dbo.maintenance_records m WITH (UPDLOCK)
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