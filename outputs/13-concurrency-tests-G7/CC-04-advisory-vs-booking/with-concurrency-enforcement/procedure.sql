-- ============================================================================
-- CC-04 -- ADVISORY MAINTENANCE RECORDING RACING WITH BOOKING ACKNOWLEDGEMENT
-- Variant: WITH concurrency enforcement
-- Procedures: usp_submit_booking_pending + usp_record_maintenance in the
-- enforcement form (copied from outputs/12-concurrency-implementation-G7.sql)
-- with TEST HOOK delays:
--   * usp_submit_booking_pending: WAITFOR DELAY between the INSERT and the
--     COMMIT. For THIS conflict the vulnerable window is exactly there: the
--     BR-46 trigger validates the acknowledgement at INSERT time (no advisory
--     exists yet); the race is that an advisory may be recorded between that
--     INSERT and the booking's COMMIT. The delay keeps the booking's
--     UPDLOCK + HOLDLOCK on the space row held across the whole window.
--   * usp_record_maintenance: WAITFOR DELAY between the space-row lock
--     acquisition and the INSERT.
--
-- Both procedures take the space-row UPDLOCK + HOLDLOCK, so they serialize: an
-- advisory commits either BEFORE the booking's snapshot (then it is included in
-- the notification, BR-45/BR-46) or AFTER the booking's acknowledgement (outside
-- the booking-time window, Q-05). In this scenario the booking commits first, so
-- the advisory lands after the acknowledgement -> no violation.
--
-- All RAISERROR messages are single string literals (no expression arguments).
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

        -- Serialization point held for the whole transaction.
        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- BR-44: no overlapping active out-of-service maintenance.
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

        WAITFOR DELAY '00:00:05';

        -- BR-45/BR-46: snapshot active advisories under the same space lock.
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        SELECT
            m.maintenance_id,
            m.space_code,
            m.impact_level,
            m.status,
            m.start_time,
            m.completion_time,
            m.problem_description
        FROM dbo.maintenance_records m
        WHERE m.space_code = @space_code
          AND m.impact_level = N'advisory'
          AND m.status IN (N'reported', N'in_progress')
          AND @requested_end_time > m.start_time
          AND (m.completion_time IS NULL
               OR @requested_start_time < m.completion_time);

        -- BR-14 pre-check. Counts ONLY approved bookings (BR-14); a pending
        -- request does not reserve the space, so several overlapping pending
        -- requests may be recorded; the conflict is resolved at approval time.
        IF EXISTS
        (
            SELECT 1
              FROM dbo.bookings b
             WHERE b.space_code = @space_code
               AND b.status = N'approved'
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

        -- ===== TEST HOOK =====
        -- Hold the transaction open AFTER the booking was inserted (BR-46 trigger
        -- validated the NULL acknowledgement while no advisory existed) but BEFORE
        -- it commits. The space-row UPDLOCK + HOLDLOCK is still held, so the
        -- concurrent advisory recording cannot commit in this window. Remove for
        -- production.
       

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

        -- Take the space-row lock so this maintenance state change serializes
        -- against any in-flight booking creation for the space (CC-04).
        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- ===== TEST HOOK =====
        -- Hold the space lock before inserting the maintenance record, so the
        -- recording cannot commit between a booking's advisory snapshot and its
        -- acknowledgement. Remove for production.

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