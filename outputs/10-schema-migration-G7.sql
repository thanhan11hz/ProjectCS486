-- ============================================================================
-- Schema Migration Script (Final Version)
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+
-- Description : Production-grade, idempotent schema migration from Phase 1 to
--               Phase 2. Implements new columns and constraints required by
--               Phase 2 business requirements (RC-01, RC-02, RC-03, RC-04).
--               This script is safe to run multiple times (idempotent).
-- Artifact    : outputs/10-schema-migration-G7.sql
-- Prerequisite: outputs/05-db-implementation-G7.sql
--               outputs/09-updated-erd-and-logical-design-G7.md
--               outputs/08-req-change-analysis-G7.md
-- ============================================================================

USE [CS486_Booking_System];
GO

-- ============================================================================
-- 1. CLEANUP: DROP OBSOLETE PHASE 1 CONSTRAINTS
-- ----------------------------------------------------------------------------
-- Phase 1 documented that BR-19 (no overlapping active maintenance records)
-- and BR-33 (any active maintenance record blocks booking) were enforced at
-- the application/trigger level, not via named DDL CHECK constraints in the
-- physical schema (see outputs/05-db-implementation-G7.sql, sections BR-NI-07
-- and BR-NI-09).
--
-- Therefore, there are no named Phase 1 CHECK constraints to drop here.
--
-- RC-03 supersedes BR-19: a space may now have multiple simultaneously active
-- maintenance records with different impact levels (BR-43). The overlapping-
-- maintenance restriction is simply removed — no DDL action required.
--
-- RC-01 / RC-02 supersede BR-33: only out_of_service maintenance blocks
-- bookings; advisory maintenance allows bookings with acknowledgement. Again,
-- this was enforced at application level in Phase 1, so no DDL constraint
-- needs to be dropped. The new logic will be enforced via the new impact_level
-- column and application-layer checks.
-- ============================================================================

-- ============================================================================
-- 2. SCHEMA EVOLUTION: ADD NEW COLUMNS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 Add impact_level to maintenance_records
-- ----------------------------------------------------------------------------
-- Source    : Phase 2 change C-01 (RC-01, RC-04); Business Rules BR-42, BR-47
-- Semantics : Indicates the severity of the maintenance with respect to space
--             usability:
--               'out_of_service' — space unusable; overlapping bookings blocked
--               'advisory'       — space usable; requester must be notified
--             The level may be escalated or downgraded while the record is open
--             (BR-47). It is mandatory on every maintenance record (BR-42).
-- NOT NULL safety: Adding a NOT NULL column to a populated table requires a
--             temporary DEFAULT. We default existing records to 'advisory'
--             (the less restrictive value, per business assumption A-04).
--             The default constraint is dropped immediately after column
--             creation so future INSERTs are forced to supply the value.
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name       = N'impact_level'
      AND Object_ID  = OBJECT_ID(N'maintenance_records')
)
BEGIN
    -- Step 1: Add column with a temporary named DEFAULT to handle existing rows
    ALTER TABLE maintenance_records
        ADD impact_level VARCHAR(20) NOT NULL
            CONSTRAINT df_maintenance_records_impact_level DEFAULT N'advisory';

    -- Step 2: Drop the temporary default — future INSERTs must provide the value
    ALTER TABLE maintenance_records
        DROP CONSTRAINT df_maintenance_records_impact_level;
END
GO

-- ----------------------------------------------------------------------------
-- 2.2 Add advisory_acknowledged to bookings
-- ----------------------------------------------------------------------------
-- Source    : Phase 2 change C-02 (RC-02); Business Rules BR-45, BR-46
-- Semantics : Records that the requester was informed of all active advisory
--             maintenance records on the space at booking time and acknowledged
--             them. NULL when no advisory was active at booking time (BR-45).
--             Must be 1 (true) when advisories were active at booking time
--             (BR-46). Conditional nullability enforced at application layer.
-- BIT type  : SQL Server standard boolean representation (1 = true, 0 = false).
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE Name      = N'advisory_acknowledged'
      AND Object_ID = OBJECT_ID(N'bookings')
)
BEGIN
    ALTER TABLE bookings
        ADD advisory_acknowledged BIT NULL;
END
GO

-- ============================================================================
-- 3. DOMAIN ENFORCEMENT: ADD NEW CHECK CONSTRAINTS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 CHECK constraint on maintenance_records.impact_level
-- ----------------------------------------------------------------------------
-- Source    : BR-42 — Each maintenance record has an impact level:
--             out_of_service or advisory. Exhaustive (A-01).
-- Naming    : Follows Phase 1 convention: ck_<table_name>_<column_name>
-- ----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name            = N'ck_maintenance_records_impact_level'
      AND parent_object_id = OBJECT_ID(N'maintenance_records')
)
BEGIN
    ALTER TABLE maintenance_records
        ADD CONSTRAINT ck_maintenance_records_impact_level
            CHECK (impact_level IN (N'out_of_service', N'advisory'));
END
GO

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
-- Summary of changes applied:
--   maintenance_records : + impact_level   VARCHAR(20) NOT NULL
--                         + ck_maintenance_records_impact_level CHECK
--   bookings            : + advisory_acknowledged BIT NULL
--
-- No DDL changes required for RC-03 (BR-19 removal) or RC-05/RC-06/RC-07/RC-08
-- as those changes are enforced at the application or concurrency-control layer.
-- Refer to outputs/11-concurrency-design-G7.md for concurrency mechanisms.
-- ============================================================================
