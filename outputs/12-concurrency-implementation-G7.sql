-- ============================================================================
-- Concurrency Implementation Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Description : Implements the concurrency enforcement designed in
--               outputs/11-concurrency-design-G7.md. Each business operation
--               that touches a concurrency-sensitive invariant is wrapped in a
--               single transaction (design assumption A-04) and protected with
--               the isolation level / locking hints recommended for its
--               conflict(s).
-- Artifact    : outputs/12-concurrency-implementation-G7.sql
-- Prerequisite: outputs/05-db-implementation-G7.sql    (run first: schema)
--               outputs/06-sample-data-G7.sql          (run second: seed data)
--               outputs/10-schema-migration-G7.sql     (run third: adds
--                   maintenance_records.impact_level,
--                   bookings.advisory_acknowledged)
-- Notes       : Stored procedures and transaction scripts only. Indexing to
--               support the range scans belongs to stage 15
--               (outputs/15-index-tuning-report-G7.md).
-- ============================================================================

USE [CS486_Booking_System];
GO

-- ============================================================================
-- 1. CONFLICT -> OPERATION -> MECHANISM MAPPING (traceability)
-- ----------------------------------------------------------------------------
--   CC-01  BR-14, BR-50        OP-01 Instant booking
--            -> READ COMMITTED + UPDLOCK (space row)
--               + HOLDLOCK (availability range read)
--   CC-02  BR-14, BR-49, BR-50 OP-01 Instant booking, OP-02 Submission,
--                              OP-03 Staff approval
--            -> READ COMMITTED + UPDLOCK (space row)
--               + HOLDLOCK (availability range read)
--   CC-03  BR-44, BR-48        OP-04 Escalation (vs OP-01/OP-02/OP-03)
--            -> READ COMMITTED + UPDLOCK (space row)
--               + UPDLOCK (maintenance record row)
--               + HOLDLOCK (affected-bookings range scan, OP-08)
--            booking side additionally holds HOLDLOCK over the active
--            out-of-service maintenance range for its requested period
--   CC-04  BR-45, BR-46        OP-01/OP-02 (vs OP-06 Advisory recording)
--            -> booking transaction holds HOLDLOCK over the space's active
--               advisory range; the advisory INSERT needs no hint because it
--               is naturally blocked by that range lock
--   CC-05  BR-47               OP-04 Escalation, OP-05 Downgrade
--            -> READ COMMITTED + UPDLOCK (maintenance record row)
--
-- Mechanism selection note (per the concurrency-implementation skill rule
-- "use only SUFFICIENT mechanisms and prioritise mechanisms of LOWER LEVEL"):
--   The design (11-concurrency-design-G7.md, section 4) recommends
--   SERIALIZABLE for CC-01..CC-04. Raising the whole transaction to
--   SERIALIZABLE also locks every unrelated read; instead the HOLDLOCK hint is
--   used on the specific protected statements, which reproduces the same
--   key-range/table-range phantom protection at READ COMMITTED. The invariant
--   guarantee is identical, while blocking of unrelated data is reduced.
--   CC-05 is inherently row-level, so the design's lower-level READ COMMITTED
--   + UPDLOCK is used unchanged.
-- ============================================================================

