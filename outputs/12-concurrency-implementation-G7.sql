-- ============================================================================
-- Concurrency Implementation Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Description : Implements the concurrency enforcement defined in the
--               concurrency design: transactions for every conflict-sensitive
--               operation, each enforcing the recommended mechanism.
-- Design      : outputs/11-concurrency-design-G7.md  (CC-01 .. CC-05)
-- Baseline    : outputs/05-db-implementation-G7.sql (Phase 1 schema)
-- Migration   : outputs/10-schema-migration-G7.sql  (Phase 2 schema)
-- Artifact    : outputs/12-concurrency-implementation-G7.sql
-- Prerequisite: Database CS486_Booking_System with the Phase 2 schema
--               (execute outputs/05-db-implementation-G7.sql then
--               outputs/10-schema-migration-G7.sql).
-- Notes       : - Locking-hint mechanisms only (UPDLOCK, HOLDLOCK) under the
--                 default READ COMMITTED isolation level, exactly as
--                 recommended in Section 4 of the concurrency design.
--               - No isolation-level change, no row versioning, no lock
--                 granularity control is used (design Rule SQL2).
--               - One transaction per operation; the space row is the single
--                 serialization point for a space's booking conditions.
-- ============================================================================

-- ============================================================================
-- 1. HEADER BLOCK — Execution Context and Database Guard
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- The implementation evolves an existing Phase 2 database; it must not
-- create one. Abort with a clear message if the Phase 2 schema is missing.
IF DB_ID(N'CS486_Booking_System') IS NULL
    THROW 52000, N'Database CS486_Booking_System does not exist. Execute outputs/05-db-implementation-G7.sql first.', 1;
GO

USE [CS486_Booking_System];
GO

-- The Phase 2 columns used by these procedures (impact_level,
-- advisory_acknowledged) are added by outputs/10-schema-migration-G7.sql.
IF OBJECT_ID(N'dbo.bookings', N'U') IS NULL
    OR OBJECT_ID(N'dbo.maintenance_records', N'U') IS NULL
    OR OBJECT_ID(N'dbo.spaces', N'U') IS NULL
    OR OBJECT_ID(N'dbo.approvals', N'U') IS NULL
    OR COL_LENGTH(N'bookings', N'advisory_acknowledged') IS NULL
    OR COL_LENGTH(N'maintenance_records', N'impact_level') IS NULL
    THROW 52001, N'Phase 2 schema missing. Execute outputs/10-schema-migration-G7.sql first.', 1;
GO

-- Documented baseline: SQL Server default READ COMMITTED. The design (Section
-- 4) requires NO isolation-level change; all invariants are preserved by the
-- UPDLOCK/HOLDLOCK hints below. This statement is written explicitly only to
-- record the baseline; it does not raise the isolation level.
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- ============================================================================
-- 2. MECHANISM SUMMARY (from outputs/11-concurrency-design-G7.md Section 4)
-- ----------------------------------------------------------------------------
-- | Conflict | Business Rules | Mechanism                          | Implementation       |
-- |----------|----------------|------------------------------------|----------------------|
-- | CC-01    | BR-14, BR-50   | UPDLOCK + HOLDLOCK, space row       | usp_submit_instant_booking |
-- | CC-02    | BR-14, BR-49, BR-50 | UPDLOCK + HOLDLOCK, space row (both paths) | usp_submit_instant_booking, usp_approve_pending_booking |
-- | CC-03    | BR-44, BR-48   | UPDLOCK + HOLDLOCK, space row (booking + escalation) | usp_submit_*_booking, usp_approve_pending_booking, usp_escalate_maintenance_impact |
-- | CC-04    | BR-45, BR-46   | UPDLOCK + HOLDLOCK (booking, space row); UPDLOCK (advisory recording, space row) | usp_submit_*_booking, usp_approve_pending_booking, usp_record_maintenance |
-- | CC-05    | BR-47          | UPDLOCK, maintenance record         | usp_escalate_maintenance_impact, usp_downgrade_maintenance_impact |
--
-- Lock ordering: EVERY procedure acquires the space-row lock before any
-- maintenance-record lock (space -> record). Uniform ordering makes deadlock
-- impossible between the operations below.
--
-- The Phase 2 triggers (trg_bookings_br44_..., trg_bookings_br46_...,
-- trg_maintenance_records_br47_...) remain as declarative backstops; they do
-- not perform any locking (Rule BC5 of the migration).
-- ============================================================================

