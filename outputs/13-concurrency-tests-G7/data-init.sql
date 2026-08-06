-- ============================================================================
-- Concurrency Tests -- Data Initialization (G7)
-- Artifact    : outputs/13-concurrency-tests-G7/data-init.sql
-- Prerequisite: Database CS486_Booking_System with the Phase 2 schema
--               (outputs/05-db-implementation-G7.sql then
--                outputs/10-schema-migration-G7.sql).
-- Purpose     : Seed the deterministic users and the test space referenced by
--               every concurrency scenario. Each session script is
--               self-contained with respect to the rows it mutates, but it
--               depends on the actors below existing because all foreign keys
--               (requester_id / approver_id / reporter_id / assigned_staff_id
--               / conductor_id) reference dbo.users and dbo.spaces.
--               This script is idempotent (IF NOT EXISTS guarded).
--
-- Actors created:
--   U-101, U-102 : instant-booking requesters            (CC-01)
--   U-201, U-202 : staff-approval requester / instant requester (CC-02)
--   U-301, U-303 : reporter / pending requester          (CC-03)
--   U-401, U-402 : pending requester / reporter          (CC-04)
--   U-501        : reporter                              (CC-05)
--   FM-301       : facility manager (approver + auto-approver) (CC-01/CC-02)
--   FM-302       : facility manager (CC-03 staff / escalation actor)
--   FM-403       : facility manager (CC-04 assigned staff)
--   FM-502, FM-503 : facility managers (CC-05 escalation / downgrade)
-- Space: X-100 (classroom, capacity 60) is the single space under test.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

-- ----------------------------------------------------------------------------
-- 1. TEST USERS
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-101')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-101', N'Alice', N'Chen', N'alice.chen@university.edu',
            N'+1-555-0001', N'student', N'Computer Science', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-102')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-102', N'Bob', N'Patel', N'bob.patel@university.edu',
            N'+1-555-0002', N'student', N'Computer Science', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-201')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-201', N'Carla', N'Meyer', N'carla.meyer@university.edu',
            N'+1-555-0003', N'student', N'Mathematics', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-202')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-202', N'Dan', N'Osei', N'dan.osei@university.edu',
            N'+1-555-0004', N'student', N'Mathematics', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-301')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-301', N'Erin', N'Khan', N'erin.khan@university.edu',
            N'+1-555-0005', N'lecturer', N'Physics', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-303')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-303', N'Frank', N'Lima', N'frank.lima@university.edu',
            N'+1-555-0006', N'lecturer', N'Physics', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-401')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-401', N'Grace', N'Nguyen', N'grace.nguyen@university.edu',
            N'+1-555-0007', N'student', N'Chemistry', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-402')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-402', N'Henry', N'Rossi', N'henry.rossi@university.edu',
            N'+1-555-0008', N'teaching_assistant', N'Chemistry', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'U-501')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'U-501', N'Ivy', N'Tan', N'ivy.tan@university.edu',
            N'+1-555-0009', N'lecturer', N'Biology', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'FM-301')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'FM-301', N'Jack', N'Roy', N'jack.roy@university.edu',
            N'+1-555-0010', N'facility_manager', N'Facilities Management', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'FM-302')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'FM-302', N'Kim', N'Zhang', N'kim.zhang@university.edu',
            N'+1-555-0011', N'facility_manager', N'Facilities Management', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'FM-403')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'FM-403', N'Leo', N'Wang', N'leo.wang@university.edu',
            N'+1-555-0012', N'facility_manager', N'Facilities Management', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'FM-502')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'FM-502', N'Mia', N'Sato', N'mia.sato@university.edu',
            N'+1-555-0013', N'facility_manager', N'Facilities Management', N'active');
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE user_id = N'FM-503')
    INSERT INTO dbo.users (user_id, first_name, last_name, email, phone_number,
                           role, department, account_status)
    VALUES (N'FM-503', N'Nina', N'Ali', N'nina.ali@university.edu',
            N'+1-555-0014', N'facility_manager', N'Facilities Management', N'active');
GO

-- ----------------------------------------------------------------------------
-- 2. TEST SPACE: X-100 (classroom, capacity 60)
--    Instant-booking eligible (classroom per BR-49 representative set).
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.spaces WHERE space_code = N'X-100')
    INSERT INTO dbo.spaces
        (space_code, space_name, space_type, building, floor, room_number,
         capacity, status, usage_policy)
    VALUES
        (N'X-100', N'Concurrency Test Auditorium 100', N'classroom', N'X',
         N'1', N'100', 60, N'available', N'Standard classroom instruction.');
GO

-- ----------------------------------------------------------------------------
-- 3. VERIFICATION (informational)
-- ----------------------------------------------------------------------------
SELECT N'users seeded (all referenced actors present)' AS check_,
       COUNT(*) AS cnt
  FROM dbo.users
 WHERE user_id IN
       (N'U-101', N'U-102', N'U-201', N'U-202', N'U-301',
        N'U-303', N'U-401', N'U-402', N'U-501', N'FM-301', N'FM-302',
        N'FM-403', N'FM-502', N'FM-503');

SELECT space_code, space_type, capacity, status
  FROM dbo.spaces
 WHERE space_code = N'X-100';
GO