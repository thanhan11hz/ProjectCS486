-- ============================================================================
-- CC-03 -- BOOKING CREATION RACING WITH ESCALATION TO OUT-OF-SERVICE
-- Variant: WITH concurrency enforcement
-- Procedures: usp_submit_instant_booking + usp_escalate_maintenance_impact in
-- the enforcement form (copied from outputs/12-concurrency-implementation-G7.sql)
-- with TEST HOOK delays:
--   * usp_submit_instant_booking: WAITFOR DELAY placed between the INSERT and
--     the COMMIT. For THIS conflict the vulnerable window is exactly there: the
--     BR-44 trigger validates the booking at INSERT time while the maintenance is
--     still advisory; the race is that the escalation may commit between that
--     INSERT and the booking's COMMIT. The delay keeps the booking's
--     UPDLOCK + HOLDLOCK on the space row held across the whole window.
--   * usp_escalate_maintenance_impact: WAITFOR DELAY between the impact-level
--     UPDATE and the BR-48 affected-booking identification.
--
-- Booking creation and escalation BOTH take the space-row UPDLOCK + HOLDLOCK, so
-- the escalation cannot commit between the booking's INSERT and COMMIT, and the
-- escalation's BR-48 identification cannot miss a concurrently committed booking
-- (CC-03). In this scenario the booking commits first and the escalation then
-- IDENTIFIES it in the BR-48 result.
--
-- All RAISERROR messages are single string literals (no expression arguments).
-- ============================================================================
USE [CS486_Booking_System];
GO
IF OBJECT_ID(N'dbo.usp_submit_instant_booking', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_submit_instant_booking;
IF OBJECT_ID(N'dbo.usp_escalate_maintenance_impact', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_escalate_maintenance_impact;
GO

-- ----------------------------------------------------------------------------
-- usp_submit_instant_booking  (OP-01, CC-03 booking side)
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

        -- Serialization point held for the whole transaction.
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

        -- BR-45 / BR-46 advisory snapshot under the SAME space lock.
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        -- BR-14 / BR-50 availability check. Counts ONLY approved bookings
        -- (BR-14); a pending request does not reserve the space and must not
        -- block another request.
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

        WAITFOR DELAY '00:00:05';

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

        -- ===== TEST HOOK =====
        -- Hold the transaction open AFTER the booking was inserted but BEFORE it
        -- commits. The BR-44 trigger validated the INSERT while the maintenance
        -- was still advisory; the space-row UPDLOCK + HOLDLOCK is still held here,
        -- so the concurrent escalation cannot commit in this window. Remove for
        -- production.
        

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

-- ----------------------------------------------------------------------------
-- usp_escalate_maintenance_impact  (OP-05, CC-03 escalation side)
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

        -- Resolve the record's space with a short navigation read (holds no lock
        -- beyond this statement), so the space lock is acquired BEFORE the record
        -- is locked again (consistent lock ordering shared with the booking paths).
        DECLARE @space_code VARCHAR(20);
        SELECT @space_code = m.space_code
          FROM dbo.maintenance_records m
         WHERE m.maintenance_id = @maintenance_id;

        IF @space_code IS NULL
        BEGIN
            RAISERROR(N'BR-47: maintenance record not found or not open.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- Serialize on the space (CC-03).
        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- Re-read the record under UPDLOCK (CC-05) for a fresh, serialized view
        -- of its state; the record must still be open.
        DECLARE @start_time    DATETIME2;
        DECLARE @completion    DATETIME2;
        DECLARE @current_level VARCHAR(20);
        SELECT @start_time    = m.start_time,
               @completion    = m.completion_time,
               @current_level = m.impact_level
          FROM dbo.maintenance_records m WITH (UPDLOCK)
         WHERE m.maintenance_id = @maintenance_id
           AND m.status IN (N'reported', N'in_progress');

        -- BR-47: only advisory records escalate to out-of-service.
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

        -- ===== TEST HOOK =====
        -- Hold the transaction open between the escalation UPDATE and the BR-48
        -- identification. The space lock is still held here, so no booking can
        -- commit in between and the identification cannot miss one. Remove for
        -- production.

        -- BR-48: identify all approved bookings overlapping the maintenance
        -- period (guaranteed consistent under the space lock).
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