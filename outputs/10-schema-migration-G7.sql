-- ============================================================================
-- Schema Migration Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Description : Evolves the Phase 1 database schema to the Phase 2 schema.
--               Existing data is preserved wherever possible.
-- Baseline    : outputs/05-db-implementation-G7.sql (Phase 1 schema)
-- Change src  : outputs/08-req-change-analysis-G7.md   (RC-01 .. RC-08)
-- Design      : outputs/09-updated-erd-and-logical-design-G7.md (C-01 .. C-06)
-- Artifact    : outputs/10-schema-migration-G7.sql
-- Prerequisite: Database CS486_Booking_System must exist (created by
--               outputs/05-db-implementation-G7.sql; may be populated by
--               outputs/06-sample-data-G7.sql).
-- Notes       : - Idempotent: every statement is guarded so the script can be
--                 executed repeatedly without failing (Rule M1).
--               - Schema-level changes only. Concurrency control mechanisms
--                 (transactions, isolation levels, locking hints, row
--                 versioning) belong to outputs/12-concurrency-implementation-
--                 G7.sql (Rule BC5).
-- ============================================================================

-- ============================================================================
-- 1. HEADER BLOCK — Execution Context and Database Guard
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- The migration evolves an existing database; it must not create one.
-- If the Phase 1 database is missing, abort with a clear message instead of
-- failing later with confusing errors.
IF DB_ID(N'CS486_Booking_System') IS NULL
    THROW 51000, N'Database CS486_Booking_System does not exist. Execute outputs/05-db-implementation-G7.sql first.', 1;
GO

USE [CS486_Booking_System];
GO

-- ============================================================================
-- 2. SCHEMA CHANGE SUMMARY
-- ----------------------------------------------------------------------------
-- Derived from the comparison between outputs/05-db-implementation-G7.sql and
-- the updated logical design (outputs/09-updated-erd-and-logical-design-G7.md).
--
-- | # | Change                              | Source    | Business Rule | Type    |
-- |---|-------------------------------------|-----------|---------------|---------|
-- | S1| bookings.advisory_acknowledged (new column, BIT NULL) | RC-02 | BR-46 | Add column |
-- | S2| maintenance_records.impact_level (new column, VARCHAR, NOT NULL) | RC-01 | BR-42 | Add column |
-- | S3| ck_maintenance_records_impact_level (CHECK)   | RC-01 | BR-42 | New constraint |
-- | S4| ck_bookings_advisory_acknowledged (CHECK)     | RC-02 | BR-46 | New constraint |
-- | S5| trg_bookings_br44_no_overlap_out_of_service   | RC-01 | BR-44 | New trigger |
-- | S6| trg_bookings_br46_advisory_acknowledgement    | RC-02 | BR-46 | New trigger |
-- | S7| trg_maintenance_records_br47_impact_level     | RC-04 | BR-47 | New trigger |
--
-- No tables are added or removed, no FK is added/removed (all 11 Phase 1 FKs
-- are retained unchanged), and no PK/UNIQUE constraint changes. BR-19
-- (no overlapping open maintenance records) is removed by RC-03 but was never
-- implemented as DDL in Phase 1 (BR-NI-07, application-layer only), so there
-- is no schema object to drop.
-- ============================================================================

-- ============================================================================
-- 3. COLUMN ADDITIONS (Rule M2, M3, M5 — add nullable first, backfill, then
--    enforce NOT NULL so existing data is preserved)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 bookings.advisory_acknowledged  (RC-02, BR-46)
-- ----------------------------------------------------------------------------
-- Records that the requester was informed of all active advisory maintenance
-- records on the space at booking time and acknowledged them.
-- - NULL  = no advisory was active at booking time (BR-45) — the correct
--   value for ALL pre-existing Phase 1 bookings, which were created before
--   the notification obligation existed. No backfill is required.
-- - 1     = requester acknowledged the active advisories.
-- A value of 0 is meaningless for this column (it exists only to record the
-- acknowledgement) and is rejected by ck_bookings_advisory_acknowledged.
-- The conditional requirement "must be 1 when an advisory is active" is a
-- cross-table check and is enforced by trg_bookings_br46_advisory_acknowledge-
-- ment (Section 5.2).
IF COL_LENGTH(N'bookings', N'advisory_acknowledged') IS NULL
BEGIN
    ALTER TABLE bookings
        ADD advisory_acknowledged BIT NULL;
END
GO

-- ----------------------------------------------------------------------------
-- 3.2 maintenance_records.impact_level  (RC-01, BR-42)
-- ----------------------------------------------------------------------------
-- Severity of the maintenance with respect to space usability:
--   out_of_service  = space unusable; booking blocked for overlapping periods
--   advisory        = space usable; requester must be notified
--
-- Step 1 — add the column as nullable so existing rows are not disturbed.
IF COL_LENGTH(N'maintenance_records', N'impact_level') IS NULL
BEGIN
    ALTER TABLE maintenance_records
        ADD impact_level VARCHAR(20) NULL;
END
GO

-- Step 2 — backfill existing records with semantically inferred values
-- (Rule M5: infer from the original business semantics, do not invent
-- arbitrary values).
--   * reported / in_progress records: Phase 1 BR-33 made ANY open maintenance
--     record block booking for the space, i.e. the space was treated as
--     unusable while the record was open — the exact semantics of
--     out_of_service. Inferred value: out_of_service.
--   * completed records: Phase 1 gave them no booking effect at all (only
--     open records blocked booking), so the least-severe level is inferred.
--     Inferred value: advisory.
-- See Section 7 (A-M01, A-M02) for the documented migration assumptions.
UPDATE maintenance_records
   SET impact_level = CASE
                          WHEN status IN (N'reported', N'in_progress')
                              THEN N'out_of_service'
                          ELSE N'advisory'
                      END
 WHERE impact_level IS NULL;
GO

-- Step 3 — enforce NOT NULL (BR-42: every maintenance record has exactly one
-- impact level). No DEFAULT is applied: a default would be an arbitrary value
-- for future inserts (Rule M2/M5); new records must supply impact_level
-- explicitly, as the Phase 2 operations in
-- outputs/12-concurrency-implementation-G7.sql already do.
IF COL_LENGTH(N'maintenance_records', N'impact_level') IS NOT NULL
   AND EXISTS (SELECT 1
                 FROM sys.columns c
                WHERE c.object_id  = OBJECT_ID(N'maintenance_records')
                  AND c.name       = N'impact_level'
                  AND c.is_nullable = 1)
BEGIN
    ALTER TABLE maintenance_records
        ALTER COLUMN impact_level VARCHAR(20) NOT NULL;
END
GO

-- ============================================================================
-- 4. DECLARATIVE CONSTRAINTS (Rule S2, BC1)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 4.1 ck_maintenance_records_impact_level (BR-42, RC-01)
-- ----------------------------------------------------------------------------
-- The two impact levels defined by the requirements are exhaustive
-- (assumption A-01 / ULD-01).
IF NOT EXISTS (SELECT 1
                 FROM sys.check_constraints
                WHERE name = N'ck_maintenance_records_impact_level')
BEGIN
    ALTER TABLE maintenance_records
        ADD CONSTRAINT ck_maintenance_records_impact_level
            CHECK (impact_level IN (N'out_of_service', N'advisory'));
END
GO

-- ----------------------------------------------------------------------------
-- 4.2 ck_bookings_advisory_acknowledged (BR-46, RC-02)
-- ----------------------------------------------------------------------------
-- The column records the requester's acknowledgement; it is either
--   * NULL (no advisory was active at booking time — BR-45), or
--   * 1 (the requester acknowledged being informed of the advisories).
-- 0 carries no business meaning and is rejected.
IF NOT EXISTS (SELECT 1
                 FROM sys.check_constraints
                WHERE name = N'ck_bookings_advisory_acknowledged')
BEGIN
    ALTER TABLE bookings
        ADD CONSTRAINT ck_bookings_advisory_acknowledged
            CHECK (advisory_acknowledged IS NULL OR advisory_acknowledged = 1);
END
GO