-- ============================================================================
-- 3. BOOKING CREATION PATHS  (CC-01, CC-02, CC-03, CC-04)
-- ----------------------------------------------------------------------------
-- Every path that creates or validates an approved booking acquires the same
-- UPDLOCK + HOLDLOCK lock on the space row and holds it to commit. This is the
-- single serialization point for a space's booking conditions:
--   * CC-01: two concurrent instant bookings for the same space serialize; the
--     loser re-checks availability after the winner commits and is rejected.
--   * CC-02: staff approval shares the identical lock, so the instant path and
--     the approval path cannot interleave their checks and commits.
--   * CC-03: an escalation holds the same space lock, so no booking can commit
--     while the escalation's affected-booking identification runs.
--   * CC-04: the advisory snapshot and acknowledgement are read/recorded while
--     holding the space lock, so an advisory commits either before the
--     snapshot (included in the notification) or after the acknowledgement
--     (outside the "at booking time" window, Q-05).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OP-01 — usp_submit_instant_booking (CC-01, CC-02, CC-03, CC-04; BR-14,
--         BR-44, BR-45, BR-46, BR-49, BR-50)
-- ----------------------------------------------------------------------------
-- User submits a booking request that is approved automatically at submission
-- time (BR-49). Eligibility for instant booking (selected space types +
-- usage policy, Q-01/A-02) is a caller precondition; this procedure performs
-- the concurrency-sensitive validation and the auto-approval.
-- Returns the booking_id and emits the advisory snapshot captured at booking
-- time (BR-45) so the requester can be notified of all active advisories.
CREATE OR ALTER PROCEDURE usp_submit_instant_booking
    @requester_id          VARCHAR(50),
    @space_code            VARCHAR(20),
    @requested_start_time  DATETIME2,
    @requested_end_time    DATETIME2,
    @purpose               VARCHAR(30),
    @expected_participants INT,
    @advisory_acknowledged BIT = NULL,      -- requester's acknowledgement (BR-46, Q-02)
    @booking_id            INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @capacity INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- CC-01/CC-02/CC-03/CC-04: acquire the space-row serialization point.
        -- UPDLOCK: concurrent booking decisions for the same space block here
        -- instead of all passing their availability check at once. HOLDLOCK:
        -- the lock is held to commit, so the checked state (availability,
        -- maintenance, advisories) cannot change mid-transaction.
        SELECT @capacity = capacity
          FROM spaces WITH (UPDLOCK, HOLDLOCK)
         WHERE space_code = @space_code;

        IF @capacity IS NULL
            THROW 52010, N'Space not found.', 1;

        -- BR-NI-05 (BR-40): expected participants must fit the space.
        IF @expected_participants > @capacity
            THROW 52011, N'BR-40 violation: expected participants exceed space capacity.', 1;

        -- BR-NI-13 (BR-36): requests must be submitted for the future.
        IF @requested_start_time <= SYSDATETIME()
            THROW 52012, N'BR-NI-13 violation: requested start time must be in the future.', 1;

        -- CC-01/CC-02: BR-14 availability check. Safe under default READ
        -- COMMITTED without a bookings lock: every path that can make a
        -- booking approved holds the same space-row lock, so no overlapping
        -- approval can be committed while this check-and-insert runs.
        IF EXISTS (SELECT 1
                     FROM bookings b
                    WHERE b.space_code = @space_code
                      AND b.status = N'approved'
                      AND @requested_end_time > b.requested_start_time
                      AND @requested_start_time < b.requested_end_time)
            THROW 52013, N'BR-14 violation: the requested period overlaps an approved booking for this space.', 1;

        -- CC-03: BR-44 pre-check against active out-of-service maintenance.
        -- Performed while holding the space lock (backed up by the trigger).
        IF EXISTS (SELECT 1
                     FROM maintenance_records m
                    WHERE m.space_code = @space_code
                      AND m.impact_level = N'out_of_service'
                      AND m.status IN (N'reported', N'in_progress')
                      AND @requested_end_time > m.start_time
                      AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time))
            THROW 52014, N'BR-44 violation: the requested period overlaps an active out-of-service maintenance record.', 1;

        -- CC-04: BR-45/BR-46 — advisory snapshot and acknowledgement are
        -- validated and recorded under the space lock, so the acknowledgement
        -- always corresponds to the snapshot captured at booking time.
        IF ISNULL(@advisory_acknowledged, 0) = 0
           AND EXISTS (SELECT 1
                         FROM maintenance_records m
                        WHERE m.space_code = @space_code
                          AND m.impact_level = N'advisory'
                          AND m.status IN (N'reported', N'in_progress')
                          AND @requested_end_time > m.start_time
                          AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time))
            THROW 52015, N'BR-46 violation: an advisory maintenance record overlaps the period; requester acknowledgement is required.', 1;

        -- BR-49: instant approval at submission time. No approvals row is
        -- created: instant booking involves no staff review, and the
        -- approvals table captures staff decisions only (assumption IA-1).
        INSERT INTO bookings (requester_id, space_code, requested_start_time, requested_end_time,
                              purpose, expected_participants, status, advisory_acknowledged)
        VALUES (@requester_id, @space_code, @requested_start_time, @requested_end_time,
                @purpose, @expected_participants, N'approved', @advisory_acknowledged);

        SET @booking_id = SCOPE_IDENTITY();

        -- BR-45: emit the advisory snapshot captured at booking time for the
        -- requester notification. Same lock, same state as the check above.
        SELECT m.maintenance_id, m.problem_description, m.start_time, m.completion_time
          FROM maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-02 — usp_submit_booking_for_approval (CC-03, CC-04; BR-14, BR-44,
--         BR-45, BR-46)
-- ----------------------------------------------------------------------------
-- User submits a booking request that is recorded as pending and continues
-- through the staff approval workflow. Identical validation and the same
-- space-row lock as OP-01, so maintenance state and the advisory snapshot are
-- captured consistently; only the resulting status differs.
CREATE OR ALTER PROCEDURE usp_submit_booking_for_approval
    @requester_id          VARCHAR(50),
    @space_code            VARCHAR(20),
    @requested_start_time  DATETIME2,
    @requested_end_time    DATETIME2,
    @purpose               VARCHAR(30),
    @expected_participants INT,
    @advisory_acknowledged BIT = NULL,
    @booking_id            INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @capacity INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- CC-03/CC-04: space-row serialization point, same as OP-01.
        SELECT @capacity = capacity
          FROM spaces WITH (UPDLOCK, HOLDLOCK)
         WHERE space_code = @space_code;

        IF @capacity IS NULL
            THROW 52020, N'Space not found.', 1;

        IF @expected_participants > @capacity
            THROW 52021, N'BR-40 violation: expected participants exceed space capacity.', 1;

        IF @requested_start_time <= SYSDATETIME()
            THROW 52022, N'BR-NI-13 violation: requested start time must be in the future.', 1;

        -- BR-14 availability check at submission time (validated again at
        -- approval time by OP-03).
        IF EXISTS (SELECT 1
                     FROM bookings b
                    WHERE b.space_code = @space_code
                      AND b.status = N'approved'
                      AND @requested_end_time > b.requested_start_time
                      AND @requested_start_time < b.requested_end_time)
            THROW 52023, N'BR-14 violation: the requested period overlaps an approved booking for this space.', 1;

        -- CC-03: BR-44 pre-check under the space lock.
        IF EXISTS (SELECT 1
                     FROM maintenance_records m
                    WHERE m.space_code = @space_code
                      AND m.impact_level = N'out_of_service'
                      AND m.status IN (N'reported', N'in_progress')
                      AND @requested_end_time > m.start_time
                      AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time))
            THROW 52024, N'BR-44 violation: the requested period overlaps an active out-of-service maintenance record.', 1;

        -- CC-04: BR-45/BR-46 advisory snapshot and acknowledgement.
        IF ISNULL(@advisory_acknowledged, 0) = 0
           AND EXISTS (SELECT 1
                         FROM maintenance_records m
                        WHERE m.space_code = @space_code
                          AND m.impact_level = N'advisory'
                          AND m.status IN (N'reported', N'in_progress')
                          AND @requested_end_time > m.start_time
                          AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time))
            THROW 52025, N'BR-46 violation: an advisory maintenance record overlaps the period; requester acknowledgement is required.', 1;

        INSERT INTO bookings (requester_id, space_code, requested_start_time, requested_end_time,
                              purpose, expected_participants, status, advisory_acknowledged)
        VALUES (@requester_id, @space_code, @requested_start_time, @requested_end_time,
                @purpose, @expected_participants, N'pending', @advisory_acknowledged);

        SET @booking_id = SCOPE_IDENTITY();

        -- BR-45: advisory snapshot for the notification.
        SELECT m.maintenance_id, m.problem_description, m.start_time, m.completion_time
          FROM maintenance_records m
         WHERE m.space_code = @space_code
           AND m.impact_level = N'advisory'
           AND m.status IN (N'reported', N'in_progress')
           AND @requested_end_time > m.start_time
           AND (m.completion_time IS NULL OR @requested_start_time < m.completion_time);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-03 — usp_approve_pending_booking (CC-02, CC-03, CC-04; BR-14, BR-28,
--         BR-44, BR-46, BR-50)
-- ----------------------------------------------------------------------------
-- Staff member approves a pending booking. The availability, maintenance and
-- advisory state are RE-validated inside the same transaction and under the
-- same space-row lock as the instant path (BR-50), so an approval can never
-- race an instant booking or another approval into overlapping slots.
CREATE OR ALTER PROCEDURE usp_approve_pending_booking
    @booking_id    INT,
    @approver_id   VARCHAR(50),
    @decision_note NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @space_code        VARCHAR(20),
            @requester_id      VARCHAR(50),
            @current_status    VARCHAR(20),
            @requested_start   DATETIME2,
            @requested_end     DATETIME2,
            @advisory_ack      BIT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @space_code = space_code,
               @requester_id = requester_id,
               @current_status = status,
               @requested_start = requested_start_time,
               @requested_end = requested_end_time,
               @advisory_ack = advisory_acknowledged
          FROM bookings
         WHERE booking_id = @booking_id;

        IF @space_code IS NULL
            THROW 52030, N'Booking not found.', 1;

        -- CC-02/CC-03/CC-04: the approval path acquires the SAME space-row
        -- lock as instant booking, so the two paths cannot race (BR-50).
        SELECT NULL
          FROM spaces WITH (UPDLOCK, HOLDLOCK)
         WHERE space_code = @space_code;

        -- BR-NI-11: the approver must differ from the requester.
        IF @approver_id = @requester_id
            THROW 52031, N'BR-NI-11 violation: the approver must differ from the requester.', 1;

        -- BR-14 re-validation, excluding the booking being approved (it is
        -- still pending and not yet part of the approved set).
        IF EXISTS (SELECT 1
                     FROM bookings b
                    WHERE b.space_code = @space_code
                      AND b.status = N'approved'
                      AND b.booking_id <> @booking_id
                      AND @requested_end > b.requested_start_time
                      AND @requested_start < b.requested_end_time)
            THROW 52032, N'BR-14 violation: the requested period overlaps an approved booking for this space.', 1;

        -- CC-03: BR-44 re-validation at approval time (backed up by the
        -- trigger on the status transition below).
        IF EXISTS (SELECT 1
                     FROM maintenance_records m
                    WHERE m.space_code = @space_code
                      AND m.impact_level = N'out_of_service'
                      AND m.status IN (N'reported', N'in_progress')
                      AND @requested_end > m.start_time
                      AND (m.completion_time IS NULL OR @requested_start < m.completion_time))
            THROW 52033, N'BR-44 violation: the requested period overlaps an active out-of-service maintenance record.', 1;

        -- CC-04: BR-46 re-validation — if an advisory became active since
        -- submission, the acknowledgement must be present before the booking
        -- becomes effective (the trigger would reject the update otherwise).
        IF ISNULL(@advisory_ack, 0) = 0
           AND EXISTS (SELECT 1
                         FROM maintenance_records m
                        WHERE m.space_code = @space_code
                          AND m.impact_level = N'advisory'
                          AND m.status IN (N'reported', N'in_progress')
                          AND @requested_end > m.start_time
                          AND (m.completion_time IS NULL OR @requested_start < m.completion_time))
            THROW 52034, N'BR-46 violation: an advisory maintenance record overlaps the period; requester acknowledgement is required before approval.', 1;

        -- BR-28: only a pending booking can be approved. The guarded UPDATE
        -- makes a concurrent double-approval impossible: the second approval
        -- finds no pending row and fails instead of creating a second
        -- approval record.
        UPDATE bookings
           SET status = N'approved'
         WHERE booking_id = @booking_id
           AND status = N'pending';

        IF @@ROWCOUNT = 0
            THROW 52035, N'BR-28 violation: only a pending booking can be approved.', 1;

        INSERT INTO approvals (booking_id, approver_id, decision, decision_time, decision_note)
        VALUES (@booking_id, @approver_id, N'approved', SYSDATETIME(), @decision_note);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- 4. MAINTENANCE OPERATIONS  (CC-03, CC-04, CC-05)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OP-04 — usp_record_maintenance (CC-04; BR-43, BR-45, BR-46)
-- ----------------------------------------------------------------------------
-- Staff records a new maintenance record (impact_level = advisory or
-- out_of_service). Takes an UPDLOCK on the space row (CC-04): if a booking
-- for the space is being finalized, the advisory commits after the booking's
-- acknowledgement (outside the "at booking time" window, Q-05); if the
-- advisory commits first, the next booking's snapshot includes it.
CREATE OR ALTER PROCEDURE usp_record_maintenance
    @reporter_id         VARCHAR(50),
    @space_code          VARCHAR(20),
    @assigned_staff_id   VARCHAR(50),
    @problem_description NVARCHAR(1000),
    @start_time          DATETIME2,
    @impact_level        VARCHAR(20),
    @maintenance_id      INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- CC-04: update lock on the space row serializes with the booking
        -- paths (which hold UPDLOCK + HOLDLOCK on the same row). UPDLOCK
        -- alone is sufficient here: this procedure only inserts; the lock is
        -- released at commit, which is exactly when the serialization point
        -- must be released.
        SELECT NULL
          FROM spaces WITH (UPDLOCK)
         WHERE space_code = @space_code;

        IF @@ROWCOUNT = 0
            THROW 52040, N'Space not found.', 1;

        IF @impact_level NOT IN (N'out_of_service', N'advisory')
            THROW 52041, N'BR-42 violation: impact_level must be out_of_service or advisory.', 1;

        -- Recording maintenance never blocks bookings retroactively: BR-48
        -- requires identifying (not cancelling) already-affected bookings
        -- (Q-04), so no overlap check is performed here.
        INSERT INTO maintenance_records (reporter_id, space_code, assigned_staff_id,
                                         problem_description, start_time, status,
                                         impact_level, completion_time, result_note)
        VALUES (@reporter_id, @space_code, @assigned_staff_id,
                @problem_description, @start_time, N'reported',
                @impact_level, NULL, NULL);

        SET @maintenance_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-05 — usp_escalate_maintenance_impact (CC-03, CC-05; BR-44, BR-47, BR-48)
-- ----------------------------------------------------------------------------
-- Escalates an open maintenance record from advisory to out_of_service and
-- identifies every approved booking overlapping the maintenance period so
-- staff can contact the requesters (BR-48).
-- CC-03: the space-row UPDLOCK + HOLDLOCK is held across the level update and
--   the affected-booking identification. No booking can commit while the
--   identification runs: bookings committed before the lock was taken are
--   visible to the read; bookings attempted afterwards see the escalated
--   out-of-service state and are rejected by BR-44.
-- CC-05: the maintenance record is read with UPDLOCK, so a concurrent
--   escalation/downgrade of the same record waits, then reads the fresh
--   committed level and applies its decision to the current state (no lost
--   update on the impact level, BR-47).
CREATE OR ALTER PROCEDURE usp_escalate_maintenance_impact
    @maintenance_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @space_code   VARCHAR(20),
            @m_status     VARCHAR(20),
            @m_level      VARCHAR(20),
            @m_start      DATETIME2,
            @m_completion DATETIME2;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Look up the space before locking (no update possible on space_code;
        -- the authoritative re-read happens below under UPDLOCK).
        SELECT @space_code = space_code
          FROM maintenance_records
         WHERE maintenance_id = @maintenance_id;

        IF @space_code IS NULL
            THROW 52050, N'Maintenance record not found.', 1;

        -- CC-03: space-row serialization point, held to commit.
        SELECT NULL
          FROM spaces WITH (UPDLOCK, HOLDLOCK)
         WHERE space_code = @space_code;

        -- CC-05: read the record under UPDLOCK before deciding the new level.
        SELECT @m_status = status,
               @m_level = impact_level,
               @m_start = start_time,
               @m_completion = completion_time
          FROM maintenance_records WITH (UPDLOCK)
         WHERE maintenance_id = @maintenance_id;

        -- BR-47: escalation applies only to open records (trigger backs up).
        IF @m_status = N'completed'
            THROW 52051, N'BR-47 violation: the impact level of a completed maintenance record cannot be changed.', 1;

        -- Idempotent: nothing to do if already escalated.
        IF @m_level <> N'out_of_service'
        BEGIN
            UPDATE maintenance_records
               SET impact_level = N'out_of_service'
             WHERE maintenance_id = @maintenance_id
               AND status IN (N'reported', N'in_progress');

            IF @@ROWCOUNT = 0
                THROW 52052, N'BR-47 violation: the impact level of a completed maintenance record cannot be changed.', 1;
        END

        -- BR-48: identify approved bookings overlapping the maintenance
        -- period for staff contact (Q-04: contact, not cancel). Consistent
        -- under the held space lock (CC-03).
        SELECT b.booking_id,
               b.requester_id,
               u.email,
               u.first_name,
               u.last_name,
               b.requested_start_time,
               b.requested_end_time
          FROM bookings b
          INNER JOIN users u
                  ON u.user_id = b.requester_id
         WHERE b.space_code = @space_code
           AND b.status = N'approved'
           AND b.requested_end_time > @m_start
           AND (@m_completion IS NULL OR b.requested_start_time < @m_completion);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-06 — usp_downgrade_maintenance_impact (CC-05; BR-47, Q-03)
