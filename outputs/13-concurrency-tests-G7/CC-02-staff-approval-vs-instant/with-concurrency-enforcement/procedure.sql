-- ============================================================================
-- CC-02 -- STAFF APPROVAL RACING WITH AN INSTANT BOOKING (SAME SPACE/PERIOD)
-- Variant: WITH concurrency enforcement
-- Procedures: usp_submit_instant_booking + usp_approve_pending_booking in the
-- enforcement form (copied verbatim from outputs/12-concurrency-implementation
-- -G7.sql). Both booking paths acquire the SAME space-row UPDLOCK + HOLDLOCK, so
-- staff approval and instant booking serialize (BR-50) and cannot both commit.
-- ============================================================================
USE [CS486_Booking_System];
GO
IF OBJECT_ID(N'dbo.usp_submit_instant_booking', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_submit_instant_booking;
IF OBJECT_ID(N'dbo.usp_approve_pending_booking', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_approve_pending_booking;
GO

-- ----------------------------------------------------------------------------
-- usp_submit_instant_booking  (OP-01, CC-02 side)
-- ----------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_submit_instant_booking
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

        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.spaces
             WHERE space_code = @space_code
               AND space_type IN (N'classroom', N'meeting_room')
        )
        BEGIN
            RAISERROR(N'BR-49: this space type is not eligible for instant booking.', 16, 1);
            ROLLBACK;
            RETURN;
        END

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

        -- BR-14/BR-50 availability check.
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
            RAISERROR(N'BR-14/BR-50: a conflicting booking already overlaps the period.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        DECLARE @new_booking_id INT;
        INSERT INTO dbo.bookings
            (requester_id, space_code, requested_start_time, requested_end_time,
             purpose, expected_participants, status, advisory_acknowledged)
        VALUES
            (@requester_id, @space_code, @requested_start_time,
             @requested_end_time, @purpose, @expected_participants,
             N'approved',
             CASE WHEN @advisory_count > 0 THEN 1 ELSE NULL END);

        SET @new_booking_id = SCOPE_IDENTITY();

        DECLARE @approver VARCHAR(50) =
            (SELECT TOP 1 user_id FROM dbo.users
              WHERE role = N'facility_manager' ORDER BY user_id);

        INSERT INTO dbo.approvals (booking_id, approver_id, decision, decision_time)
        VALUES (@new_booking_id, ISNULL(@approver, @requester_id),
                N'approved', SYSDATETIME());

        COMMIT TRANSACTION;
        PRINT N'Instant booking ' + CAST(@new_booking_id AS VARCHAR(40)) + N' approved.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- usp_approve_pending_booking  (OP-03, CC-02 side)
-- ----------------------------------------------------------------------------
CREATE PROCEDURE dbo.usp_approve_pending_booking
    @booking_id   INT,
    @approver_id  VARCHAR(50),
    @decision_note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_code VARCHAR(20);
        DECLARE @requested_start DATETIME2, @requested_end DATETIME2;

        SELECT @space_code     = b.space_code,
               @requested_start = b.requested_start_time,
               @requested_end   = b.requested_end_time
          FROM dbo.bookings b WITH (UPDLOCK)
         WHERE b.booking_id = @booking_id;

        IF @space_code IS NULL
        BEGIN
            RAISERROR(N'Booking %d not found.', 16, 1, @booking_id);
            ROLLBACK;
            RETURN;
        END

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- BR-44 re-validation.
        IF EXISTS
        (
            SELECT 1
              FROM dbo.maintenance_records m
             WHERE m.space_code = @space_code
               AND m.impact_level = N'out_of_service'
               AND m.status IN (N'reported', N'in_progress')
               AND @requested_end > m.start_time
               AND (m.completion_time IS NULL OR @requested_start < m.completion_time)
        )
        BEGIN
            RAISERROR(N'BR-44: cannot approve: space under out-of-service maintenance.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- BR-14/BR-50 re-validation.
        IF EXISTS
        (
            SELECT 1
              FROM dbo.bookings b2
             WHERE b2.space_code = @space_code
               AND b2.booking_id <> @booking_id
               AND b2.status IN (N'approved', N'pending')
               AND b2.requested_end_time > @requested_start
               AND b2.requested_start_time < @requested_end
        )
        BEGIN
            RAISERROR(N'BR-14/BR-50: approving would create an overlapping reservation.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        UPDATE dbo.bookings
           SET status = N'approved'
         WHERE booking_id = @booking_id;

        INSERT INTO dbo.approvals (booking_id, approver_id, decision,
                                   decision_time, decision_note)
        VALUES (@booking_id, @approver_id, N'approved', SYSDATETIME(), @decision_note);

        COMMIT TRANSACTION;
        PRINT N'Booking ' + CAST(@booking_id AS VARCHAR(40)) + N' approved.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO