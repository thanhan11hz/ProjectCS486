-- ============================================================================
-- Database Implementation Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Description : Physical database implementation derived from logical design
-- Artifact    : outputs/05-db-implementation-G7.sql
-- Prerequisite: outputs/03-logical-design-G7.md
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
-- ----------------------------------------------------------------------------
CREATE TABLE users
(
    user_id          VARCHAR(50)    NOT NULL,
    first_name       NVARCHAR(100)  NOT NULL,
    last_name        NVARCHAR(100)  NOT NULL,
    email            VARCHAR(255)   NOT NULL,
    phone_number     VARCHAR(20)    NULL,
    role             VARCHAR(30)    NOT NULL,
    department       NVARCHAR(100)  NOT NULL,
    account_status   VARCHAR(20)    NOT NULL DEFAULT N'active',

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
-- ----------------------------------------------------------------------------
CREATE TABLE spaces
(
    space_code     VARCHAR(20)    NOT NULL,
    space_name     NVARCHAR(200)  NOT NULL,
    space_type     VARCHAR(30)    NOT NULL,
    building       NVARCHAR(100)  NOT NULL,
    floor          NVARCHAR(20)   NOT NULL,
    room_number    VARCHAR(20)    NOT NULL,
    capacity       INT            NOT NULL,
    status         VARCHAR(30)    NOT NULL DEFAULT N'available',
    usage_policy   NVARCHAR(MAX)  NULL,

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
-- ----------------------------------------------------------------------------
CREATE TABLE facilities
(
    facility_id    INT IDENTITY(1,1) NOT NULL,
    facility_name  NVARCHAR(200)     NOT NULL,
    description    NVARCHAR(MAX)     NULL,

    CONSTRAINT pk_facilities PRIMARY KEY (facility_id),
    CONSTRAINT uq_facilities_facility_name UNIQUE (facility_name)
);
GO

-- ----------------------------------------------------------------------------
-- Table: bookings (depends on: users, spaces)
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
-- Table: approvals (weak entity, depends on: bookings, users)
-- ----------------------------------------------------------------------------
CREATE TABLE approvals
(
    booking_id       INT            NOT NULL,
    approval_id      INT IDENTITY(1,1) NOT NULL,
    approver_id      VARCHAR(50)    NOT NULL,
    decision         VARCHAR(20)    NOT NULL,
    decision_time    DATETIME2      NOT NULL,
    decision_note    NVARCHAR(MAX)  NULL,
    rejection_reason NVARCHAR(MAX)  NULL,

    CONSTRAINT pk_approvals PRIMARY KEY (booking_id, approval_id),
    CONSTRAINT fk_approvals_bookings FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_approvals_users FOREIGN KEY (approver_id)
        REFERENCES users (user_id) ON DELETE NO ACTION,
    CONSTRAINT ck_approvals_decision CHECK (decision IN (N'approved', N'rejected')),
    CONSTRAINT ck_approvals_rejection_reason CHECK (
        decision <> N'rejected' 
    )
);
GO

-- ----------------------------------------------------------------------------
-- Table: sessions (weak entity, depends on: bookings, users)
-- ----------------------------------------------------------------------------
CREATE TABLE sessions
(
    booking_id        INT            NOT NULL,
    session_id        INT IDENTITY(1,1) NOT NULL,
    conductor_id      VARCHAR(50)    NOT NULL,
    actual_start_time DATETIME2      NOT NULL,
    actual_end_time   DATETIME2      NULL,
    initial_condition NVARCHAR(MAX)  NOT NULL,
    final_condition   NVARCHAR(MAX)  NULL,
    usage_notes       NVARCHAR(MAX)  NULL,

    CONSTRAINT pk_sessions PRIMARY KEY (booking_id, session_id),
    CONSTRAINT fk_sessions_bookings FOREIGN KEY (booking_id)
        REFERENCES bookings (booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_sessions_users FOREIGN KEY (conductor_id)
        REFERENCES users (user_id) ON DELETE NO ACTION,
    CONSTRAINT ck_sessions_time_range CHECK (
        actual_end_time IS NULL OR actual_end_time > actual_start_time
    )
);
GO

-- ----------------------------------------------------------------------------
-- Table: maintenance_records (depends on: users, spaces)
-- ----------------------------------------------------------------------------
CREATE TABLE maintenance_records
(
    maintenance_id      INT IDENTITY(1,1) NOT NULL,
    reporter_id         VARCHAR(50)       NOT NULL,
    space_code          VARCHAR(20)       NOT NULL,
    assigned_staff_id   VARCHAR(50)       NOT NULL,
    problem_description NVARCHAR(MAX)     NOT NULL,
    start_time          DATETIME2         NOT NULL,
    completion_time     DATETIME2         NULL,
    status              VARCHAR(20)       NOT NULL DEFAULT N'reported',
    result_note         NVARCHAR(MAX)     NULL,

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
-- Table: space_facilities (associative M:N, depends on: spaces, facilities)
-- ----------------------------------------------------------------------------
CREATE TABLE space_facilities
(
    space_code   VARCHAR(20) NOT NULL,
    facility_id  INT         NOT NULL,
    quantity     INT         NOT NULL,

    CONSTRAINT pk_space_facilities PRIMARY KEY (space_code, facility_id),
    CONSTRAINT fk_space_facilities_spaces FOREIGN KEY (space_code)
        REFERENCES spaces (space_code) ON DELETE CASCADE,
    CONSTRAINT fk_space_facilities_facilities FOREIGN KEY (facility_id)
        REFERENCES facilities (facility_id) ON DELETE CASCADE,
    CONSTRAINT ck_space_facilities_quantity CHECK (quantity > 0)
);
GO

-- ============================================================================
-- 4. SEED DATA BLOCK — Placeholder
-- ----------------------------------------------------------------------------
-- Seed data will be generated in a later stage (outputs/06-sample-data.sql).
-- This section is reserved for comprehensive testing insert queries.
-- ============================================================================

-- ============================================================================
-- 5. BUSINESS RULES DOCUMENTATION
-- ----------------------------------------------------------------------------
-- Business rules from the logical design that cannot be enforced via DDL
-- constraints and must be enforced at the application or trigger level.
-- ============================================================================

-- BR-NI-01: Booking status transitions
--   A booking's status must follow a defined lifecycle:
--   pending -> approved/rejected -> checked_in -> completed/no_show/cancelled.
--   Reason: Status transitions require knowledge of the current state and
--   cannot be enforced with a static CHECK constraint. Enforced at the
--   application layer or via a DML trigger.

-- BR-NI-02: Only pending bookings can be approved
--   The approvals table references a booking; the referenced booking must
--   have status = 'pending' at the time of approval insertion.
--   Reason: Cross-table validation cannot be expressed in a CHECK
--   constraint. Enforced at the application layer or via a trigger.

-- BR-NI-03: Only approved bookings can have sessions
--   A session (actual usage) should only be created for bookings whose
--   status is 'approved'.
--   Reason: Cross-table validation. Enforced at the application layer
--   or via a trigger.

-- BR-NI-04: Approver must be different from requester
--   The approver_id in approvals must not equal the requester_id in the
--   referenced booking.
--   Reason: Cross-table comparison. Enforced at the application layer
--   or via a trigger.

-- BR-NI-05: Expected participants must not exceed space capacity
--   bookings.expected_participants <= spaces.capacity for the referenced
--   space_code.
--   Reason: Cross-table validation. Enforced at the application layer
--   or via a trigger.

-- BR-NI-06: Booking time range must not overlap existing bookings
--   A new booking's [requested_start_time, requested_end_time) must not
--   overlap any existing approved booking for the same space.
--   Reason: Requires querying existing rows; not expressible as a scalar
--   CHECK constraint. Enforced at the application layer or via a trigger.

-- BR-NI-07: Role-based access control
--   Only users with appropriate roles can perform certain actions
--   (e.g., only facility_manager can approve bookings, only students can
--   book student_workspace, only facility_staff can be assigned to
--   maintenance records).
--   Reason: Role-based authorization is inherently application-level.
--   Enforced at the application layer.

-- BR-NI-08: Assigned maintenance staff must hold facility role
--   The assigned_staff_id in maintenance_records must reference a user
--   whose role is 'facility_staff' or 'facility_manager'.
--   Reason: Cross-table validation requiring subquery. Enforced at the
--   application layer or via a trigger.

-- BR-NI-09: A booking can have at most one approval
--   The 1:1 identifying relationship (reviews) between Booking and
--   Approval is structurally enforced by the composite PK
--   (booking_id, approval_id). However, nothing prevents multiple
--   approval rows for the same booking_id. A UNIQUE constraint on
--   booking_id alone is not added because the weak-entity mapping
--   requires the composite PK per Rule 2. Enforced at the application
--   layer or via a trigger if strict 1:1 is required.

-- BR-NI-10: A booking can have at most one session
--   Same reasoning as BR-NI-09 for the tracks relationship.
--   Enforced at the application layer or via a trigger.

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
