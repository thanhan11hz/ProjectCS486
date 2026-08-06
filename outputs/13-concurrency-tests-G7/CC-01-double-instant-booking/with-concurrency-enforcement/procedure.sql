-- ============================================================================
-- CC-01 -- CONCURRENT INSTANT BOOKINGS FOR SAME SPACE, OVERLAPPING PERIOD
-- Variant: WITH concurrency enforcement
-- Procedure: usp_submit_instant_booking in the enforcement form
-- (copied verbatim from outputs/12-concurrency-implementation-G7.sql).
-- Protection: SELECT ... FROM dbo.spaces WITH (UPDLOCK, HOLDLOCK) held to commit
--             serialises the availability check of two instant bookings.
-- ============================================================================
USE [CS486_Booking_System];
GO
IF OBJECT_ID(N'dbo.usp_submit_instant_booking', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_submit_instant_booking;
GO
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

        -- BR-49: only selected space types are instant-eligible.
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.spaces
             WHERE space_code = @space_code
               AND space_type IN (N'classroom', N'meeting_room')
        )
        BEGIN
            RAISERROR(N'BR-49: this space type is not eligible for instant '
                      + N'booking. Use staff approval.', 16, 1);
            ROLLBACK;
            RETURN;
        END

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
            RAISERROR(N'BR-44: booking overlaps active out-of-service '
                      + N'maintenance. Booking is not permitted.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- BR-45/BR-46: advisory snapshot + acknowledgement.
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        -- BR-14/BR-50: availability check (the contested statement).
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
            RAISERROR(N'BR-14/BR-50: a conflicting booking already overlaps '
                      + N'the requested period for this space.', 16, 1);
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

        PRINT N'Instant booking ' + CAST(@new_booking_id AS VARCHAR(40))
              + N' approved and recorded.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO