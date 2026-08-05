-- ============================================================================
-- Schema Migration Script (Initial Version)
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+
-- Description : Basic, naive schema migration from Phase 1 to Phase 2.
--               Adds new columns required by Phase 2 business requirements.
--               WARNING: This script is intentionally unpolished. It does NOT
--               include idempotency checks (IF NOT EXISTS), DEFAULT constraints
--               to handle NOT NULL on existing data, or removal of obsolete
--               Phase 1 constraints. It will fail if run more than once or if
--               the tables already contain rows when adding impact_level (NOT NULL).
-- Artifact    : initial-result/10-schema-migration-G7.sql
-- Prerequisite: outputs/05-db-implementation-G7.sql
--               outputs/09-updated-erd-and-logical-design-G7.md
-- ============================================================================

USE [CS486_Booking_System];
GO

-- ============================================================================
-- 1. MODIFY maintenance_records TABLE
-- ----------------------------------------------------------------------------
-- Source: Phase 2 change C-01 (RC-01, RC-04)
-- Add impact_level column to record whether a maintenance event is
-- 'out_of_service' (space unusable, bookings blocked) or
-- 'advisory' (space usable, requester must be notified).
-- NOTE: Adding as NOT NULL without a DEFAULT. This will fail on a populated
-- table — an intentional limitation of this initial version.
-- ============================================================================

ALTER TABLE maintenance_records
    ADD impact_level VARCHAR(20) NOT NULL;
GO

ALTER TABLE maintenance_records
    ADD CONSTRAINT ck_maintenance_records_impact_level
    CHECK (impact_level IN ('out_of_service', 'advisory'));
GO

-- ============================================================================
-- 2. MODIFY bookings TABLE
-- ----------------------------------------------------------------------------
-- Source: Phase 2 change C-02 (RC-02)
-- Add advisory_acknowledged column to record whether the requester was
-- informed of all active advisory maintenance records at booking time.
-- The column is BIT and nullable (NULL means no advisory was active).
-- ============================================================================

ALTER TABLE bookings
    ADD advisory_acknowledged BIT NULL;
GO

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
