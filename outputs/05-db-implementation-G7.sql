-- ============================================================================
-- Database Implementation Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Description : Physical database implementation derived from logical design
-- Artifact    : outputs/05-db-implementation-G7.sql
-- Prerequisite: outputs/03-logical-design-G7.md
-- Notes       : DDL only. No seed data, no indexes, no views, no triggers.
-- ============================================================================

-- ============================================================================
-- 1. HEADER BLOCK — Database Creation and Context
-- ============================================================================

USE [master];
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CS486_Booking_System')
BEGIN
    ALTER DATABASE [CS486_Booking_System] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [CS486_Booking_System];
END
GO

CREATE DATABASE [CS486_Booking_System];
GO

USE [CS486_Booking_System];
GO

-- ============================================================================
-- 2. CLEANUP SCHEMA BLOCK — Drop tables in reverse dependency order
--    (space_facilities -> maintenance_records -> sessions -> approvals ->
--     bookings -> facilities -> spaces -> users)
-- ============================================================================

IF OBJECT_ID(N'space_facilities', N'U') IS NOT NULL DROP TABLE space_facilities;
IF OBJECT_ID(N'maintenance_records', N'U') IS NOT NULL DROP TABLE maintenance_records;
IF OBJECT_ID(N'sessions', N'U') IS NOT NULL DROP TABLE sessions;
IF OBJECT_ID(N'approvals', N'U') IS NOT NULL DROP TABLE approvals;
IF OBJECT_ID(N'bookings', N'U') IS NOT NULL DROP TABLE bookings;
IF OBJECT_ID(N'facilities', N'U') IS NOT NULL DROP TABLE facilities;
IF OBJECT_ID(N'spaces', N'U') IS NOT NULL DROP TABLE spaces;
IF OBJECT_ID(N'users', N'U') IS NOT NULL DROP TABLE users;
GO

-- ============================================================================
-- 3. TABLE CREATION BLOCK — Dependency-ordered CREATE TABLE statements
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: users (independent — no foreign key dependencies)
-- External ID: user_id (university user ID, VARCHAR per Rule T4)
-- ----------------------------------------------------------------------------
CREATE TABLE users
(
    user_id          VARCHAR(50)   NOT NULL,
    first_name       NVARCHAR(100) NOT NULL,
    last_name        NVARCHAR(100) NOT NULL,
    email            VARCHAR(255)  NOT NULL,
    phone_number     VARCHAR(20)   NULL,
    role             VARCHAR(30)   NOT NULL,
    department       NVARCHAR(100) NULL,
    account_status   VARCHAR(20)   NOT NULL DEFAULT N'active',

    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT ck_users_role CHECK (role IN (
        N'student', N'lecturer', N'teaching_assistant',
        N'facility_staff', N'department_administrator', N'facility_manager'
    )),
    CONSTRAINT ck_users_account_status CHECK (account_status IN (N'active', N'suspended'))
);
GO

-- ----------------------------------------------------------------------------
-- Table: spaces (independent — no foreign key dependencies)
-- External ID: space_code (space code, VARCHAR per Rule T4)
-- ----------------------------------------------------------------------------
CREATE TABLE spaces
(
    space_code     VARCHAR(20)   NOT NULL,
    space_name     NVARCHAR(200) NOT NULL,
    space_type     VARCHAR(30)   NOT NULL,
    building       NVARCHAR(100) NOT NULL,
    floor          NVARCHAR(10)  NOT NULL,
    room_number    VARCHAR(50)   NOT NULL,
    capacity       INT           NOT NULL,
    status         VARCHAR(30)   NOT NULL DEFAULT N'available',
    usage_policy   NVARCHAR(1000) NULL,

    CONSTRAINT pk_spaces PRIMARY KEY (space_code),
    CONSTRAINT uq_spaces_building_floor_room UNIQUE (building, floor, room_number),
    CONSTRAINT ck_spaces_capacity CHECK (capacity > 0),
    CONSTRAINT ck_spaces_space_type CHECK (space_type IN (
        N'auditorium', N'classroom', N'computer_laboratory',
        N'project_laboratory', N'meeting_room', N'student_workspace'
    )),
    CONSTRAINT ck_spaces_status CHECK (status IN (
        N'available', N'in_use', N'under_maintenance',
        N'temporarily_closed', N'retired'
    ))
);
GO