-- ============================================================================
-- 5. TRIGGER-BASED CONSTRAINTS (Rule BC2, BC3, BC4)
-- ----------------------------------------------------------------------------
-- Business rules that cannot be expressed as scalar declarative constraints
-- (cross-table / multi-row temporal validation) are implemented as triggers.
-- Each trigger:
--   * validates only the rules affected by its triggering operation (BC3),
--   * rejects violations with a clearly identified error (BC4),
--   * performs NO isolation/locking/versioning — concurrency control is
--     owned by outputs/12-concurrency-implementation-G7.sql (BC5).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5.1 BR-44: A space with an active out-of-service maintenance record cannot
--            be booked for any period overlapping the maintenance period.
--            (RC-01; replaces the Phase 1 blanket open-maintenance blocking
--            of BR-32/BR-33)
-- ----------------------------------------------------------------------------
-- Table   : bookings  (INSERT, UPDATE)
-- Rationale: the violating operation is the creation of a booking over an
--   open out-of-service record, so the trigger sits on bookings. It is NOT
--   placed on maintenance_records: escalation to out-of-service must be
--   allowed to proceed so that already-affected approved bookings can be
--   identified for staff contact (BR-48, Q-04) — existing bookings are never
--   retroactively rejected.
-- Scope   : the check runs only when the reservation itself changes —
--   INSERT, or UPDATE of space_code / requested times / status. Status
--   transitions into the effective states (pending, approved) are re-checked
--   so no approval can create an overlapping reservation (consistent with the
--   approval-time check in outputs/12-concurrency-implementation-G7.sql).
--   Rows with status rejected/cancelled are not reservations and are exempt.
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_bookings_br44_no_overlap_out_of_service
ON bookings
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Re-check only when the reservation itself changed.
    IF NOT (UPDATE(space_code)
            OR UPDATE(requested_start_time)
            OR UPDATE(requested_end_time)
            OR UPDATE(status))
        RETURN;

    IF EXISTS
    (
        SELECT 1
          FROM inserted i
          INNER JOIN maintenance_records m
                  ON m.space_code = i.space_code
         WHERE m.impact_level   = N'out_of_service'
           AND m.status         IN (N'reported', N'in_progress')   -- open record
           -- Period overlap: [start_time, completion_time) vs requested range
           AND i.requested_end_time > m.start_time
           AND (m.completion_time IS NULL
                OR i.requested_start_time < m.completion_time)
           -- Exclude non-reservations (rejected/cancelled)
           AND i.status NOT IN (N'rejected', N'cancelled')
           AND
           (
               -- INSERT: every effective new booking is checked
               NOT EXISTS (SELECT 1 FROM deleted d WHERE d.booking_id = i.booking_id)
               -- UPDATE: re-check when space/times changed, or when the status
               -- moves into an effective reservation state
               OR UPDATE(space_code)
               OR UPDATE(requested_start_time)
               OR UPDATE(requested_end_time)
               OR i.status IN (N'pending', N'approved')
           )
    )
    BEGIN
        RAISERROR(N'BR-44 violation: the requested period overlaps an active out-of-service maintenance record for this space. Booking is not permitted.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- 5.2 BR-46: When active advisory maintenance overlaps the booking period,
--            the booking MUST record the requester's acknowledgement that
--            they were informed of all active advisories (advisory_acknow-
--            ledged = 1).  (RC-02; conditional nullability per BR-45)
-- ----------------------------------------------------------------------------
-- Table   : bookings  (INSERT, UPDATE)
-- Rationale: the violation is a booking row that misses the acknowledgement
--   while an overlapping open advisory record exists. The trigger re-checks
--   when the reservation changes (space/times/status) and when the
--   acknowledgement itself is modified, so the acknowledgement can never be
--   silently cleared (CC-04's booking side). Recording an advisory AFTER a
--   booking exists does not retroactively violate the obligation — the
--   notification is captured at booking time (BR-45, Q-05), so no trigger is
--   placed on maintenance_records for this rule.
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_bookings_br46_advisory_acknowledgement
ON bookings
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(space_code)
            OR UPDATE(requested_start_time)
            OR UPDATE(requested_end_time)
            OR UPDATE(status)
            OR UPDATE(advisory_acknowledged))
        RETURN;

    IF EXISTS
    (
        SELECT 1
          FROM inserted i
          INNER JOIN maintenance_records m
                  ON m.space_code = i.space_code
         WHERE m.impact_level   = N'advisory'
           AND m.status         IN (N'reported', N'in_progress')   -- open record
           -- Period overlap with the requested range
           AND i.requested_end_time > m.start_time
           AND (m.completion_time IS NULL
                OR i.requested_start_time < m.completion_time)
           -- Acknowledgement missing or explicitly false
           AND (i.advisory_acknowledged IS NULL OR i.advisory_acknowledged = 0)
           AND
           (
               NOT EXISTS (SELECT 1 FROM deleted d WHERE d.booking_id = i.booking_id)
               OR UPDATE(space_code)
               OR UPDATE(requested_start_time)
               OR UPDATE(requested_end_time)
               OR i.status IN (N'pending', N'approved')
               OR UPDATE(advisory_acknowledged)
           )
    )
    BEGIN
        RAISERROR(N'BR-46 violation: an advisory maintenance record overlaps the booking period. The requester acknowledgement advisory_acknowledged = 1) is required.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- ----------------------------------------------------------------------------
-- 5.3 BR-47: The impact level of an OPEN maintenance record may be escalated
--            (advisory -> out_of_service) or downgraded, but the level of a
--            COMPLETED record is fixed at its last recorded value.
--            (RC-04; assumption A-04 / ULD-04)
-- ----------------------------------------------------------------------------
-- Table   : maintenance_records  (UPDATE)
-- Rationale: the violating operation is changing impact_level after (or
--   together with) completion. Level changes while the record is open remain
--   permitted; the allowed values are already restricted by
--   ck_maintenance_records_impact_level (BR-42). The single consistent
--   current value under concurrent decisions (CC-05) is the responsibility of
--   outputs/12-concurrency-implementation-G7.sql (usp_escalate_ / usp_down-
--   grade_maintenance_impact), not of this trigger (BC5).
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_maintenance_records_br47_impact_level_lifecycle
ON maintenance_records
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(impact_level) OR UPDATE(status))
        RETURN;

    IF EXISTS
    (
        SELECT 1
          FROM inserted i
          INNER JOIN deleted d
                  ON d.maintenance_id = i.maintenance_id
         WHERE i.impact_level <> d.impact_level
           -- completed before this statement, or completed BY this statement
           AND (i.status = N'completed' OR d.status = N'completed')
    )
    BEGIN
        RAISERROR(N'BR-47 violation: the impact level of a completed maintenance record cannot be changed. Escalation and downgrade are only allowed while the record is open.',
                  16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- ============================================================================
-- 6. UNCHANGED OBJECTS AND REMOVED RULES
-- ----------------------------------------------------------------------------
-- Objects intentionally NOT touched by this migration:
--
-- * All 11 foreign keys, 8 primary keys, and 3 unique constraints from
--   Phase 1 are retained unchanged (Section 3.5 of the updated logical
--   design).
-- * bookings / maintenance_records / spaces status CHECK constraints are
--   unchanged (no new statuses were introduced).
--
-- Rules removed or superseded, and why no DDL cleanup is needed:
--
-- * BR-19 (no overlapping open maintenance records per space) — REMOVED by
--   RC-03 (BR-43 now permits several simultaneously active records). Phase 1
--   never implemented BR-19 as DDL (BR-NI-07, application-layer only), so
--   there is no constraint or trigger to drop.
-- * BR-32 / BR-33 (open maintenance blocks booking) — SUPERSEDED by RC-01 /
--   RC-02 with BR-44/BR-45. Phase 1 never implemented them as DDL (BR-NI-08/
--   BR-NI-09), so no schema object is removed; the new semantics are enforced
--   by trg_bookings_br44_no_overlap_out_of_service.
--
-- Rules intentionally deferred to other stages (no schema object here):
--
-- * BR-14 / BR-50 (no overlapping approved bookings, incl. concurrent
--   operations) — concurrency invariant; enforced by transactions, isolation
--   levels and locking in outputs/12-concurrency-implementation-G7.sql.
-- * BR-48 (identify approved bookings affected by escalation) — derived
--   query, no storage change (A-05); implemented in the escalation procedure
--   of the concurrency stage.
-- * BR-49 (instant booking for selected space types) — process rule over
--   existing relations (A-02, Q-01); no schema change.
-- * BR-45 (notification obligation) — business/process-level obligation
--   (A-06); only its data-side counterpart BR-46 is schema-enforceable and
--   is implemented above.
-- ============================================================================

-- ============================================================================
-- 7. MIGRATION ASSUMPTIONS (Rule M2 / M5)
-- ----------------------------------------------------------------------------
-- | ID    | Assumption | Justification |
-- |-------|-----------|---------------|
-- | A-M01 | Existing OPEN maintenance records (status reported / in_progress) are backfilled with impact_level = out_of_service. | Phase 1 BR-33 blocked booking whenever open maintenance existed, i.e. the space was treated as unusable while the record was open — exactly the out_of_service semantics of RC-01/BR-44. |
-- | A-M02 | Existing COMPLETED maintenance records are backfilled with impact_level = advisory. | Phase 1 only open records affected booking (BR-33); completed records had no booking impact, so the least-severe level is inferred. Value is historical only. |
-- | A-M03 | Existing bookings keep advisory_acknowledged = NULL. | Phase 1 (baseline requirements) had no advisory notification obligation (RC-02 is new); NULL correctly means "no advisory requirement at booking time" (BR-45). |
-- | A-M04 | No DEFAULT is applied to impact_level; future INSERTs must supply it explicitly. | BR-42 requires an explicit level; a default value would be arbitrary (Rule M2). The Phase 2 recording operations (outputs/12-concurrency-implementation-G7.sql) already provide it. |
-- | A-M05 | advisory_acknowledged = 0 is rejected by a CHECK constraint. | The column exists solely to record the acknowledgement; a false value records nothing and contradicts BR-46. |
-- | A-M06 | impact_level has no upper bound on simultaneously active records per space (Q-06). | BR-43 permits any number; no schema restriction is added. |
-- ============================================================================

-- ============================================================================
-- 8. TRACEABILITY MATRIX
-- ----------------------------------------------------------------------------
-- | Schema Change        | Requirement Change | Business Rule | Design Ref |
-- |----------------------|--------------------|---------------|------------|
-- | S1 bookings.advisory_acknowledged     | RC-02 | BR-46 | C-02, 09 §3.3 |
-- | S2 maintenance_records.impact_level   | RC-01 | BR-42 | C-01, 09 §3.3 |
-- | S3 ck_maintenance_records_impact_level| RC-01 | BR-42 | 09 §3.7 BR-42 |
-- | S4 ck_bookings_advisory_acknowledged  | RC-02 | BR-46 | 09 §3.3/§3.7 |
-- | S5 trg_bookings_br44_...              | RC-01 | BR-44 | 09 §3.7 BR-44 |
-- | S6 trg_bookings_br46_...              | RC-02 | BR-45, BR-46 | 09 §3.7 BR-45/46 |
-- | S7 trg_maintenance_records_br47_...   | RC-04 | BR-47, ULD-04 | 09 §3.7 BR-47 |
-- | No object for BR-19 removal           | RC-03 | BR-19 removed, BR-43 | 09 §3.7 BR-19 |
-- ============================================================================

-- ============================================================================
-- 9. VALIDATION CHECKLIST (completed at authoring time)
-- ----------------------------------------------------------------------------
-- [X] Every schema modification is supported by the updated logical design.
-- [X] No obsolete objects remain that conflict with the updated design
--     (BR-19/BR-32/BR-33 were never DDL; nothing to drop).
-- [X] Every DDL statement is idempotent (COL_LENGTH / sys.check_constraints
--     guards; CREATE OR ALTER TRIGGER).
-- [X] Existing data is preserved; backfilled values are semantically inferred
--     (A-M01, A-M02) and documented.
-- [X] Dependency order: columns (nullable) -> backfill -> NOT NULL ->
--     CHECK -> triggers.
-- [X] Naming follows the Phase 1 conventions (ck_<table>_<column>,
--     trg_<table>_<br>_<purpose>).
-- [X] Only schema-level constraints are implemented; concurrency control is
--     left to outputs/12-concurrency-implementation-G7.sql.
-- [X] Every trigger rejects violations with an identified error (BR-xx) and
--     rolls back, leaving the transaction consistent (BC4).
-- ============================================================================

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
