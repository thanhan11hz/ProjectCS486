-- ============================================================================
-- CC-03 -- WITHOUT concurrency enforcement
-- Procedures: usp_submit_booking_pending + usp_escalate_maintenance_impact with
-- all isolation-level statements and locking hints REMOVED. The booking's BR-44
-- check and the escalation's update-and-identify now use plain unlocked reads,
-- so the escalation can commit between the booking's BR-44 check and its commit
-- (the booking is created on an out-of-service space) or the BR-48 identification
-- can miss a concurrently committed booking -- reproducing CC-03.
-- ============================================================================
USE [CS486_Booking_System];
GO
IF OBJECT_ID(N'dbo.usp_submit_booking_pending', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_submit_booking_pending;
IF OBJECT_ID(N'dbo.usp_escalate_maintenance_impact', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_escalate_maintenance_impact;
GO

CREATE PROCEDURE dbo.usp_submit_booking_pending
    @requester_id          VARCHAR(50),
    @space_code            VARCHAR(20),
    @requested_start_time  DATETIME2,
    @requested_end_time    DATETIME2,
    @purpose               VARCHAR(30),
    @expected_participants INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s                                    -- (hint removed)
         WHERE s.space_code = @space_code;

        IF EXISTS
        (
            SELECT 1
              FROM dbo.maintenance_records m
             WHERE m.space_code = @space_code
               AND m.impact_level = N'out_of_service'
               AND m.status IN (N'reported', N'in_progress')
               AND @requested_end_time > m.start_time
               AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time)
        )
        BEGIN
            RAISERROR(N'BR-44: booking overlaps active out-of-service maintenance.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        IF EXISTS
        (
            SELECT 1
              FROM dbo.bookings b
             WHERE b.space_code = @space_code
               AND b.status IN (N'approved', N'pending')
               AND b.requested_end_time > @requested_start_time
               AND b.requested_start_time < @requested_end_time
        )
        BEGIN
            RAISERROR(N'BR-14/BR-50: a conflicting booking already exists.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        INSERT INTO dbo.bookings
            (requester_id, space_code, requested_start_time, requested_end_time,
             purpose, expected_participants, status, advisory_acknowledged)
        VALUES
            (@requester_id, @space_code, @requested_start_time,
             @requested_end_time, @purpose, @expected_participants,
             N'pending',
             CASE WHEN @advisory_count = 0 THEN NULL ELSE 1 END);

        DECLARE @booking INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        PRINT N'Booking #' + CAST(@booking AS VARCHAR(40)) + N' recorded as pending.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
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

        -- BR-48 identification read (now unlocked; may miss a concurrent booking).
        SELECT b.booking_id, b.requester_id, u.email,
               b.requested_start_time, b.requested_end_time
          FROM dbo.bookings b
          JOIN dbo.users u ON u.user_id = b.requester_id
         WHERE b.space_code = @space_code
           AND b.status = N'approved'
           AND b.requested_end_time > @start_time
           AND (@completion IS NULL OR b.requested_start_time < @completion);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO