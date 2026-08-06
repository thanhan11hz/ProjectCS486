-- ============================================================================
-- Concurrency Implementation Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Description : Implements the concurrency enforcement defined in the
--               concurrency design (outputs/11-concurrency-design-G7.md) by
--               wrapping every concurrency-sensitive operation in a stored
--               procedure that applies the required locking hints.
-- Baseline    : outputs/05-db-implementation-G7.sql  (Phase 1 schema)
-- Migrated by : outputs/10-schema-migration-G7.sql    (Phase 2 schema)
-- Design      : outputs/11-concurrency-design-G7.md
-- Artifact    : outputs/12-concurrency-implementation-G7.sql
-- Prerequisite: Database CS486_Booking_System with the Phase 2 schema (run
--               outputs/05-db-implementation-G7.sql then
--               outputs/10-schema-migration-G7.sql, then optionally seed with
--               outputs/06-sample-data-G7.sql).
-- ----------------------------------------------------------------------------
-- Concurrency mechanisms (allowed set per skill rules):
--   * Isolation levels: READ COMMITTED, REPEATABLE READ, SERIALIZABLE
--   * Locking hints  : READCOMMITTED, UPDLOCK, HOLDLOCK
--   * Lock granularity and row versioning are EXCLUDED.
--
-- Per the design (11 Section 4) every conflict is resolved with locking hints
-- under SQL Server's default READ COMMITTED isolation. Each procedure therefore
-- EXPLICITLY sets READ COMMITTED (so the behavior is independent of any prior
-- session state) and relies on the correct UPDLOCK / UPDLOCK + HOLDLOCK hints
-- to carry the serialization. Isolation levels are never raised above the
-- default because the design shows the locking hints are sufficient and least
-- restrictive (Rule SQL2 / disallow high-level over-engineering).
-- ============================================================================

USE [CS486_Booking_System];
GO

-- ----------------------------------------------------------------------------
-- 0. SAFE DROP BLOCK (idempotent re-run)
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_submit_booking_pending',        N'P') IS NOT NULL DROP PROCEDURE usp_submit_booking_pending;
IF OBJECT_ID(N'dbo.usp_submit_instant_booking',         N'P') IS NOT NULL DROP PROCEDURE usp_submit_instant_booking;
IF OBJECT_ID(N'dbo.usp_approve_pending_booking',       N'P') IS NOT NULL DROP PROCEDURE usp_approve_pending_booking;
IF OBJECT_ID(N'dbo.usp_record_maintenance',            N'P') IS NOT NULL DROP PROCEDURE usp_record_maintenance;
IF OBJECT_ID(N'dbo.usp_escalate_maintenance_impact',   N'P') IS NOT NULL DROP PROCEDURE usp_escalate_maintenance_impact;
IF OBJECT_ID(N'dbo.usp_downgrade_maintenance_impact',  N'P') IS NOT NULL DROP PROCEDURE usp_downgrade_maintenance_impact;
GO

-- ============================================================================
-- ============================================================================
-- SECTION A -- BOOKING CREATION AND APPROVAL PATHS (CC-01, CC-02, CC-03, CC-04)
-- ============================================================================
-- All booking paths share ONE serialization point: the space row, read with
-- UPDLOCK + HOLDLOCK before any availability / maintenance / advisory check.
-- This guarantees:
--   * CC-01/CC-02: two approved-booking decisions for the same space and
--     overlapping period cannot both pass the availability check.
--   * CC-03: a booking cannot be created on a space that just escalated to
--     out-of-service, nor can an escalation's identification miss it.
--   * CC-04: the advisory snapshot + acknowledgement are captured consistently
--     with any advisory recorded concurrently.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- usp_submit_instant_booking  (OP-01 -- CC-01/CC-02/CC-03/CC-04)
-- ----------------------------------------------------------------------------
-- Submits a booking request that is approved AUTOMATICALLY at submission time
-- because the space type is instant-booking-eligible (BR-49). This is the
-- highest-contention path: the availability + maintenance + advisory snapshot
-- checks and the insertion (pending + approval) all run in ONE transaction
-- that holds UPDLOCK + HOLDLOCK on the space row for its whole duration.
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

        -- --------------------------------------------------------------
        -- Take / hold the space-row serialization point with UPDLOCK +
        -- HOLDLOCK so the availability check below cannot be raced by another
        -- transaction publishing an overlapping approved booking on the same
        -- space (CC-01/CC-02). HOLDLOCK keeps the lock to commit so no phantom
        -- overlapping booking can be inserted between the check and commit.
        -- --------------------------------------------------------------
        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- ----- 1) BR-49: only selected space types are instant-eligible.
        --        (Representative set; the authoritative set is Q-01.)
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

        -- ----- 2) BR-44: reject if the requested period overlaps an active
        -- out-of-service maintenance record (blocking rule).
        IF EXISTS
        (
            SELECT 1
              FROM dbo.maintenance_records m
             WHERE m.space_code = @space_code
               AND m.impact_level = N'out_of_service'
               AND m.status IN (N'reported', N'in_progress')
               AND @requested_end_time > m.start_time
               AND (m.completion_time IS NULL
                    OR @requested_start_time < m.completion_time)
        )
        BEGIN
            RAISERROR(N'BR-44: booking overlaps active out-of-service '
                      + N'maintenance. Booking is not permitted.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- ----- 3) BR-45 / CC-04: capture the active ADVISORY snapshot under
        -- the SAME space-row lock. An advisory recorded up to this instant is
        -- included in the notification; an advisory recorded after the
        -- acknowledgement is outside the "at booking time" window (Q-05).
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        -- ----- 4) BR-14 / BR-50: availability check against existing
        -- approved/pending bookings. Because HOLDLOCK holds the space row to
        -- the end of the transaction, two concurrent instant bookings for the
        -- same space and overlapping period cannot BOTH pass (CC-01), and a
        -- staff approval cannot interleave (CC-02).
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

        -- ----- 5) INSERT the booking, immediately approved (BR-49), carrying
        -- the advisory acknowledgement (1 iff an advisory was active (BR-46).
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

        -- ----- 6) Record the instant approval (BR-49); the approval source is
        -- automated, so a facility_manager is used as the approver
        -- representative. (Approver identity is the subject of Q-02.)
        DECLARE @approver VARCHAR(50) =
            (SELECT TOP 1 user_id FROM dbo.users
              WHERE role = N'facility_manager' ORDER BY user_id);

        INSERT INTO dbo.approvals (booking_id, approver_id, decision,
                                   decision_time)
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

