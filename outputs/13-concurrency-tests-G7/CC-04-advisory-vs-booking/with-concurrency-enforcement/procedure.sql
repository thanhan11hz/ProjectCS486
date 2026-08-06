-- ============================================================================
-- CC-04 -- ADVISORY MAINTENANCE RECORDING RACING WITH BOOKING ACKNOWLEDGEMENT
-- Variant: WITH concurrency enforcement
-- Procedures: usp_submit_booking_pending + usp_record_maintenance in the
-- enforcement form (copied verbatim from outputs/12-concurrency-implementation
-- -G7.sql).
--
--   * usp_submit_booking_pending holds the space-row UPDLOCK + HOLDLOCK while it
--     captures the advisory snapshot and records the acknowledgement.
--   * usp_record_maintenance takes the space-row UPDLOCK + HOLDLOCK too.
-- The two serialize on the space row: an advisory commits either BEFORE the
-- booking's snapshot (then it is included in the notification, BR-45/BR-46) or
-- AFTER the booking's acknowledgement (outside the booking-time window, Q-05).
-- ============================================================================
USE [CS486_Booking_System];
GO
IF OBJECT_ID(N'dbo.usp_submit_booking_pending', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_submit_booking_pending;
IF OBJECT_ID(N'dbo.usp_record_maintenance', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_record_maintenance;
GO

-- ----------------------------------------------------------------------------
-- usp_submit_booking_pending  (OP-02, CC-04 booking side)
-- ----------------------------------------------------------------------------
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
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- BR-44 out-of-service check.
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

        -- BR-45/BR-46: advisory snapshot under the SAME space lock.
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        -- BR-14 pre-check.
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

-- ----------------------------------------------------------------------------
-- usp_record_maintenance  (OP-04, CC-04 advisory-recording side)
-- ----------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_record_maintenance
    @reporter_id         VARCHAR(50),
    @space_code          VARCHAR(20),
    @assigned_staff_id   VARCHAR(50),
    @problem_description NVARCHAR(1000),
    @start_time          DATETIME2,
    @impact_level        VARCHAR(20),   -- N'out_of_service' or N'advisory'
    @maintenance_id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        INSERT INTO dbo.maintenance_records
            (reporter_id, space_code, assigned_staff_id,
             problem_description, start_time, status, impact_level)
        VALUES
            (@reporter_id, @space_code, @assigned_staff_id,
             @problem_description, @start_time, N'reported', @impact_level);

        SET @maintenance_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
        PRINT N'Maintenance #' + CAST(@maintenance_id AS VARCHAR(40))
              + N' recorded as ' + @impact_level + N'.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO