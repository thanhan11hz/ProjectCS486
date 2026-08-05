-- ============================================================================
-- Concurrency Implementation Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+
-- Description : Implements the concurrency enforcement from the concurrency
--               design (outputs/11-concurrency-design-G7.md) on top of the
--               Phase 2 migrated schema (outputs/10-schema-migration-G7.sql).
--               Provides stored procedures for each concurrent operation
--               (OP-01..OP-08) with the isolation levels and locking hints
--               recommended in the design.
-- Artifact    : outputs/12-concurrency-implementation-G7.sql
-- Prerequisite: outputs/11-concurrency-design-G7.md
--               outputs/10-schema-migration-G7.sql
--               outputs/05-db-implementation-G7.sql
-- Notes       : DML + concurrency only. Does NOT modify the schema. Does NOT
--               seed data. Designed to run after the Phase 2 migration is
--               applied.
-- ============================================================================

USE [CS486_Booking_System];
GO

SET NOCOUNT ON;
GO

-- ============================================================================
-- 1. METHODOLOGY / MAPPING
-- ----------------------------------------------------------------------------
-- Each stored procedure implements one concurrent business operation and uses
-- the mechanism recommended for the corresponding conflict:
--
--   Conflict / Operation                Mechanism
--   -------------------------------------------------------------------------
--   CC-01  OP-01 Create Instant Booking SERIALIZABLE + UPDLOCK(space)
--                                        + HOLDLOCK(range reads)   [OP-01]
--   CC-02  OP-03 Approve Booking        SERIALIZABLE + UPDLOCK(space)
--                                        + HOLDLOCK(range reads)   [OP-03]
--   CC-03  OP-04 Escalate Level (OOS)   SERIALIZABLE + UPDLOCK(maintenance row)
--                                        + HOLDLOCK(booking range scan)
--                                                                  [OP-04, OP-08]
--   CC-04  OP-01/02 Advisory capture    SERIALIZABLE + HOLDLOCK(advisory range)
--                                                                  [within OP-01/02]
--   CC-05  OP-04/05 Level decision      READ COMMITTED + UPDLOCK(row)
--                                                                  [OP-05; row step of OP-04]
--
-- Conventions used throughout:
--   * XACT_ABORT ON so any runtime error rolls back the whole operation.
--   * Transactions are opened explicitly; validation reads and writes share
--     one transaction (design assumption A-04 / A-07).
--   * The space row is read with UPDLOCK as the common serialization point for
--     all booking/approval paths (design A-05).
--   * Availability and maintenance state reads use HOLDLOCK under SERIALIZABLE
--     to take range locks that prevent phantom overlaps (CC-01..CC-04).
--   * Impact-level decision reads use UPDLOCK under READ COMMITTED to prevent
--     lost updates on the single maintenance row (CC-05).
-- ============================================================================

-- ============================================================================
-- 2. HELPER: SPACE AVAILABILITY CHECK (range + maintenance)
-- ----------------------------------------------------------------------------
-- Shared availability validation for every booking path (OP-01, OP-02, OP-03).
-- Must be called INSIDE an existing SERIALIZABLE transaction so that the
-- HOLDLOCK range reads are held for the duration of the enclosing operation.
--
-- Returns:
--   0  = free: no overlapping approved booking and no overlapping
--        out-of-service maintenance for [@start,@end) on the space.
--   1  = blocked by an overlapping APPROVED booking (BR-14/BR-50).
--   2  = blocked by active OUT_OF_SERVICE maintenance (BR-44).
--   3  = space not bookable by its status (BR-32).
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CheckSpaceAvailability
    @space_code      VARCHAR(20),
    @start_time      DATETIME2,
    @end_time        DATETIME2,
    @availability    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @space_status VARCHAR(30);

    -- UPDLOCK on the space row: common serialization point that orders all
    -- booking/approval operations on the same space (CC-01/02/03).
    SELECT @space_status = status
    FROM   dbo.spaces WITH (UPDLOCK, ROWLOCK)
    WHERE  space_code = @space_code;

    IF @space_status IS NULL
    BEGIN
        SET @availability = 4;             -- space does not exist
        RETURN;
    END

    IF @space_status IN (N'under_maintenance', N'temporarily_closed', N'retired')
    BEGIN
        SET @availability = 3;             -- BR-32
        RETURN;
    END

    -- CC-01/02: overlapping APPROVED booking check. HOLDLOCK + SERIALIZABLE
    -- turns the range scan into a key-range lock so a concurrent insert of an
    -- overlapping approved booking cannot commit while we are uncommitted.
    IF EXISTS (
        SELECT 1
        FROM   dbo.bookings WITH (HOLDLOCK, ROWLOCK)
        WHERE  space_code = @space_code
          AND  status     = N'approved'
          AND  requested_start_time < @end_time
          AND  requested_end_time   > @start_time
    )
    BEGIN
        SET @availability = 1;             -- BR-14 / BR-50
        RETURN;
    END

    -- CC-03: active OUT_OF_SERVICE maintenance check. Hold the range lock so an
    -- escalation to out-of-service overlapping [@start,@end) must wait until
    -- this check of the period is committed.
    IF EXISTS (
        SELECT 1
        FROM   dbo.maintenance_records WITH (HOLDLOCK, ROWLOCK)
        WHERE  space_code   = @space_code
          AND  impact_level = N'out_of_service'
          AND  start_time   < @end_time
          AND  (completion_time IS NULL OR completion_time > @start_time)
    )
    BEGIN
        SET @availability = 2;             -- BR-44
        RETURN;
    END

    SET @availability = 0;                 -- free
END;
GO

-- ============================================================================
-- 3. OP-01 — CREATE INSTANT BOOKING  (CC-01, CC-04)
-- ----------------------------------------------------------------------------
-- User submits a booking that auto-approves at submission time (BR-49).
-- Runs entirely under SERIALIZABLE so the availability range locks and the
-- active-advisory range locks prevent phantom overlaps and notify the
-- requester of exactly the advisories active at booking time (BR-45/46).
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CreateInstantBooking
    @requester_id          VARCHAR(50),
    @space_code            VARCHAR(20),
    @requested_start_time  DATETIME2,
    @requested_end_time    DATETIME2,
    @purpose               VARCHAR(30),
    @expected_participants INT,
    @booking_id            INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @availability INT;
    DECLARE @capacity     INT;
    DECLARE @has_advisory BIT = 0;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Shared availability + maintenance check (BR-14, BR-44, BR-32).
        EXEC dbo.usp_CheckSpaceAvailability
            @space_code, @requested_start_time, @requested_end_time,
            @availability OUTPUT;

        IF @availability <> 0
        BEGIN
            ROLLBACK;
            RAISERROR(N'Instant booking rejected: availability code %d.', 16, 1, @availability);
            RETURN;
        END

        -- CC-04: capture the stable advisory set active at booking time under
        -- range locks, so a concurrent advisory insert is not missed and the
        -- acknowledgement is complete (BR-45, BR-46).
        SELECT @has_advisory = CASE WHEN COUNT_BIG(*) > 0 THEN 1 ELSE 0 END
        FROM   dbo.maintenance_records WITH (HOLDLOCK, ROWLOCK)
        WHERE  space_code   = @space_code
          AND  impact_level = N'advisory'
          AND  start_time   < @requested_end_time
          AND  (completion_time IS NULL OR completion_time > @requested_start_time);

        -- Capacity validation (BR-40 / BR-NI-05).
        SELECT @capacity = capacity
        FROM   dbo.spaces
        WHERE  space_code = @space_code;

        IF @expected_participants > @capacity
        BEGIN
            ROLLBACK;
            RAISERROR(N'Expected participants exceed space capacity.', 16, 1);
            RETURN;
        END

        -- Record the APPROVED booking (instant approval path, BR-49).
        INSERT INTO dbo.bookings (
            requester_id, space_code, requested_start_time, requested_end_time,
            purpose, expected_participants, status, advisory_acknowledged
        )
        VALUES (
            @requester_id, @space_code, @requested_start_time, @requested_end_time,
            @purpose, @expected_participants, N'approved', @has_advisory
        );

        SET @booking_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- 4. OP-02 — SUBMIT BOOKING REQUEST (staff-approval workflow)
-- ----------------------------------------------------------------------------
-- User submits a request that goes through the staff approval workflow.
-- The submission itself performs a limited availability probe so the request
-- is not queued against an already-conflicting period; it records a PENDING
-- booking (no approval yet). The definitive no-overlap guarantee is enforced
-- at approval time (OP-03), which shares the same SERIALIZABLE mechanism
-- (BR-50). Advisory acknowledgement is captured at submission time, since the
-- requester is informed of active advisories when they request the space.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_SubmitBookingRequest
    @requester_id          VARCHAR(50),
    @space_code            VARCHAR(20),
    @requested_start_time  DATETIME2,
    @requested_end_time    DATETIME2,
    @purpose               VARCHAR(30),
    @expected_participants INT,
    @booking_id            INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @availability INT;
    DECLARE @capacity     INT;
    DECLARE @has_advisory BIT = 0;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
        EXEC dbo.usp_CheckSpaceAvailability
            @space_code, @requested_start_time, @requested_end_time,
            @availability OUTPUT;

        -- Submissions may be queued; only hard unbookable-by-status or
        -- out-of-service blocks abort the submission outright (BR-32, BR-44).
        IF @availability IN (2, 3, 4)
        BEGIN
            ROLLBACK;
            RAISERROR(N'Booking submission rejected: availability code %d.', 16, 1, @availability);
            RETURN;
        END

        -- CC-04: capture the advisory set at submission time (BR-45/46).
        SELECT @has_advisory = CASE WHEN COUNT_BIG(*) > 0 THEN 1 ELSE 0 END
        FROM   dbo.maintenance_records WITH (HOLDLOCK, ROWLOCK)
        WHERE  space_code   = @space_code
          AND  impact_level = N'advisory'
          AND  start_time   < @requested_end_time
          AND  (completion_time IS NULL OR completion_time > @requested_start_time);

        SELECT @capacity = capacity
        FROM   dbo.spaces
        WHERE  space_code = @space_code;

        IF @expected_participants > @capacity
        BEGIN
            ROLLBACK;
            RAISERROR(N'Expected participants exceed space capacity.', 16, 1);
            RETURN;
        END

        INSERT INTO dbo.bookings (
            requester_id, space_code, requested_start_time, requested_end_time,
            purpose, expected_participants, status, advisory_acknowledged
        )
        VALUES (
            @requester_id, @space_code, @requested_start_time, @requested_end_time,
            @purpose, @expected_participants, N'pending', @has_advisory
        );

        SET @booking_id = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- 5. OP-03 — APPROVE BOOKING  (CC-02)
-- ----------------------------------------------------------------------------
-- Staff approves a PENDING booking. Runs the definitive availability check
-- under SERIALIZABLE with UPDLOCK on the space row and HOLDLOCK range reads,
-- so it cannot race an instant booking or another approval into overlapping
-- approved bookings (BR-14, BR-49, BR-50). Records the approval row and flips
-- the booking status.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_ApproveBooking
    @booking_id     INT,
    @approver_id    VARCHAR(50),
    @decision_note  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @space_code        VARCHAR(20);
    DECLARE @start_time        DATETIME2;
    DECLARE @end_time          DATETIME2;
    DECLARE @requester_id      VARCHAR(50);
    DECLARE @current_status    VARCHAR(20);
    DECLARE @availability      INT;
    DECLARE @has_advisory      BIT;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Lock the pending booking with UPDLOCK so two staff members cannot
        -- approve the same request concurrently.
        SELECT @space_code  = space_code,
               @start_time  = requested_start_time,
               @end_time    = requested_end_time,
               @requester_id= requester_id,
               @current_status = status,
               @has_advisory = advisory_acknowledged
        FROM   dbo.bookings WITH (UPDLOCK, ROWLOCK)
        WHERE  booking_id = @booking_id;

        IF @current_status IS NULL
        BEGIN
            ROLLBACK;
            RAISERROR(N'Booking not found.', 16, 1);
            RETURN;
        END

        IF @current_status <> N'pending'
        BEGIN
            ROLLBACK;
            RAISERROR(N'Only pending bookings can be approved (BR-28).', 16, 1);
            RETURN;
        END

        IF @approver_id = @requester_id
        BEGIN
            ROLLBACK;
            RAISERROR(N'Approver must differ from requester (BR-11).', 16, 1);
            RETURN;
        END

        -- CC-02: decisive availability check before the approval is recorded.
        EXEC dbo.usp_CheckSpaceAvailability
            @space_code, @start_time, @end_time, @availability OUTPUT;

        IF @availability <> 0
        BEGIN
            ROLLBACK;
            RAISERROR(N'Approval rejected: overlapping approved booking or out-of-service maintenance (code %d).', 16, 1, @availability);
            RETURN;
        END

        -- Approval decision must precede the booking start (BR-37).
        IF SYSDATETIME() >= @start_time
        BEGIN
            ROLLBACK;
            RAISERROR(N'Approval decision must be before booking start (BR-37).', 16, 1);
            RETURN;
        END

        -- Record the approval and finalize the booking status atomically.
        INSERT INTO dbo.approvals (
            booking_id, approver_id, decision, decision_time, decision_note
        )
        VALUES (@booking_id, @approver_id, N'approved', SYSDATETIME(), @decision_note);

        UPDATE dbo.bookings
        SET    status = N'approved'
        WHERE  booking_id = @booking_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- 6. OP-08 — IDENTIFY AFFECTED APPROVED BOOKINGS  (CC-03)
-- ----------------------------------------------------------------------------
-- Lists approved bookings overlapping a maintenance period. Under SERIALIZABLE
-- + HOLDLOCK this scan takes range locks over the period so no concurrent
-- approval/instant booking can commit into the period while the scan runs,
-- making the affected set complete (BR-48).
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_IdentifyAffectedBookings
    @space_code     VARCHAR(20),
    @start_time     DATETIME2,
    @end_time       DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Range-read approved bookings overlapping [@start,@end).
        SELECT b.booking_id,
               b.requester_id,
               u.first_name,
               u.last_name,
               u.email,
               u.phone_number,
               b.requested_start_time,
               b.requested_end_time
        FROM   dbo.bookings b WITH (HOLDLOCK, ROWLOCK)
        JOIN   dbo.users    u ON u.user_id = b.requester_id
        WHERE  b.space_code = @space_code
          AND  b.status     = N'approved'
          AND  b.requested_start_time < @end_time
          AND  b.requested_end_time   > @start_time
        ORDER  BY b.requested_start_time;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- 7. OP-04 — ESCALATE MAINTENANCE IMPACT LEVEL  (CC-03, CC-05, CC-03/OP-08)
-- ----------------------------------------------------------------------------
-- Staff escalates an OPEN maintenance record from advisory to out-of-service.
-- The whole escalation is one transaction (design A-08):
--   * UPDLOCK read on the maintenance row prevents a lost update against a
--     concurrent downgrade decision (CC-05).
--   * The affected-approved-bookings scan runs under SERIALIZABLE (the
--     enclosing transaction) + HOLDLOCK so it cannot miss a concurrently
--     approved booking (CC-03 Direction B, BR-48).
--   * Because the transaction holds SERIALIZABLE range locks on the period,
--     a concurrent booking into the period is blocked (CC-03 Direction A,
--     BR-44).
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_EscalateMaintenanceToOutOfService
    @maintenance_id  INT,
    @staff_id        VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @space_code   VARCHAR(20);
    DECLARE @start_time   DATETIME2;
    DECLARE @completion   DATETIME2;
    DECLARE @cur_level    VARCHAR(20);
    DECLARE @cur_status   VARCHAR(20);

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- CC-05: UPDLOCK read of the maintenance row. This serializes concurrent
        -- escalation/downgrade decisions on the same record (BR-47).
        SELECT @space_code = space_code,
               @start_time = start_time,
               @completion = completion_time,
               @cur_level  = impact_level,
               @cur_status = status
        FROM   dbo.maintenance_records WITH (UPDLOCK, ROWLOCK)
        WHERE  maintenance_id = @maintenance_id;

        IF @cur_status IS NULL
        BEGIN
            ROLLBACK;
            RAISERROR(N'Maintenance record not found.', 16, 1);
            RETURN;
        END

        -- Escalation/downgrade applies only while the record is OPEN (A-02).
        IF @cur_status = N'completed'
        BEGIN
            ROLLBACK;
            RAISERROR(N'Maintenance record is already completed.', 16, 1);
            RETURN;
        END

        -- Apply the escalation.
        UPDATE dbo.maintenance_records
        SET    impact_level = N'out_of_service',
               assigned_staff_id = @staff_id
        WHERE  maintenance_id = @maintenance_id;

        -- CC-03 / OP-08: identify affected approved bookings. The HOLDLOCK scan
        -- takes range locks over the maintenance period so no booking can commit
        -- into it concurrently (BR-48). The affected list is returned to the
        -- caller so staff can contact the requesters.
        SELECT b.booking_id,
               b.requester_id,
               u.first_name,
               u.last_name,
               u.email,
               b.requested_start_time,
               b.requested_end_time
        FROM   dbo.bookings b WITH (HOLDLOCK, ROWLOCK)
        JOIN   dbo.users    u ON u.user_id = b.requester_id
        WHERE  b.space_code = @space_code
          AND  b.status     = N'approved'
          AND  b.requested_start_time < CASE WHEN @completion IS NULL THEN @start_time + 1 WHEN @completion > @start_time THEN @completion ELSE @start_time + 1 END
          AND  b.requested_end_time   > @start_time;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- 8. OP-05 — DOWNGRADE MAINTENANCE IMPACT LEVEL  (CC-05)
