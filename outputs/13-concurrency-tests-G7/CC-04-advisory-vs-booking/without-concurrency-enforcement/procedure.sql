-- ============================================================================
-- CC-04 -- WITHOUT concurrency enforcement
-- Procedures: usp_submit_booking_pending + usp_record_maintenance with all
-- isolation-level statements and locking hints REMOVED.
--
-- The TEST HOOK delays are kept so the two sessions overlap in exactly the window
-- that exposes the race. Because no lock is held, Session 2's advisory recording
-- can COMMIT between Session 1's advisory snapshot (0 advisories) and the booking
-- COMMIT. The booking is therefore created with advisory_acknowledged = NULL while
-- an advisory is already active at the time the booking is finalised -- the
-- notification obligation BR-45/BR-46 is silently bypassed (the CC-04 conflict).
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
-- usp_submit_booking_pending  (OP-02, CC-04 booking side, no locking)
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

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s                             -- (locking hint removed)
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

        -- Advisory snapshot (now an unlocked read; can miss a concurrent advisory).
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        -- BR-14 pre-check (unlocked read). Counts ONLY approved bookings;
        -- pending requests do not reserve the space.
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

        WAITFOR DELAY '00:00:05';

        INSERT INTO dbo.bookings
            (requester_id, space_code, requested_start_time, requested_end_time,
             purpose, expected_participants, status, advisory_acknowledged)
        VALUES
            (@requester_id, @space_code, @requested_start_time,
             @requested_end_time, @purpose, @expected_participants,
             N'pending',
             CASE WHEN @advisory_count = 0 THEN NULL ELSE 1 END);

        DECLARE @booking INT = SCOPE_IDENTITY();

        -- ===== TEST HOOK ===== (NO lock held; the advisory recording can commit
        -- in this window, before this booking commits).
        

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
-- usp_record_maintenance  (OP-04, CC-04 advisory-recording side, no locking)
-- ----------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_record_maintenance
    @reporter_id         VARCHAR(50),
    @space_code          VARCHAR(20),
    @assigned_staff_id   VARCHAR(50),
    @problem_description NVARCHAR(1000),
    @start_time          DATETIME2,
    @impact_level        VARCHAR(20),
    @maintenance_id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s                             -- (locking hint removed)
         WHERE s.space_code = @space_code;

        INSERT INTO dbo.maintenance_records
            (reporter_id, space_code, assigned_staff_id,
             problem_description, start_time, status, impact_level)
        VALUES
            (@reporter_id, @space_code, @assigned_staff_id,
             @problem_description, @start_time, N'reported', @impact_level);

        SET @maintenance_id = SCOPE_IDENTITY();

        -- Advisory maintenance affects overlapping bookings.
        IF @impact_level = 'advisory'
        BEGIN
            UPDATE b
            SET b.advisory_acknowledged = 1
            FROM dbo.bookings AS b
            WHERE b.space_code = @space_code
              AND b.status IN (N'pending', N'approved')
              AND b.requested_end_time > @start_time;
        END;


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