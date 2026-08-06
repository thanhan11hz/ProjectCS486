-- ============================================================================
-- CC-03 -- WITHOUT concurrency enforcement
-- Procedures: usp_submit_instant_booking + usp_escalate_maintenance_impact with
-- all isolation-level statements and locking hints REMOVED.
--
-- The TEST HOOK delays are kept (between INSERT and COMMIT in the booking, and
-- between the UPDATE and the BR-48 identification in the escalation) so the two
-- sessions overlap in exactly the window that exposes the race. Because no lock
-- is held:
--   * the booking's INSERT + BR-44 trigger run while the maintenance is still
--     advisory, and its COMMIT is delayed;
--   * the escalation's UPDATE commits and its BR-48 identification runs BEFORE
--     the booking commits, so the identification MISSES the still-uncommitted
--     approved booking; that booking then commits after -- an approved booking
--     now overlaps the out-of-service maintenance period that was not identified
--     (BR-48), i.e. the CC-03 conflict is reproduced.
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
-- usp_submit_instant_booking  (OP-01, CC-03 booking side, no locking)
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

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s                             -- (locking hint removed)
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

        -- BR-14 / BR-50 availability check (unlocked read). Counts ONLY approved
        -- bookings (BR-14); a pending request does not reserve the space.
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

        -- ===== TEST HOOK ===== (NO lock held; the escalation can commit and run
        -- its identification in this window, while this booking stays uncommitted).
        WAITFOR DELAY '00:00:05';

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
-- usp_escalate_maintenance_impact  (OP-05, CC-03 escalation side, no locking)
-- ----------------------------------------------------------------------------
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

        -- ===== TEST HOOK =====
        -- Hold the transaction open between the escalation UPDATE and the BR-48
        -- identification. Without the space lock, the concurrent booking can
        -- commit right after this identification read -> it is MISSED.
        WAITFOR DELAY '00:00:03';

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