-- ============================================================================
-- 2. CC-01 / CC-02 / CC-03 / CC-04 — BOOKING PATH
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OP-01: usp_create_instant_booking
-- CC-01 / CC-02 / CC-03 / CC-04, auto-approval path (BR-49)
-- Mechanism: READ COMMITTED + UPDLOCK (space row) + HOLDLOCK
--   (availability, out-of-service, and advisory range reads)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_create_instant_booking
    @requester_id           VARCHAR(50),
    @space_code             VARCHAR(20),
    @requested_start_time   DATETIME2,
    @requested_end_time     DATETIME2,
    @purpose                VARCHAR(30),
    @expected_participants  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- [CC-01/CC-02/CC-03] UPDLOCK on the space row is the common
        --   serialization point for every operation that mutates the space's
        --   availability state (instant booking, submission, approval,
        --   escalation). It is acquired before any other lock in this path so
        --   all booking-path transactions share one lock order (space first)
        --   and cannot deadlock. Also reads capacity and status for the
        --   business validation (BR-32, BR-40).
        DECLARE @capacity      INT;
        DECLARE @space_status  VARCHAR(30);

        SELECT @capacity = capacity, @space_status = status
          FROM spaces WITH (UPDLOCK, HOLDLOCK)
         WHERE space_code = @space_code;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 51001, N'Space does not exist.', 1;
        END

        IF @space_status IN (N'under_maintenance', N'temporarily_closed', N'retired')
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 51002, N'Space is not bookable in its current status.', 1;
        END

        IF @expected_participants > @capacity
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 51003, N'Expected participants exceed the space capacity.', 1;
        END

        -- [CC-01] HOLDLOCK on the availability range read: shared key-range
        --   locks over the approved bookings of this space that overlap the
        --   requested period are held to the end of the transaction, so a
        --   concurrent instant booking / submission / approval for an
        --   overlapping period cannot insert in between (phantom prevention,
        --   BR-14 / BR-50).
        IF EXISTS (
            SELECT 1
              FROM bookings WITH (HOLDLOCK)
             WHERE space_code            = @space_code
               AND status                = N'approved'
               AND requested_start_time  < @requested_end_time
               AND requested_end_time    > @requested_start_time
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 51004, N'The space is already booked for an overlapping period.', 1;
        END

        -- [CC-03] HOLDLOCK on the out-of-service maintenance range read: a
        --   concurrent escalation that marks this space out of service for an
        --   overlapping period cannot commit before this booking does, so the
        --   booking can never be created on a space that was already declared
        --   out of service (BR-44).
        IF EXISTS (
            SELECT 1
              FROM maintenance_records WITH (HOLDLOCK)
             WHERE space_code            = @space_code
               AND impact_level          = N'out_of_service'
               AND status                IN (N'reported', N'in_progress')
               AND start_time            < @requested_end_time
               AND (completion_time IS NULL OR completion_time > @requested_start_time)
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 51005, N'The space is out of service for the requested period.', 1;
        END

        -- [CC-04] HOLDLOCK on the active advisory range read: the advisory set
        --   is captured atomically with the booking. A concurrently recorded
        --   advisory either commits before this booking (and is then captured
        --   and acknowledged) or commits after it (and is correctly excluded);
        --   it can never be silently missed (BR-45 / BR-46).
        DECLARE @advisory_active BIT =
            CASE WHEN EXISTS (
                SELECT 1
                  FROM maintenance_records WITH (HOLDLOCK)
                 WHERE space_code            = @space_code
                   AND impact_level          = N'advisory'
                   AND status                IN (N'reported', N'in_progress')
                   AND start_time            < @requested_end_time
                   AND (completion_time IS NULL OR completion_time > @requested_start_time)
            ) THEN 1 ELSE 0 END;

        -- Instant booking is auto-approved at submission time (OP-01, BR-49).
        -- The acknowledgement is recorded when advisories are active (BR-46);
        -- requesters are notified at application level (out of scope, A-03).
        INSERT INTO bookings (
            requester_id, space_code, requested_start_time, requested_end_time,
            purpose, expected_participants, status, advisory_acknowledged
        )
        VALUES (
            @requester_id, @space_code, @requested_start_time, @requested_end_time,
            @purpose, @expected_participants, N'approved',
            CASE WHEN @advisory_active = 1 THEN 1 ELSE NULL END
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-02: usp_submit_booking_request
-- CC-02 / CC-03 / CC-04, staff-approval path (BR-28)
-- Mechanism: READ COMMITTED + UPDLOCK (space row) + HOLDLOCK
--   (availability, out-of-service, and advisory range reads)
-- Note: the decisive availability check runs again inside usp_approve_booking;
--       submission performs the same protected validation so a pending request
--       is created against a consistent snapshot (assumption A-07).
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_submit_booking_request
    @requester_id           VARCHAR(50),
    @space_code             VARCHAR(20),
    @requested_start_time   DATETIME2,
    @requested_end_time     DATETIME2,
    @purpose                VARCHAR(30),
    @expected_participants  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @capacity      INT;
        DECLARE @space_status  VARCHAR(30);

        SELECT @capacity = capacity, @space_status = status
          FROM spaces WITH (UPDLOCK, HOLDLOCK)
         WHERE space_code = @space_code;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 52001, N'Space does not exist.', 1;
        END

        IF @space_status IN (N'under_maintenance', N'temporarily_closed', N'retired')
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 52002, N'Space is not bookable in its current status.', 1;
        END

        IF @expected_participants > @capacity
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 52003, N'Expected participants exceed the space capacity.', 1;
        END

        -- [CC-02] Availability range read with HOLDLOCK (early validation; the
        --   approval path re-checks under the same locks).
        IF EXISTS (
            SELECT 1
              FROM bookings WITH (HOLDLOCK)
             WHERE space_code            = @space_code
               AND status                = N'approved'
               AND requested_start_time  < @requested_end_time
               AND requested_end_time    > @requested_start_time
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 52004, N'The space is already booked for an overlapping period.', 1;
        END

        -- [CC-03] Out-of-service maintenance range read with HOLDLOCK.
        IF EXISTS (
            SELECT 1
              FROM maintenance_records WITH (HOLDLOCK)
             WHERE space_code            = @space_code
               AND impact_level          = N'out_of_service'
               AND status                IN (N'reported', N'in_progress')
               AND start_time            < @requested_end_time
               AND (completion_time IS NULL OR completion_time > @requested_start_time)
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 52005, N'The space is out of service for the requested period.', 1;
        END

        -- [CC-04] Advisory range read with HOLDLOCK; captured acknowledgement.
        DECLARE @advisory_active BIT =
            CASE WHEN EXISTS (
                SELECT 1
                  FROM maintenance_records WITH (HOLDLOCK)
                 WHERE space_code            = @space_code
                   AND impact_level          = N'advisory'
                   AND status                IN (N'reported', N'in_progress')
                   AND start_time            < @requested_end_time
                   AND (completion_time IS NULL OR completion_time > @requested_start_time)
            ) THEN 1 ELSE 0 END;

        INSERT INTO bookings (
            requester_id, space_code, requested_start_time, requested_end_time,
            purpose, expected_participants, status, advisory_acknowledged
        )
        VALUES (
            @requester_id, @space_code, @requested_start_time, @requested_end_time,
            @purpose, @expected_participants, N'pending',
            CASE WHEN @advisory_active = 1 THEN 1 ELSE NULL END
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-03: usp_approve_booking
-- CC-02 / CC-03 / CC-04, staff-approval workflow (BR-28)
-- Mechanism: READ COMMITTED + UPDLOCK (pending booking row and space row)
--   + HOLDLOCK (availability, out-of-service, advisory range reads)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_approve_booking
    @booking_id     INT,
    @approver_id    VARCHAR(50),
    @decision_note  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- UPDLOCK on the pending booking row: two staff members cannot approve
        -- (or reject) the same request concurrently (1:1 approvals,
        -- uq_approvals_booking_id), and the lock is held until commit.
        DECLARE @space_code           VARCHAR(20);
        DECLARE @requested_start_time DATETIME2;
        DECLARE @requested_end_time   DATETIME2;
        DECLARE @current_status       VARCHAR(20);

        SELECT @space_code           = space_code,
               @requested_start_time = requested_start_time,
               @requested_end_time   = requested_end_time,
               @current_status       = status
          FROM bookings WITH (UPDLOCK, HOLDLOCK)
         WHERE booking_id = @booking_id;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 53001, N'Booking not found.', 1;
        END

        IF @current_status <> N'pending'
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 53002, N'Only pending bookings can be approved.', 1;
        END

        -- [CC-02] UPDLOCK on the space row: shared serialization point with the
        --   instant-booking and submission paths (space-first lock order).
        IF NOT EXISTS (
            SELECT 1
              FROM spaces WITH (UPDLOCK, HOLDLOCK)
             WHERE space_code = @space_code
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 53003, N'Referenced space no longer exists.', 1;
        END

        -- [CC-02] HOLDLOCK availability range read: an overlapping instant
        --   booking or another staff approval that commits concurrently cannot
        --   slip between this check and the recording of the approval (BR-14,
        --   BR-49, BR-50). This is the decisive check that closes the race
        --   between the approval and booking-submission paths.
        IF EXISTS (
            SELECT 1
              FROM bookings WITH (HOLDLOCK)
             WHERE space_code            = @space_code
               AND booking_id            <> @booking_id
               AND status                = N'approved'
               AND requested_start_time  < @requested_end_time
               AND requested_end_time    > @requested_start_time
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 53004, N'Approval would create overlapping approved bookings.', 1;
        END

        -- [CC-03] HOLDLOCK out-of-service range read: approval cannot proceed
        --   while the space is (or concurrently becomes) out of service.
        IF EXISTS (
            SELECT 1
              FROM maintenance_records WITH (HOLDLOCK)
             WHERE space_code            = @space_code
               AND impact_level          = N'out_of_service'
               AND status                IN (N'reported', N'in_progress')
               AND start_time            < @requested_end_time
               AND (completion_time IS NULL OR completion_time > @requested_start_time)
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 53005, N'The space is out of service for the requested period.', 1;
        END

        -- [CC-04] HOLDLOCK advisory range read and acknowledgement refresh so
        --   the advisory set is stable at the point the booking becomes
        --   approved (BR-45 / BR-46).
        DECLARE @advisory_active BIT =
            CASE WHEN EXISTS (
                SELECT 1
                  FROM maintenance_records WITH (HOLDLOCK)
                 WHERE space_code            = @space_code
                   AND impact_level          = N'advisory'
                   AND status                IN (N'reported', N'in_progress')
                   AND start_time            < @requested_end_time
                   AND (completion_time IS NULL OR completion_time > @requested_start_time)
            ) THEN 1 ELSE 0 END;

        UPDATE bookings
           SET status                = N'approved',
               advisory_acknowledged = CASE WHEN @advisory_active = 1 THEN 1 ELSE NULL END
         WHERE booking_id = @booking_id;

        INSERT INTO approvals (booking_id, approver_id, decision, decision_time, decision_note)
        VALUES (@booking_id, @approver_id, N'approved', SYSUTCDATETIME(), @decision_note);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- 3. CC-03 / CC-05 — MAINTENANCE IMPACT LEVEL OPERATIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OP-04: usp_escalate_maintenance_impact
-- CC-03 (vs concurrent bookings) + CC-05 (vs concurrent decisions)
-- Mechanism: READ COMMITTED + UPDLOCK (space row) + UPDLOCK (maintenance
--   record row) + HOLDLOCK (affected-bookings range scan, OP-08)
-- Lock order: space row first, then maintenance record, then the scan —
--   identical to the booking path so escalation and booking can never form a
--   lock cycle.
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_escalate_maintenance_impact
    @maintenance_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_code      VARCHAR(20);
        DECLARE @start_time      DATETIME2;
        DECLARE @completion_time DATETIME2;
        DECLARE @impact_level    VARCHAR(20);
        DECLARE @main_status     VARCHAR(20);

        -- Unlocked probe to discover the space and maintenance period. The
        -- record itself is re-read with UPDLOCK below before any decision is
        -- applied, so a level change that commits between the probe and the
        -- lock is never overwritten.
        SELECT @space_code      = space_code,
               @start_time      = start_time,
               @completion_time = completion_time
          FROM maintenance_records
         WHERE maintenance_id = @maintenance_id;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 54001, N'Maintenance record not found.', 1;
        END

        -- [CC-03] UPDLOCK on the space row acquired BEFORE the maintenance
        --   record lock (space-first lock order shared with the booking path).
        SELECT space_code
          FROM spaces WITH (UPDLOCK, HOLDLOCK)
         WHERE space_code = @space_code;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 54002, N'Referenced space no longer exists.', 1;
        END

        -- [CC-05] UPDLOCK on the maintenance record row: a concurrent
        --   escalation or downgrade decision (OP-04/OP-05) blocks until this
        --   decision commits, so the second decision is applied to the latest
        --   committed level instead of a stale read (lost-update prevention,
        --   BR-47).
        SELECT @start_time      = start_time,
               @completion_time = completion_time,
               @impact_level    = impact_level,
               @main_status     = status
          FROM maintenance_records WITH (UPDLOCK, HOLDLOCK)
         WHERE maintenance_id = @maintenance_id;

        IF @main_status NOT IN (N'reported', N'in_progress')
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 54003, N'Only open maintenance records can be escalated.', 1;
        END

        IF @impact_level = N'out_of_service'
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 54004, N'The maintenance record is already out of service.', 1;
        END

        -- Guarded update: the level must still be 'advisory' at write time;
        -- if a concurrent decision committed in between, no row is updated and
        -- the decision is aborted (BR-47).
        UPDATE maintenance_records
           SET impact_level = N'out_of_service'
         WHERE maintenance_id = @maintenance_id
           AND impact_level   = N'advisory'
           AND status         IN (N'reported', N'in_progress');

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 54005, N'The maintenance record changed concurrently; decision aborted.', 1;
        END

        -- [CC-03][OP-08] HOLDLOCK on the affected approved-bookings range:
        --   the scan (required by BR-48 so staff can contact requesters) is
        --   protected against a booking that commits concurrently. A booking
        --   for an overlapping period either blocks until this escalation
        --   commits (and is then rejected by the booking-side checks) or is
        --   already visible in this result set — it cannot be missed.
        SELECT b.booking_id,
               b.requester_id,
               u.email             AS requester_email,
               b.requested_start_time,
               b.requested_end_time,
               b.purpose
          FROM bookings b WITH (HOLDLOCK)
          JOIN users    u ON u.user_id = b.requester_id
         WHERE b.space_code = @space_code
           AND b.status     = N'approved'
           AND (b.requested_start_time < @completion_time OR @completion_time IS NULL)
           AND b.requested_end_time     > @start_time
         ORDER BY b.requested_start_time;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-05: usp_downgrade_maintenance_impact
-- CC-05 (vs concurrent escalation/downgrade decisions)
-- Mechanism: READ COMMITTED + UPDLOCK (maintenance record row)
-- Row-level conflict, so the least restrictive sufficient mechanism is a
--   row-level update lock acquired at the read.
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_downgrade_maintenance_impact
    @maintenance_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @impact_level VARCHAR(20);
        DECLARE @main_status  VARCHAR(20);

        -- [CC-05] UPDLOCK on the maintenance record row (same mechanism as the
        --   escalation path): concurrent decisions on this record serialize.
        SELECT @impact_level = impact_level,
               @main_status  = status
          FROM maintenance_records WITH (UPDLOCK, HOLDLOCK)
         WHERE maintenance_id = @maintenance_id;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 55001, N'Maintenance record not found.', 1;
        END

        IF @main_status NOT IN (N'reported', N'in_progress')
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 55002, N'Only open maintenance records can be downgraded.', 1;
        END

        -- advisory is the minimum impact level (assumption A-01 / Q-06), so a
        -- downgrade of an advisory record is a no-op.
        IF @impact_level = N'advisory'
        BEGIN
            COMMIT TRANSACTION;
            RETURN 0;
        END

        -- Guarded update; aborts if the level changed concurrently (BR-47).
        UPDATE maintenance_records
           SET impact_level = N'advisory'
         WHERE maintenance_id = @maintenance_id
           AND impact_level   = N'out_of_service'
           AND status         IN (N'reported', N'in_progress');

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 55003, N'The maintenance record changed concurrently; decision aborted.', 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- 4. CC-04 — MAINTENANCE RECORDING OPERATIONS
-- ----------------------------------------------------------------------------
-- OP-06 / OP-07 insert a new open maintenance record. No locking hint is
-- required on the INSERT itself: a booking transaction holds HOLDLOCK range
-- locks over the space's active maintenance records for its requested period,
-- so a recording that would overlap an in-flight booking blocks until that
-- booking commits. The advisory is then either captured in the booking's
-- notification (if it commits first) or correctly excluded (if it commits
-- after the booking) — BR-45 / BR-46 cannot be violated.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OP-06: usp_record_advisory_maintenance
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_record_advisory_maintenance
    @reporter_id         VARCHAR(50),
    @space_code          VARCHAR(20),
    @assigned_staff_id   VARCHAR(50),
    @problem_description NVARCHAR(1000),
    @start_time          DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO maintenance_records (
            reporter_id, space_code, assigned_staff_id, problem_description,
            start_time, completion_time, status, impact_level
        )
        VALUES (
            @reporter_id, @space_code, @assigned_staff_id, @problem_description,
            @start_time, NULL, N'reported', N'advisory'
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- OP-07: usp_record_out_of_service_maintenance
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_record_out_of_service_maintenance
    @reporter_id         VARCHAR(50),
    @space_code          VARCHAR(20),
    @assigned_staff_id   VARCHAR(50),
    @problem_description NVARCHAR(1000),
    @start_time          DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO maintenance_records (
            reporter_id, space_code, assigned_staff_id, problem_description,
            start_time, completion_time, status, impact_level
        )
        VALUES (
            @reporter_id, @space_code, @assigned_staff_id, @problem_description,
            @start_time, NULL, N'reported', N'out_of_service'
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- 5. CC-03 — AFFECTED BOOKINGS SCAN
-- ============================================================================

-- ----------------------------------------------------------------------------
-- OP-08: usp_identify_affected_bookings
-- CC-03 (Direction B), standalone version of the scan embedded in
--   usp_escalate_maintenance_impact. Identifies all approved bookings
--   overlapping the maintenance period so staff can contact the requesters
--   (BR-48).
-- Mechanism: READ COMMITTED + HOLDLOCK (approved-bookings range read)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_identify_affected_bookings
    @maintenance_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @space_code      VARCHAR(20);
        DECLARE @start_time      DATETIME2;
        DECLARE @completion_time DATETIME2;

        SELECT @space_code      = space_code,
               @start_time      = start_time,
               @completion_time = completion_time
          FROM maintenance_records
         WHERE maintenance_id = @maintenance_id;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 56001, N'Maintenance record not found.', 1;
        END

        -- [CC-03][OP-08] HOLDLOCK over the approved-bookings range: a booking
        --   approved concurrently with this scan cannot be missed; it either
        --   blocks until the scan commits or is already part of the result.
        SELECT b.booking_id,
               b.requester_id,
               u.email             AS requester_email,
               b.requested_start_time,
               b.requested_end_time,
               b.purpose
          FROM bookings b WITH (HOLDLOCK)
          JOIN users    u ON u.user_id = b.requester_id
         WHERE b.space_code = @space_code
           AND b.status     = N'approved'
           AND (b.requested_start_time < @completion_time OR @completion_time IS NULL)
           AND b.requested_end_time     > @start_time
         ORDER BY b.requested_start_time;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- 6. IMPLEMENTATION SUMMARY (traceability)
-- ----------------------------------------------------------------------------
-- Conflict | Business rules   | Enforcing procedure(s)                  | Mechanism
-- CC-01    | BR-14, BR-50     | usp_create_instant_booking             | READ COMMITTED + UPDLOCK(space) + HOLDLOCK(availability)
-- CC-02    | BR-14,BR-49,BR-50| usp_create_instant_booking,            | READ COMMITTED + UPDLOCK(space) + HOLDLOCK(availability)
--          |                  | usp_submit_booking_request,            |
--          |                  | usp_approve_booking                    |
-- CC-03    | BR-44, BR-48     | usp_escalate_maintenance_impact,       | UPDLOCK(space) + UPDLOCK(maintenance row) + HOLDLOCK(affected range);
--          |                  | usp_identify_affected_bookings,        | booking path holds HOLDLOCK over active out-of-service range
--          |                  | usp_create_instant_booking,            |
--          |                  | usp_submit_booking_request,            |
--          |                  | usp_approve_booking                    |
-- CC-04    | BR-45, BR-46     | usp_create_instant_booking,            | HOLDLOCK(active advisory range) in booking path;
--          |                  | usp_submit_booking_request,            | usp_record_advisory_maintenance needs no hint
--          |                  | usp_approve_booking                    |
-- CC-05    | BR-47            | usp_escalate_maintenance_impact,       | READ COMMITTED + UPDLOCK(maintenance record row)
--          |                  | usp_downgrade_maintenance_impact       |
--
-- Verification: outputs/13-concurrency-tests-G7/ exercises these procedures
-- under simultaneous transactions.
-- ============================================================================

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
