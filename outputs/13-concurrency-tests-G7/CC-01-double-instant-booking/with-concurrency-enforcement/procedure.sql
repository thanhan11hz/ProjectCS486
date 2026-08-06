-- ============================================================================
-- CC-01 -- CONCURRENT INSTANT BOOKINGS FOR THE SAME SPACE, OVERLAPPING PERIOD
-- Variant: WITH concurrency enforcement
-- Procedure: usp_submit_instant_booking in the enforcement form
-- (copied from outputs/12-concurrency-implementation-G7.sql) with ONE test hook:
-- a WAITFOR DELAY inserted between the BR-14/BR-50 availability check and the
-- INSERT so the two sessions reliably overlap inside the check -> act window.
--
-- Protection (unchanged from the implementation script):
--   SELECT ... FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK) is held to the end of
--   the transaction, serialising the availability checks of two instant bookings
--   for the same space (BR-14 / BR-50).
--
-- Why the delay is here: while Session 1 sleeps between check and INSERT it
-- still holds the space-row UPDLOCK + HOLDLOCK. Session 2 blocks at the same
-- lock, and after Session 1 commits it reads the FRESH state, sees the
-- conflicting booking and is rejected. Only ONE approved booking results.
--
-- All RAISERROR messages are single string literals (no expression arguments).
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

        -- Serialization point: space row locked with UPDLOCK + HOLDLOCK for the
        -- whole transaction (CC-01 / CC-02).
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
            RAISERROR(N'BR-49: this space type is not eligible for instant booking. Use staff approval.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- BR-44: reject if the requested period overlaps an active
        -- out-of-service maintenance record.
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
            RAISERROR(N'BR-44: booking overlaps active out-of-service maintenance. Booking is not permitted.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- BR-45 / BR-46: capture the active advisory snapshot under the SAME
        -- space-row lock.
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        -- BR-14 / BR-50: availability check (the contested statement).
        -- Counts ONLY approved bookings (BR-14): a pending request does not
        -- reserve the space, so it must NOT block the creation of another
        -- request (instant booking in particular).
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
            RAISERROR(N'BR-14/BR-50: a conflicting booking already overlaps the requested period for this space.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- ===== TEST HOOK =====
        -- Hold the transaction open after the availability check. The space-row
        -- UPDLOCK + HOLDLOCK is still held here, so a concurrent instant booking
        -- for the same space cannot pass the same check. Remove for production.
        WAITFOR DELAY '00:00:05';

        -- INSERT the booking, immediately approved (BR-49), carrying the
        -- advisory acknowledgement.
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

        -- Record the instant approval (BR-49).
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