-- ----------------------------------------------------------------------------
-- Downgrades an open maintenance record from out_of_service to advisory.
-- CC-05 only: the record is read under UPDLOCK so concurrent level changes
-- serialize and no committed decision is lost. No space-row lock is required
-- here — downgrade reduces severity and cannot violate BR-44/BR-48 (only an
-- escalation can), and booking creation never waits on the level of a
-- downgraded record (it validates against out_of_service only).
CREATE OR ALTER PROCEDURE usp_downgrade_maintenance_impact
    @maintenance_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @m_status VARCHAR(20),
            @m_level  VARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- CC-05: UPDLOCK on the maintenance record; held to commit, so a
        -- concurrent escalation/downgrade waits and re-reads the fresh level.
        SELECT @m_status = status,
               @m_level = impact_level
          FROM maintenance_records WITH (UPDLOCK)
         WHERE maintenance_id = @maintenance_id;

        IF @m_status IS NULL
            THROW 52060, N'Maintenance record not found.', 1;

        -- BR-47: downgrade applies only to open records (trigger backs up).
        IF @m_status = N'completed'
            THROW 52061, N'BR-47 violation: the impact level of a completed maintenance record cannot be changed.', 1;

        -- Q-03: advisory is the minimum level; downgrade below advisory is not
        -- possible, and a record already at advisory has nothing to do.
        IF @m_level = N'out_of_service'
        BEGIN
            UPDATE maintenance_records
               SET impact_level = N'advisory'
             WHERE maintenance_id = @maintenance_id
               AND status IN (N'reported', N'in_progress');

            IF @@ROWCOUNT = 0
                THROW 52062, N'BR-47 violation: the impact level of a completed maintenance record cannot be changed.', 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- 6. TRACEABILITY MATRIX
