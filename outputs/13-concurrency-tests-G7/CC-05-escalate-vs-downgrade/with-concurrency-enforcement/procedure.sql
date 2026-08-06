-- ============================================================================
-- CC-05 -- CONCURRENT ESCALATION / DOWNGRADE OF THE SAME MAINTENANCE RECORD
-- Variant: WITH concurrency enforcement (lost-update prevention)
-- Procedures: usp_escalate_maintenance_impact + usp_downgrade_maintenance_impact
-- in the enforcement form (copied from outputs/12-concurrency-implementation-
-- G7.sql) with TEST HOOK additions:
--   * a WAITFOR DELAY between reading the current impact level and the UPDATE
--     (so the two sessions overlap inside the read -> write window), and
--   * a PRINT of the impact level actually read (so the stale-vs-fresh read is
--     observable).
--
-- Both procedures read the maintenance record with UPDLOCK, which is held to the
-- end of the transaction. The second operation therefore BLOCKS until the first
-- commits, then re-reads the FRESH committed level and applies its decision to
-- that value. No committed change is lost (BR-47): in this run Session 1 escalates
-- first and Session 2 then downgrades the fresh out_of_service value.
--
-- All RAISERROR messages are single string literals (no expression arguments).
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

        -- Resolve the record's space with a short navigation read, then acquire
        -- the space lock FIRST (consistent lock ordering shared with the booking
        -- paths), then re-read the record under UPDLOCK (CC-05).
        DECLARE @space_code VARCHAR(20);
        SELECT @space_code = m.space_code
          FROM dbo.maintenance_records m
         WHERE m.maintenance_id = @maintenance_id
           AND m.status IN (N'reported', N'in_progress');

        IF @space_code IS NULL
        BEGIN
            RAISERROR(N'BR-47: maintenance record not found or not open.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- Serialize on the space (CC-03) so the escalation's update-and-identify
        -- holds the booking serialization point.
        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- Re-read the record under UPDLOCK (CC-05) for a fresh, serialized view
        -- of its state.
        DECLARE @start_time    DATETIME2;
        DECLARE @completion    DATETIME2;
        DECLARE @current_level VARCHAR(20);
        SELECT @start_time    = m.start_time,
               @completion    = m.completion_time,
               @current_level = m.impact_level
          FROM dbo.maintenance_records m WITH (UPDLOCK)
         WHERE m.maintenance_id = @maintenance_id
           AND m.status IN (N'reported', N'in_progress');

        IF @current_level IS NULL
        BEGIN
            RAISERROR(N'BR-47: maintenance record not found or not open.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        PRINT N'[escalate] read impact level = ' + CAST(@current_level AS VARCHAR(20));

        -- BR-47: only advisory records escalate to out-of-service.
        IF @current_level <> N'advisory'
        BEGIN
            RAISERROR(N'BR-47: only advisory records escalate to out-of-service.', 16, 1);
            ROLLBACK;
            RETURN;
        END;

        -- ===== TEST HOOK =====
        -- Hold the UPDLOCK on the record between the read and the UPDATE; a
        -- concurrent level change blocks and then re-reads the fresh value.
        WAITFOR DELAY '00:00:05';

        UPDATE dbo.maintenance_records
           SET impact_level = N'out_of_service'
         WHERE maintenance_id = @maintenance_id
           AND status IN (N'reported', N'in_progress');

        -- BR-48: identify approved bookings overlapping the maintenance period.
        SELECT b.booking_id, b.requester_id, u.email,
               b.requested_start_time, b.requested_end_time
          FROM dbo.bookings b
          JOIN dbo.users u ON u.user_id = b.requester_id
         WHERE b.space_code = @space_code
           AND b.status = N'approved'
           AND b.requested_end_time > @start_time
           AND (@completion IS NULL OR b.requested_start_time < @completion);

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

        -- UPDLOCK read to prevent lost updates (BR-47).
        DECLARE @current_level VARCHAR(20), @status VARCHAR(20);
        SELECT @current_level = m.impact_level, @status = m.status
          FROM dbo.maintenance_records m WITH (UPDLOCK)
         WHERE m.maintenance_id = @maintenance_id;

        PRINT N'[downgrade] read impact level = ' + CAST(@current_level AS VARCHAR(20));

        IF @status = N'completed'
        BEGIN
            RAISERROR(N'BR-47: the impact level of a completed maintenance record cannot be changed. Downgrade is only allowed while the record is open.', 16, 1);
            ROLLBACK;
            RETURN;
        END;

        -- ===== TEST HOOK =====
        -- Hold the UPDLOCK on the record between the read and the UPDATE.
        WAITFOR DELAY '00:00:05';

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