-- ----------------------------------------------------------------------------
-- Staff downgrades an OPEN maintenance record (out-of-service -> advisory).
-- A pure row-level decision, protected from lost updates by the UPDLOCK read
-- on the maintenance row under READ COMMITTED (CC-05, BR-47). No range scan is
-- required, so the least-restrictive row-level mechanism is sufficient.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_DowngradeMaintenanceToAdvisory
    @maintenance_id  INT,
    @staff_id        VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @cur_level    VARCHAR(20);
    DECLARE @cur_status   VARCHAR(20);

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- CC-05: UPDLOCK read. Under READ COMMITTED this is an update lock that
        -- is retained until commit, blocking a concurrent decision and forcing
        -- the second decision to be evaluated against the latest committed
        -- level (BR-47). Prevents the lost update / lost-workflow problem.
        SELECT @cur_level  = impact_level,
               @cur_status = status
        FROM   dbo.maintenance_records WITH (UPDLOCK, ROWLOCK)
        WHERE  maintenance_id = @maintenance_id;

        IF @cur_status IS NULL
        BEGIN
            ROLLBACK;
            RAISERROR(N'Maintenance record not found.', 16, 1);
            RETURN;
        END

        IF @cur_status = N'completed'
        BEGIN
            ROLLBACK;
            RAISERROR(N'Maintenance record is already completed (A-02).', 16, 1);
            RETURN;
        END

        IF @cur_level = N'advisory'
        BEGIN
            ROLLBACK;
            RAISERROR(N'Impact level is already advisory.', 16, 1);
            RETURN;
        END

        UPDATE dbo.maintenance_records
        SET    impact_level = N'advisory',
               assigned_staff_id = @staff_id
        WHERE  maintenance_id = @maintenance_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ============================================================================
-- 9. OP-06 / OP-07 — RECORD MAINTENANCE  (advisory / out-of-service)
-- ----------------------------------------------------------------------------
-- Staff records a NEW open maintenance record for a space with an impact level.
-- The insert takes the impact_level value directly (BR-42). Because the new
-- row is inserted, it may block concurrent bookings only if it is
-- out_of_service; the SERIALIZABLE range protection for such bookings is
-- enforced by the booking-side availability check, not here. This procedure
-- just records the maintenance record; it does not need extra locking.
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_RecordMaintenance
    @reporter_id         VARCHAR(50),
    @space_code          VARCHAR(20),
    @assigned_staff_id   VARCHAR(50),
    @problem_description NVARCHAR(1000),
    @start_time          DATETIME2,
    @impact_level        VARCHAR(20),
    @maintenance_id      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    INSERT INTO dbo.maintenance_records (
        reporter_id, space_code, assigned_staff_id, problem_description,
        start_time, status, impact_level
    )
    VALUES (
        @reporter_id, @space_code, @assigned_staff_id, @problem_description,
        @start_time, N'in_progress', @impact_level
    );

    SET @maintenance_id = SCOPE_IDENTITY();
END;
GO

-- ============================================================================
-- 10. CONCURRENCY TEST SCENARIOS (verification queries)
-- ----------------------------------------------------------------------------
-- Runnable smoke checks after seeding + migration. Each scenario opens two
-- concurrent transactions and verifies the enforced invariant. These are the
-- SQL-level manifestations of the scenarios specified in the concurrency
-- design (outputs/13-concurrency-tests-G7/).
--
-- Scenario A (CC-01/CC-02): simultaneous instant bookings / approval for an
--   overlapping period on the same space. Under SERIALIZABLE one of the two
--   must block and ultimately fail with availability code 1; the overlapping
--   approved booking invariant (BR-14, BR-50) holds.
--
-- Scenario B (CC-03): an escalation to out-of-service concurrent with a
--   booking into the maintenance period. Either the booking commits first and
--   is listed as affected, or the escalation commits first and the booking
--   fails with availability code 2 (BR-44, BR-48).
--
-- Scenario C (CC-05): two concurrent decisions on the same maintenance row.
--   With UPDLOCK one decision blocks; the second is evaluated against the
--   latest committed level, so no decision is silently lost (BR-47).
-- ============================================================================
-- Usage (SSMS, two query windows):
--   Window 1:
--     BEGIN TRANSACTION;
--       EXEC dbo.usp_CreateInstantBooking ...;
--     -- pause before COMMIT to demonstrate the block
--     COMMIT TRANSACTION;
--   Window 2:
--     EXEC dbo.usp_CreateInstantBooking ...;  -- blocks, then fails
-- ============================================================================

-- ============================================================================
-- 11. RESET ISOLATION LEVEL TO SERVER DEFAULT
-- ----------------------------------------------------------------------------
-- Individual procedures set the transaction isolation level explicitly at the
-- start of their own batch-scope transactions, so the session-level default
-- can be left at its (unchanged) READ COMMITTED baseline afterward.
-- ============================================================================
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================