-- ----------------------------------------------------------------------------
-- | Conflict | Procedure                       | Mechanism used                     | Rules |
-- |----------|---------------------------------|------------------------------------|-------|
-- | CC-01    | usp_submit_instant_booking      | UPDLOCK + HOLDLOCK (space row)     | BR-14, BR-50 |
-- | CC-02    | usp_submit_instant_booking, usp_approve_pending_booking | UPDLOCK + HOLDLOCK (space row, both paths) | BR-14, BR-49, BR-50 |
-- | CC-03    | usp_submit_instant_booking, usp_submit_booking_for_approval, usp_approve_pending_booking, usp_escalate_maintenance_impact | UPDLOCK + HOLDLOCK (space row)     | BR-44, BR-48 |
-- | CC-04    | usp_submit_instant_booking, usp_submit_booking_for_approval, usp_approve_pending_booking (booking side); usp_record_maintenance (recording side) | UPDLOCK + HOLDLOCK (space row); UPDLOCK (space row) | BR-45, BR-46 |
-- | CC-05    | usp_escalate_maintenance_impact, usp_downgrade_maintenance_impact | UPDLOCK (maintenance record)       | BR-47 |
--
-- | Operation | Procedure                       | Business Rules enforced            |
-- |-----------|---------------------------------|------------------------------------|
-- | OP-01     | usp_submit_instant_booking      | BR-14, BR-40, BR-44, BR-45, BR-46, BR-49, BR-50, BR-NI-05, BR-NI-13 |
-- | OP-02     | usp_submit_booking_for_approval | BR-14, BR-40, BR-44, BR-45, BR-46, BR-NI-05, BR-NI-13 |
-- | OP-03     | usp_approve_pending_booking     | BR-14, BR-28, BR-44, BR-46, BR-50, BR-NI-11 |
-- | OP-04     | usp_record_maintenance          | BR-42, BR-43, BR-45, BR-46        |
-- | OP-05     | usp_escalate_maintenance_impact | BR-44, BR-47, BR-48               |
-- | OP-06     | usp_downgrade_maintenance_impact| BR-47                             |
-- ============================================================================