-- ----------------------------------------------------------------------------
-- Table: facilities (independent — no foreign key dependencies)
-- Internal ID: facility_id (INT IDENTITY per Rule T4)
-- ----------------------------------------------------------------------------
CREATE TABLE facilities
(
    facility_id    INT IDENTITY(1,1) NOT NULL,
    facility_name  NVARCHAR(100)     NOT NULL,
    description    NVARCHAR(500)     NULL,

    CONSTRAINT pk_facilities PRIMARY KEY (facility_id),
    CONSTRAINT uq_facilities_facility_name UNIQUE (facility_name)
);
GO

-- ----------------------------------------------------------------------------
-- Table: bookings (depends on: users, spaces)
-- Internal ID: booking_id (INT IDENTITY per Rule T4)
-- ----------------------------------------------------------------------------
CREATE TABLE bookings
(
    booking_id             INT IDENTITY(1,1) NOT NULL,
    requester_id           VARCHAR(50)       NOT NULL,
    space_code             VARCHAR(20)       NOT NULL,
    requested_start_time   DATETIME2         NOT NULL,
    requested_end_time     DATETIME2         NOT NULL,
    purpose                VARCHAR(30)       NOT NULL,
    expected_participants  INT               NOT NULL,
    status                 VARCHAR(20)       NOT NULL DEFAULT N'pending',

    CONSTRAINT pk_bookings PRIMARY KEY (booking_id),
    CONSTRAINT fk_bookings_users FOREIGN KEY (requester_id)
        REFERENCES users (user_id) ON DELETE NO ACTION,
    CONSTRAINT fk_bookings_spaces FOREIGN KEY (space_code)
        REFERENCES spaces (space_code) ON DELETE NO ACTION,
    CONSTRAINT ck_bookings_purpose CHECK (purpose IN (
        N'lecture', N'examination', N'seminar', N'workshop',
        N'meeting', N'student_activity', N'administrative_event'
    )),
    CONSTRAINT ck_bookings_status CHECK (status IN (
        N'pending', N'approved', N'rejected', N'cancelled',
        N'checked_in', N'completed', N'no_show'
    )),
    CONSTRAINT ck_bookings_expected_participants CHECK (expected_participants > 0),
    CONSTRAINT ck_bookings_time_range CHECK (requested_start_time < requested_end_time)
);
GO

-- ----------------------------------------------------------------------------
-- Table: approvals (strong entity, depends on: bookings, users)
-- Internal ID: approval_id (INT IDENTITY per Rule T4)
-- 1:1 reviews (Approval -> Booking): UNIQUE on booking_id (LD-04, Rule 3)
-- ----------------------------------------------------------------------------
CREATE TABLE approvals
(
    approval_id      INT IDENTITY(1,1) NOT NULL,
    booking_id       INT               NOT NULL,
    approver_id      VARCHAR(50)       NOT NULL,
    decision         VARCHAR(20)       NOT NULL,
    decision_time    DATETIME2         NOT NULL,
    decision_note    NVARCHAR(500)     NULL,
    rejection_reason NVARCHAR(500)     NULL,

    CONSTRAINT pk_approvals PRIMARY KEY (approval_id),
    CONSTRAINT uq_approvals_booking_id UNIQUE (booking_id),
    CONSTRAINT fk_approvals_bookings FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id) ON DELETE NO ACTION,
    CONSTRAINT fk_approvals_users FOREIGN KEY (approver_id)
        REFERENCES users (user_id) ON DELETE NO ACTION,
    CONSTRAINT ck_approvals_decision CHECK (decision IN (N'approved', N'rejected')),
    CONSTRAINT ck_approvals_rejection_reason CHECK (
        decision <> N'rejected'
        OR (rejection_reason IS NOT NULL AND rejection_reason <> N'')
    )
);
GO

-- ----------------------------------------------------------------------------
-- Table: sessions (strong entity, depends on: bookings, users)
-- Internal ID: session_id (INT IDENTITY per Rule T4)
-- 1:1 tracks (Session -> Booking): UNIQUE on booking_id (LD-04, Rule 3)
-- actual_start_time/actual_end_time are conditionally nullable per BR-30/BR-31
-- ----------------------------------------------------------------------------
CREATE TABLE sessions
(
    session_id        INT IDENTITY(1,1) NOT NULL,
    booking_id        INT               NOT NULL,
    conductor_id      VARCHAR(50)       NOT NULL,
    actual_start_time DATETIME2         NULL,
    actual_end_time   DATETIME2         NULL,
    initial_condition NVARCHAR(500)     NULL,
    final_condition   NVARCHAR(500)     NULL,
    usage_notes       NVARCHAR(1000)    NULL,

    CONSTRAINT pk_sessions PRIMARY KEY (session_id),
    CONSTRAINT uq_sessions_booking_id UNIQUE (booking_id),
    CONSTRAINT fk_sessions_bookings FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id) ON DELETE NO ACTION,
    CONSTRAINT fk_sessions_users FOREIGN KEY (conductor_id)
        REFERENCES users (user_id) ON DELETE NO ACTION,
    CONSTRAINT ck_sessions_time_range CHECK (
        actual_start_time IS NULL
        OR actual_end_time IS NULL
        OR actual_end_time > actual_start_time
    )
);
GO

-- ----------------------------------------------------------------------------
-- Table: maintenance_records (depends on: users, spaces)
-- Internal ID: maintenance_id (INT IDENTITY per Rule T4)
-- completion_time/result_note are conditionally nullable per BR-34
-- ----------------------------------------------------------------------------
CREATE TABLE maintenance_records
(
    maintenance_id      INT IDENTITY(1,1) NOT NULL,
    reporter_id         VARCHAR(50)       NOT NULL,
    space_code          VARCHAR(20)       NOT NULL,
    assigned_staff_id   VARCHAR(50)       NOT NULL,
    problem_description NVARCHAR(1000)    NOT NULL,
    start_time          DATETIME2         NOT NULL,
    completion_time     DATETIME2         NULL,
    status              VARCHAR(20)       NOT NULL DEFAULT N'reported',
    result_note         NVARCHAR(1000)    NULL,

    CONSTRAINT pk_maintenance_records PRIMARY KEY (maintenance_id),
    CONSTRAINT fk_maintenance_records_users_reporter FOREIGN KEY (reporter_id)
        REFERENCES users (user_id) ON DELETE NO ACTION,
    CONSTRAINT fk_maintenance_records_spaces FOREIGN KEY (space_code)
        REFERENCES spaces (space_code) ON DELETE NO ACTION,
    CONSTRAINT fk_maintenance_records_users_staff FOREIGN KEY (assigned_staff_id)
        REFERENCES users (user_id) ON DELETE NO ACTION,
    CONSTRAINT ck_maintenance_records_status CHECK (status IN (
        N'reported', N'in_progress', N'completed'
    )),
    CONSTRAINT ck_maintenance_records_time_range CHECK (
        completion_time IS NULL OR completion_time > start_time
    )
);
GO

-- ----------------------------------------------------------------------------
-- Table: space_facilities (associative relation for M:N equipped_with,
--         depends on: spaces, facilities)
-- Composite PK (space_code, facility_id) per Rule 5 / LD-03
-- ----------------------------------------------------------------------------
CREATE TABLE space_facilities
(
    space_code   VARCHAR(20) NOT NULL,
    facility_id  INT         NOT NULL,
    quantity     INT         NOT NULL,

    CONSTRAINT pk_space_facilities PRIMARY KEY (space_code, facility_id),
    CONSTRAINT fk_space_facilities_spaces FOREIGN KEY (space_code)
        REFERENCES spaces (space_code) ON DELETE NO ACTION,
    CONSTRAINT fk_space_facilities_facilities FOREIGN KEY (facility_id)
        REFERENCES facilities (facility_id) ON DELETE NO ACTION,
    CONSTRAINT ck_space_facilities_quantity CHECK (quantity > 0)
);
GO

-- ============================================================================
-- 4. SEED DATA BLOCK — Placeholder
-- ----------------------------------------------------------------------------
-- Seed data will be generated in a later stage (outputs/06-sample-data.sql).
-- This skill generates DDL only; no DML is included per stage scope.
-- ============================================================================

-- ============================================================================
-- 5. BUSINESS RULES DOCUMENTATION
-- ----------------------------------------------------------------------------
-- Business rules from the logical design that cannot be enforced via DDL
-- constraints, and the reason they are enforced elsewhere.
-- ============================================================================

-- BR-NI-01: Booking status lifecycle
--   Booking.status must follow pending -> approved/rejected -> checked_in ->
--   completed/no_show/cancelled. Valid transitions depend on the current
--   state, which a static CHECK constraint cannot express.
--   Reason: Enforced at the application layer or via a DML trigger.

-- BR-NI-02: Only pending bookings can be approved (BR-28)
--   An approved booking requires an associated approval record with
--   decision = approved. Cross-table validation (Approval -> Booking.status).
--   Reason: Not expressible as a scalar CHECK constraint. Enforced at the
--   application layer or via a trigger.

-- BR-NI-03: Only approved bookings can have sessions (BR-13)
--   A session may only exist for a booking with status = approved.
--   Cross-table validation (Session -> Booking.status).
--   Reason: Not expressible as a scalar CHECK constraint. Enforced at the
--   application layer or via a trigger.

-- BR-NI-04: Rejected booking requires rejection reason (BR-29)
--   The booking-side linkage (a rejected booking must be linked to a
--   rejected approval with a reason) spans Booking and Approval.
--   Reason: The approval row's rejection_reason requirement is enforced by
--   ck_approvals_rejection_reason; the booking-side check is enforced at the
--   application layer.

-- BR-NI-05: Expected participants must not exceed space capacity (BR-40)
--   bookings.expected_participants <= spaces.capacity for the referenced
--   space_code.
--   Reason: Cross-table validation. Enforced at the application layer
--   or via a trigger.

-- BR-NI-06: No overlapping approved bookings for the same space (BR-14)
--   A new booking's [requested_start_time, requested_end_time) must not
--   overlap any existing approved booking for the same space.
--   Reason: Requires range-overlap checks against existing rows; not
--   expressible as a scalar CHECK constraint. Enforced at the application
--   layer or via a trigger.

-- BR-NI-07: No overlapping active maintenance for the same space (BR-19)
--   A space should not have overlapping open (reported/in_progress)
--   maintenance records.
--   Reason: Temporal overlap check on existing rows. Enforced at the
--   application layer or via a trigger.

-- BR-NI-08: Unbookable space statuses (BR-32)
--   A space with status under_maintenance, temporarily_closed, or retired
--   cannot be booked.
--   Reason: Cross-table validation (Booking -> Space.status). Enforced at
--   the application layer or via a trigger.

-- BR-NI-09: Open maintenance prevents booking (BR-33)
--   A space with a reported/in_progress maintenance record cannot be booked.
--   Reason: Cross-table validation. Enforced at the application layer
--   or via a trigger.

-- BR-NI-10: Approval decision before booking start (BR-37)
--   Approval.decision_time must be before Booking.requested_start_time.
--   Reason: Cross-table temporal validation. Enforced at the application
--   layer or via a trigger.

-- BR-NI-11: Approver must be different from requester
--   approvals.approver_id must not equal the referenced booking's
--   requester_id.
--   Reason: Cross-table comparison. Enforced at the application layer
--   or via a trigger.

-- BR-NI-12: Role-based access control (BR-22, BR-23)
--   Only facility staff / facility managers may be assigned as
--   maintenance assigned_staff_id or as session conductor_id; only
--   department administrators / facility managers may approve bookings.
--   Reason: Role-based authorization requires subqueries across users.
--   Enforced at the application layer or via a trigger.

-- BR-NI-13: Requests must be submitted for the future (BR-36)
--   Booking.requested_start_time must be in the future at submission.
--   Reason: Time-dependent validation not expressible as a static CHECK.
--   Enforced at the application layer.

-- ============================================================================
-- Enforcement notes for rules implemented as DDL constraints:
--   BR-01 (email unique)            -> uq_users_email
--   Candidate key (building, floor, room_number) -> uq_spaces_building_floor_room
--   Facility name unique            -> uq_facilities_facility_name
--   BR-09/1:1 reviews               -> uq_approvals_booking_id
--   BR-10/1:1 tracks                -> uq_sessions_booking_id
--   BR-29/BR-41 (rejection reason)  -> ck_approvals_rejection_reason
--   BR-35 (end > start)             -> ck_bookings_time_range
--   BR-38 (session time ordering)   -> ck_sessions_time_range
--   BR-39 (completion > start)      -> ck_maintenance_records_time_range
--   BR-40 (participants >= 1)       -> ck_bookings_expected_participants
--   Capacity/quantity >= 1          -> ck_spaces_capacity, ck_space_facilities_quantity
-- ============================================================================

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
