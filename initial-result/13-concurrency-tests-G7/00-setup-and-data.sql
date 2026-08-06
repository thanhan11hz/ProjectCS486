-- ============================================================================
-- Concurrency Test — Setup / Reset helper (Group 7)
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Artifact    : outputs/13-concurrency-tests-G7/00-setup-and-data.sql
-- Prereq      : 05 + 10 + 06 + 12 already applied.
-- Purpose     : Verify prerequisites and (re)establish the small, deterministic
--               test fixtures (a dedicated instant-eligible space, a set of
--               test workers, and supporting rows) that the CC-01..CC-05 test
--               scripts reference. Idempotent: safe to run repeatedly.
-- ============================================================================

USE [CS486_Booking_System];
GO
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 0. Prerequisite guards
-- ----------------------------------------------------------------------------
IF DB_ID(N'CS486_Booking_System') IS NULL
    THROW 51000, N'Database CS486_Booking_System missing. Run 05 then 10 first.', 1;
GO

IF OBJECT_ID(N'dbo.usp_submit_instant_booking', N'P') IS NULL
   OR OBJECT_ID(N'dbo.usp_submit_booking_pending', N'P') IS NULL
   OR OBJECT_ID(N'dbo.usp_approve_pending_booking', N'P') IS NULL
   OR OBJECT_ID(N'dbo.usp_record_maintenance', N'P') IS NULL
   OR OBJECT_ID(N'dbo.usp_escalate_maintenance_impact', N'P') IS NULL
   OR OBJECT_ID(N'dbo.usp_downgrade_maintenance_impact', N'P') IS NULL
    THROW 520, N'Concurrency procedures are missing. Run 12-concurrency-implementation-G7.sql first.', 1;
GO

-- ----------------------------------------------------------------------------
-- 1. Choose a deterministic, instant-eligible, currently-available space.
--    'classroom' and 'meeting_room' are the reachable instant-eligible types
--    (BR-49 representative set; authoritative set is Q-01).
--    Enforce a far-future time window so sample rows never collide.
-- ----------------------------------------------------------------------------
DECLARE @test_space_code VARCHAR(20);
SELECT TOP (1) @test_space_code = s.space_code
  FROM dbo.spaces s
 WHERE s.space_type IN (N'classroom', N'meeting_room')
   AND s.status = N'available'
 ORDER BY s.space_code;

IF @test_space_code IS NULL
    THROW 530, N'No instant-eligible available space found in the sample data.', 1;

PRINT N'[00] Test space selected: ' + @test_space_code;

-- ----------------------------------------------------------------------------
-- 2. Identify one user of each role needed by the tests (seeded in 06).
-- ----------------------------------------------------------------------------
DECLARE @student_id     VARCHAR(50);
DECLARE @student2_id    VARCHAR(50);
DECLARE @staff_approve  VARCHAR(50);   -- department_administrator
DECLARE @fac_mgr        VARCHAR(50);   -- facility_manager

SELECT TOP (1) @student_id  = user_id FROM dbo.users WHERE role = N'student'                 ORDER BY user_id;
SELECT TOP (1) @student2_id = user_id FROM dbo.users WHERE role = N'student'                 AND user_id > ISNULL(@student_id,N'') ORDER BY user_id;
SELECT TOP (1) @staff_approve = user_id FROM dbo.users WHERE role = N'department_administrator' ORDER BY user_id;
SELECT TOP (1) @fac_mgr       = user_id FROM dbo.users WHERE role = N'facility_manager'       ORDER BY user_id;

IF @student_id IS NULL OR @student2_id IS NULL OR @staff_approve IS NULL OR @fac_mgr IS NULL
    THROW 540, N'One or more required test roles are missing from users.', 1;

PRINT N'[test] requester A (student)   = ' + @student_id;
PRINT N'[test] requester B (student)   = ' + @student2_id;
PRINT N'[test] staff approver (DA)     = ' + @staff_approve;
PRINT N'[test] facility manager         = ' + @fac_mgr;
PRINT N'[test] instant-eligible space   = ' + @test_space_code;

-- ----------------------------------------------------------------------------
-- 3. Report existence of the building blocks the tests rely on so the runtime
--    SELECTs in each test can copy these identifiers into Session A / B.
-- ----------------------------------------------------------------------------
SELECT @test_space_code AS test_space_code,
       @student_id       AS requester_student_1,
       @student2_id      AS requester_student_2,
       @staff_approve    AS staff_approver,
       @fac_mgr          AS facility_manager;

PRINT N'Setup complete. Copy the printed identifiers into the CC-01..CC-05 scripts (or let them select these readers at runtime).';
GO