-- ============================================================================
-- 7. IMPLEMENTATION ASSUMPTIONS AND OPEN QUESTIONS
-- ----------------------------------------------------------------------------
-- Implementation assumptions (additional to design Section 5):
--
-- | ID  | Assumption | Justification |
-- |-----|-----------|---------------|
-- | IA-1 | An instant booking (OP-01) creates NO approvals row. | Instant approval is not a staff review; the approvals table captures staff decisions (approver_id is a required staff attribute). Auto-approved bookings are recorded directly with status = approved (BR-49). |
-- | IA-2 | Eligibility for instant booking (selected space types + usage policy, Q-01/A-02) is a caller precondition. | The eligible set is unspecified (Q-01); this script implements the concurrency-sensitive validation and auto-approval, not the eligibility policy evaluation. |
-- | IA-3 | The requester's acknowledgement (@advisory_acknowledged) is supplied by the calling application when the requester confirms the advisories (Q-02). | The confirmation mechanism is unspecified; BR-46 requires the acknowledgement to be recorded, and the trigger enforces it when an advisory overlaps. |
-- | IA-4 | BR-48 identification returns requester contact details (email) so staff can contact the affected requesters (Q-04: contact, not cancellation). | Q-04 is unresolved; no cancellation operation exists, so no DELETE-style concurrency is introduced. |
-- | IA-5 | Advisory is the minimum impact level; downgrade from advisory is a no-op (Q-03). | Q-03 unresolved; the two levels of BR-42/A-01 are exhaustive. |
-- | IA-6 | All procedures run under default READ COMMITTED with the documented locking hints; no procedure changes the isolation level. | Design Section 4 (Rule SQL2). |
-- | IA-7 | Lock ordering space-row -> maintenance-record is uniform across procedures, making deadlock impossible between these operations. | Verified: OP-01/02/03/04 lock the space row only; OP-05 locks space then record; OP-06 locks the record only. No lock cycle exists. |
--
-- Open questions carried from the design (Section 6): Q-01 (instant booking
-- eligibility), Q-02 (acknowledgement confirmation), Q-03 (minimum level),
-- Q-04 (cancellation vs contact), Q-05 ("at booking time" boundary), Q-06
-- (max active records).
-- ============================================================================

-- ============================================================================
-- 8. VALIDATION CHECKLIST (completed at authoring time)
-- ----------------------------------------------------------------------------
-- [X] Every conflict (CC-01 .. CC-05) has a transaction implementing its
--     recommended mechanism.
-- [X] Only the permitted mechanisms are used: locking hints UPDLOCK/HOLDLOCK
--     under default READ COMMITTED. No REPEATABLE READ, no SERIALIZABLE, no
--     row versioning, no lock granularity control.
-- [X] No redundant enforcement: mechanisms from the design are applied only
--     where the design recommends them (e.g. downgrade does not take the
--     CC-03 space lock).
-- [X] The same space-row serialization point is shared by every path that
--     produces or validates an approved booking (BR-50).
-- [X] Each operation runs in a single transaction with TRY/CATCH and
--     XACT_STATE()-based rollback; trigger rollbacks are rethrown unchanged.
-- [X] Cross-table business rules not expressible as DDL (BR-14, BR-44/46
--     pre-checks, BR-47 re-read) are enforced in the procedures, backed up by
--     the Phase 2 triggers and CHECK constraints.
-- [X] Naming follows the Phase 1/2 conventions (usp_<verb>_<object>).
-- [X] No object owned by another stage is modified: this script only creates
--     stored procedures; triggers and constraints from
--     outputs/10-schema-migration-G7.sql are reused, not recreated.
-- [X] Concurrency test scenarios belong to outputs/13-concurrency-tests-G7/
--     and are not included here.
-- ============================================================================

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