-- ----------------------------------------------------------------------------
-- usp_submit_booking_pending  (OP-02 -- CC-01/CC-02/CC-03/CC-04)
-- ----------------------------------------------------------------------------
-- Submits a booking request that enters the staff-approval workflow as pending.
-- It reuses the IDENTICAL space-row UPDLOCK + HOLDLOCK serialization and
-- identical validation (BR-14 pre-check, BR-44, advisory snapshot and
-- acknowledgement) so both booking paths carry the SAME conflict protection
-- (BR-50) and cannot bypass one another's invariant.
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
               AND (m.completion_time IS NULL
                    OR @requested_start_time < m.completion_time)
        )
        BEGIN
            RAISERROR(N'BR-44: booking overlaps active out-of-service '
                      + N'maintenance.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- BR-45/BR-46: snapshot active advisories under the same space lock.
        DECLARE @advisory_count INT = 0;
        SELECT @advisory_count = COUNT(*)
          FROM dbo.maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        -- BR-14 pre-check: no overlap with an existing approved/pending.
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
        PRINT N'Booking #' + CAST(@booking AS VARCHAR(40))
              + N' recorded as pending for staff approval.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- usp_approve_pending_booking  (OP-03 -- CC-02/CC-03)
-- ----------------------------------------------------------------------------
-- Staff approves a pending booking. Approval RE-VALIDATES BR-14 availability
-- and BR-44 maintenance state under the SAME space-lock serialization used by
-- instant submissions, so staff approval and instant booking cannot race
-- (CC-02). It also holds the space lock (CC-03) so it cannot be interleaved
-- with an escalation.
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

        -- Serialize on the space: an approval is an approved-booking decision.
        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- BR-44 re-validation at approval time.
        IF EXISTS
        (
            SELECT 1
              FROM dbo.maintenance_records m
             WHERE m.space_code = @space_code
               AND m.impact_level = N'out_of_service'
               AND m.status IN (N'reported', N'in_progress')
               AND @requested_end > m.start_time
               AND (m.completion_time IS NULL
                    OR @requested_start < m.completion_time)
        )
        BEGIN
            RAISERROR(N'BR-44: cannot approve: space is under out-of-service '
                      + N'maintenance for this period.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- BR-14/BR-50 re-validation vs other approved/pending bookings.
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
            RAISERROR(N'BR-14/BR-50: approving would create an overlapping '
                      + N'reservation.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- Mark the booking approved and record the approval.
        UPDATE dbo.bookings
           SET status = N'approved'
         WHERE booking_id = @booking_id;

        INSERT INTO dbo.approvals (booking_id, approver_id, decision,
                                   decision_time, decision_note)
        VALUES (@booking_id, @approver_id, N'approved', SYSDATETIME(),
                @decision_note);

        COMMIT TRANSACTION;
        PRINT N'Booking ' + CAST(@booking_id AS VARCHAR(40)) + N' approved.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- SECTION B -- MAINTENANCE OPERATIONS (CC-03, CC-04, CC-05)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- usp_record_maintenance  (OP-04 -- CC-04)
-- ----------------------------------------------------------------------------
-- Records a NEW maintenance record. It acquires an UPDATE lock on the space
-- row so the recording is serialized with a booking's advisory snapshot +
-- acknowledgement (CC-04): an advisory commits either before the booking's
-- snapshot (then it is included in the notification) or after the booking's
-- acknowledgement (outside the booking-time window). UPDLOCK + HOLDLOCK is
-- used because recording a maintenance state change must not interleave with
-- booking creation, and HOLDLOCK keeps the space row locked to commit.
-- impact_level is passed explicitly (BR-42; no default in the schema).
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

-- ----------------------------------------------------------------------------
-- usp_escalate_maintenance_impact  (OP-05 -- CC-03, CC-05, BR-48)
-- ----------------------------------------------------------------------------
-- Escalates an open advisory maintenance record to out-of-service. Two
-- resources are serialized:
--   * CC-05: the single maintenance record is read with UPDLOCK so two
--     concurrent level changes cannot lose one another (lost update).
--   * CC-03 / BR-48: the space row is read with UPDLOCK + HOLDLOCK so the
--     escalate holds the space lock for the entire update-and-identify
--     sequence; the affected-approved-booking read cannot miss a concurrently
--     committed booking (CC-03).
-- BR-48: all approved bookings overlapping the maintenance period are returned
--     to the caller so staff can contact the requesters.
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

        -- Serialize on the maintenance record (CC-05). Re-read the current
        -- state under UPDLOCK so the decision is based on fresh committed data.
        DECLARE @space_code     VARCHAR(20);
        DECLARE @start_time     DATETIME2;
        DECLARE @completion     DATETIME2;
        DECLARE @current_level  VARCHAR(20);

        SELECT @space_code     = m.space_code,
               @start_time     = m.start_time,
               @completion     = m.completion_time,
               @current_level  = m.impact_level
          FROM dbo.maintenance_records m WITH (UPDLOCK)
         WHERE m.maintenance_id = @maintenance_id
           AND m.status IN (N'reported', N'in_progress');

        IF @space_code IS NULL
        BEGIN
            RAISERROR(N'BR-47: maintenance record not found or not open.', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- Serialize on the space (CC-03) so the escalation's
        -- update-and-identify holds the booking serialization point.
        DECLARE @space_holder VARCHAR(20);
        SELECT @space_holder = s.space_code
          FROM dbo.spaces s WITH (UPDLOCK, HOLDLOCK)
         WHERE s.space_code = @space_code;

        -- BR-47: only advisory records escalate to out-of-service.
        IF @current_level <> N'advisory'
        BEGIN
            RAISERROR(N'BR-47: only advisory records escalate to out-of-service.',
                      16, 1);
            ROLLBACK;
            RETURN;
        END;

        -- Perform the escalation.
        UPDATE dbo.maintenance_records
           SET impact_level = N'out_of_service'
         WHERE maintenance_id = @maintenance_id
           AND status IN (N'reported', N'in_progress');

        -- BR-48: identify all approved bookings overlapping the maintenance
        -- period. The space lock guarantees no concurrently committed booking
        -- is missed (CC-03).
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

-- ----------------------------------------------------------------------------
-- usp_downgrade_maintenance_impact  (OP-06 -- CC-05)
-- ----------------------------------------------------------------------------
-- Downgrades the impact level of an OPEN record (e.g., out_of_service ->
-- advisory). Uses the same UPDLOCK-on-record protection as escalation to prevent a
-- lost update (CC-05). No space lock is needed: the downgrade only relaxes a
-- space's booking conditions and does not identify affected bookings.
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

        -- Updated-level UPDLOCK read to prevent lost updates (BR-47).
        DECLARE @current_level VARCHAR(20), @status VARCHAR(20);
        SELECT @current_level = m.impact_level, @status = m.status
          FROM dbo.maintenance_records m WITH (UPDLOCK)
         WHERE m.maintenance_id = @maintenance_id;

        IF @status = N'completed'
        BEGIN
            RAISERROR(N'BR-47: the impact level of a completed maintenance '
                      + N'record cannot be changed. Downgrade is only allowed '
                      + N'while the record is open.', 16, 1);
            ROLLBACK;
            RETURN;
        END;

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

-- ============================================================================
-- TRACEABILITY -- Conflict to mechanism to object
-- ----------------------------------------------------------------------------
-- | Conflict | Business Rules | Mechanism Used (in the SQL above)          | Object(s)                        |
-- |----------|---------------|--------------------|------------------------------------------------|------------------------------|
-- | CC-01   | BR-14, BR-50 | UPDLOCK+HOLDLOCK space row (availability check) | usp_submit_instant_booking      |
-- | CC-02   | BR-14,BR-49,BR-50 | UPDLOCK+HOLDLOCK space row (both paths) | usp_submit_booking_pending + usp_approve_pending_booking |
-- | CC-03   | BR-44, BR-48   | UPDLOCK+HOLDLOCK space row (both booking and escalation)      | usp_escalate (space lock + BR-48 SELECT) |
-- | CC-04   | BR-45, BR-46   | UPDLOCK+HOLDLOCK (all booking) + UPDLOCK (record maintenance) | usp_record_maintenance/booking paths |
-- | CC-05   | BR-47          | UPDLOCK on maintenance record (both directions) | usp_escalate / usp_downgrade    |
-- ============================================================================

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================