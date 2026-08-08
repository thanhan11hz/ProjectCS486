-- ============================================================================
-- Large-Scale Data Generator
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Artifact    : outputs/14-data-generator-G7.sql
-- Prerequisite: outputs/05-db-implementation-G7.sql  (creates the database)
--               outputs/10-schema-migration-G7.sql    (adds advisory_acknow-
--               ledged, impact_level and the BR-44 / BR-46 / BR-47 triggers)
-- Alternative : outputs/06-sample-data-G7.sql seeds the same schema with a
--               small (3 000 booking) dataset; this script is the Phase 2
--               large-scale generator for performance and concurrency testing.
-- Description : Seeds at least 100 000 booking records spanning a minimum of
--               three academic years plus the current autumn semester, with
--               realistic usage distributions and operational scenarios
--               (maintenance, cancellations, no-shows, advisory
--               acknowledgements).
--
-- How to use (repeated execution in a test environment):
--   1. Run 05 (drops/recreates the database)  -> 10 (migration) -> 14 (this).
--   2. Re-running this script directly is blocked by a guard so the dataset
--      cannot be accidentally duplicated. Re-running the whole 05 -> 10 -> 14
--      sequence regenerates an identical dataset (deterministic generator).
--
-- Determinism
--   All pseudo-random values are derived from CHECKSUM(CONCAT(...)) so every
--   execution yields byte-identical data. No NEWID()/RAND() is used.
--
-- Trigger-safe generation order (critical for BR-44 / BR-46):
--   1. Reference data (users, spaces, facilities, space_facilities)
--   2. Completed maintenance records  (status completed  -> inert for the
--      BR-44 / BR-46 booking triggers)
--   3. Wave-1 bookings (blocks 08:00-20:00) -> advisory_acknowledged = NULL
--      (no open advisory existed at booking time; BR-45)
--   4. Open ADVISORY maintenance records (reported/in_progress, no completion)
--   5. Wave-2 bookings (block 20:00-22:00, last AY + autumn semester) with
--      advisory_acknowledged computed by the exact BR-46 trigger predicate
--   6. Approvals and sessions for both waves
--   7. Open OUT-OF-SERVICE maintenance records (inserted last: their periods
--      may overlap existing approved bookings — the RC-05 escalation scenario
--      where affected bookings are surfaced for staff contact)
--   8. Resolution pass: cancel pending/approved bookings overlapping open
--      out-of-service records (BR-44) and backfill advisory_acknowledged = 1
--      for every effective booking overlapping an open advisory record
--      (BR-46), leaving the dataset fully consistent
-- ============================================================================

SET NOCOUNT ON;
GO

USE [CS486_Booking_System];
GO

-- ============================================================================
-- 0. GUARD BLOCK — prevent accidental re-runs and wrong-prerequisite runs
-- ============================================================================

IF DB_ID(N'CS486_Booking_System') IS NULL
    THROW 51000, N'Database CS486_Booking_System does not exist. Execute outputs/05-db-implementation-G7.sql first.', 1;
GO

IF COL_LENGTH(N'bookings', N'advisory_acknowledged') IS NULL
   OR COL_LENGTH(N'maintenance_records', N'impact_level') IS NULL
    THROW 51001, N'Phase 2 columns are missing. Execute outputs/10-schema-migration-G7.sql first.', 1;
GO

IF (SELECT COUNT(*) FROM bookings) > 0
    THROW 51002, N'bookings already contains data. To regenerate the large-scale dataset re-run outputs/05-db-implementation-G7.sql (recreates the database), then outputs/10-schema-migration-G7.sql, then this script.', 1;
GO

-- ============================================================================
-- 1. USERS (1500 rows)
--    Deterministic, set-based. Departments restricted to CS domains.
--    Roles: student 62%, lecturer 13%, teaching_assistant 10%,
--           facility_staff 6%, department_administrator 5%, facility_manager 4%
--    Account status: active 92%, suspended 8%
--    user_id format follows the Phase 1 convention: 'U' + 5-digit sequence.
-- ============================================================================

WITH
first_name_pool AS (
    SELECT name FROM (VALUES
        (N'James'),(N'Mary'),(N'Robert'),(N'Patricia'),(N'John'),
        (N'Jennifer'),(N'Michael'),(N'Linda'),(N'David'),(N'Elizabeth'),
        (N'William'),(N'Barbara'),(N'Richard'),(N'Susan'),(N'Joseph'),
        (N'Jessica'),(N'Thomas'),(N'Sarah'),(N'Christopher'),(N'Karen'),
        (N'Daniel'),(N'Nancy'),(N'Matthew'),(N'Lisa'),(N'Anthony'),
        (N'Margaret'),(N'Mark'),(N'Betty'),(N'Donald'),(N'Sandra'),
        (N'Charles'),(N'Ashley'),(N'Steven'),(N'Dorothy'),(N'Andrew'),
        (N'Kimberly'),(N'Paul'),(N'Donna'),(N'Joshua'),(N'Carol'),
        (N'Kevin'),(N'Michelle'),(N'Brian'),(N'Amanda'),(N'Jason'),
        (N'Melissa'),(N'George'),(N'Deborah'),(N'Kenneth'),(N'Stephanie'),
        (N'Edward'),(N'Rebecca'),(N'Ronald'),(N'Sharon'),(N'Timothy'),
        (N'Laura'),(N'Angela'),(N'Emily'),(N'Jeffrey'),(N'Helen')
    ) AS fn(name)
),
last_name_pool AS (
    SELECT name FROM (VALUES
        (N'Smith'),(N'Johnson'),(N'Williams'),(N'Brown'),(N'Jones'),
        (N'Garcia'),(N'Miller'),(N'Davis'),(N'Rodriguez'),(N'Martinez'),
        (N'Hernandez'),(N'Lopez'),(N'Gonzalez'),(N'Wilson'),(N'Anderson'),
        (N'Thomas'),(N'Taylor'),(N'Moore'),(N'Jackson'),(N'Martin'),
        (N'Lee'),(N'Perez'),(N'Thompson'),(N'White'),(N'Harris'),
        (N'Sanchez'),(N'Clark'),(N'Ramirez'),(N'Lewis'),(N'Robinson')
    ) AS ln(name)
),
department_pool AS (
    SELECT name, ROW_NUMBER() OVER (ORDER BY name) AS rn FROM (VALUES
        (N'Computer Science'),(N'Software Engineering'),(N'Data Science'),
        (N'Artificial Intelligence'),(N'Cybersecurity'),
        (N'Information Systems'),(N'Computer Networks'),
        (N'Human-Computer Interaction')
    ) AS d(name)
),
numbered AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY fn.name, ln.name) AS seq,
        fn.name AS fn_name,
        ln.name AS ln_name,
        ABS(CHECKSUM(CONCAT('urole',  fn.name, ln.name))) % 100 AS role_roll,
        ABS(CHECKSUM(CONCAT('ustat',  fn.name, ln.name))) % 100 AS status_roll,
        ABS(CHECKSUM(CONCAT('uphn',   fn.name, ln.name))) % 100 AS phone_roll,
        ABS(CHECKSUM(CONCAT('udept',  fn.name, ln.name))) % 8   AS dept_roll
    FROM first_name_pool fn
    CROSS JOIN last_name_pool ln
)
INSERT INTO users (user_id, first_name, last_name, email, phone_number, role, department, account_status)
SELECT TOP (1500)
    'U' + RIGHT('00000' + CAST(seq AS VARCHAR(5)), 5),
    fn_name,
    ln_name,
    LOWER(fn_name + '.' + ln_name + RIGHT('00000' + CAST(seq AS VARCHAR(5)), 5) + '@university.edu'),
    CASE WHEN phone_roll < 8 THEN NULL
         ELSE '+1-555-' + RIGHT('0000' + CAST(1000 + seq AS VARCHAR(10)), 4) END,
    CASE
        WHEN role_roll < 62 THEN N'student'
        WHEN role_roll < 75 THEN N'lecturer'
        WHEN role_roll < 85 THEN N'teaching_assistant'
        WHEN role_roll < 91 THEN N'facility_staff'
        WHEN role_roll < 96 THEN N'department_administrator'
        ELSE N'facility_manager'
    END,
    dp.name,
    CASE WHEN status_roll < 92 THEN N'active' ELSE N'suspended' END
FROM numbered
JOIN department_pool dp ON dp.rn = dept_roll + 1
ORDER BY seq;
GO

-- ============================================================================
-- 2. SPACES (40 rows)
--    Buildings A-E, 8 spaces each. Type template per building:
--    AU, CR, CR, CL, PL, MR, MR, SW  (5 AU, 10 CR, 5 CL, 5 PL, 10 MR, 5 SW)
--    Capacity: multiples of 5 (AU 200-300, CR 40-50, CL 20-30, PL 15-25,
--    MR 10-20, SW 5-60). All spaces are bookable (no retired / temporarily
--    closed status) so maintenance impact is modelled through maintenance
--    records, matching the Phase 2 impact-level design (BR-42 / BR-44 / BR-45).
-- ============================================================================

WITH
buildings AS (
    SELECT letter, bidx FROM (VALUES
        ('A', 0), ('B', 1), ('C', 2), ('D', 3), ('E', 4)
    ) AS b(letter, bidx)
),
type_template AS (
    SELECT slot, type_name, prefix, min_cap, max_cap FROM (VALUES
        (1, N'auditorium',          'AU', 200, 300),
        (2, N'classroom',           'CR', 40,  50),
        (3, N'classroom',           'CR', 40,  50),
        (4, N'computer_laboratory', 'CL', 20,  30),
        (5, N'project_laboratory',  'PL', 15,  25),
        (6, N'meeting_room',        'MR', 10,  20),
        (7, N'meeting_room',        'MR', 10,  20),
        (8, N'student_workspace',   'SW', 5,   60)
    ) AS t(slot, type_name, prefix, min_cap, max_cap)
),
space_meta AS (
    SELECT
        b.letter,
        b.bidx,
        t.slot,
        t.type_name,
        t.prefix,
        t.min_cap,
        t.max_cap,
        1 + ((t.slot - 1) / 2) AS floor_num,
        CAST(b.bidx + 1 AS VARCHAR(2)) + RIGHT('0' + CAST(t.slot AS VARCHAR(2)), 2) AS room_num
    FROM buildings b
    CROSS JOIN type_template t
)
INSERT INTO spaces (space_code, space_name, space_type, building, floor, room_number, capacity, status, usage_policy)
SELECT
    letter + '-' + prefix + '-' + room_num AS space_code,
    N'Building ' + letter + N' ' +
        CASE type_name
            WHEN N'auditorium'          THEN N'Auditorium'
            WHEN N'classroom'           THEN N'Classroom'
            WHEN N'computer_laboratory' THEN N'Computer Lab'
            WHEN N'project_laboratory'  THEN N'Project Lab'
            WHEN N'meeting_room'        THEN N'Meeting Room'
            WHEN N'student_workspace'   THEN N'Study Area'
        END + N' ' + room_num AS space_name,
    type_name,
    letter,
    CAST(floor_num AS VARCHAR(5)),
    room_num,
    ((min_cap / 5) + ABS(CHECKSUM(CONCAT('cap', letter, room_num))) % ((max_cap - min_cap) / 5 + 1)) * 5 AS capacity,
    CASE WHEN ABS(CHECKSUM(CONCAT('spst', letter, room_num))) % 20 = 0 THEN N'in_use' ELSE N'available' END AS status,
    CASE type_name
        WHEN N'auditorium'          THEN N'Large lectures, examinations, and seminars.'
        WHEN N'classroom'           THEN N'Standard classroom instruction.'
        WHEN N'computer_laboratory' THEN N'Computer-based instruction and workshops.'
        WHEN N'project_laboratory'  THEN N'Scientific experiments and project work.'
        WHEN N'meeting_room'        THEN N'Meetings and small group discussions.'
        WHEN N'student_workspace'   THEN N'Student self-study and group work.'
    END
FROM space_meta;
GO

-- ============================================================================
-- 3. FACILITIES (18 rows)
-- ============================================================================

INSERT INTO facilities (facility_name, description)
VALUES
(N'Projector',             N'Digital projector with HDMI and VGA connectivity.'),
(N'Whiteboard',            N'Standard dry-erase whiteboard with markers.'),
(N'Smart Board',           N'Interactive smart board with touch capability.'),
(N'Air Conditioning',      N'HVAC system with temperature control.'),
(N'Computer Workstation',  N'Desktop computer with standard software suite.'),
(N'Laboratory Equipment',  N'Specialized scientific equipment.'),
(N'Video Conferencing',    N'Camera and microphone for remote meetings.'),
(N'Microphone System',     N'Wireless microphone and speaker system.'),
(N'Document Camera',       N'Camera for projecting documents and objects.'),
(N'Wheelchair Access',     N'Wheelchair-accessible entrance and seating.'),
(N'Printer',               N'Network-connected printer.'),
(N'Projection Screen',     N'Motorized projection screen.'),
(N'Speaker System',        N'Room audio speaker system.'),
(N'TV Monitor',            N'Large LCD TV monitor for presentations.'),
(N'Charging Station',      N'Multi-device charging station.'),
(N'Network Access Point',  N'High-density Wi-Fi access point.'),
(N'External Display',      N'Additional external display monitor.'),
(N'Recording Camera',      N'Video recording camera for lectures.');
GO

-- ============================================================================
-- 4. SPACE-FACILITIES (~150 rows)
--    Facility profile derived from the space type (deterministic quantities).
-- ============================================================================

WITH
space_type_map AS (
    SELECT space_code, space_type FROM spaces
),
facility_map AS (
    SELECT facility_id, facility_name FROM facilities
),
profile AS (
    SELECT
        stm.space_code,
        stm.space_type,
        fm.facility_name,
        fm.facility_id,
        CASE fm.facility_name
            WHEN N'Projector' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom', N'computer_laboratory', N'meeting_room') THEN 1 ELSE 0 END
            WHEN N'Whiteboard' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom', N'meeting_room') THEN 1 ELSE 0 END
            WHEN N'Smart Board' THEN
                CASE WHEN stm.space_type = N'classroom' THEN 1 ELSE 0 END
            WHEN N'Air Conditioning' THEN 1
            WHEN N'Computer Workstation' THEN
                CASE stm.space_type
                    WHEN N'computer_laboratory' THEN 20 + ABS(CHECKSUM(CONCAT('wks', stm.space_code))) % 11
                    WHEN N'student_workspace'   THEN 4
                    ELSE 0
                END
            WHEN N'Laboratory Equipment' THEN
                CASE WHEN stm.space_type = N'project_laboratory' THEN 5 + ABS(CHECKSUM(CONCAT('lab', stm.space_code))) % 6 ELSE 0 END
            WHEN N'Video Conferencing' THEN
                CASE WHEN stm.space_type IN (N'meeting_room', N'auditorium') THEN 1 ELSE 0 END
            WHEN N'Microphone System' THEN
                CASE WHEN stm.space_type = N'auditorium' THEN 2 ELSE 0 END
            WHEN N'Document Camera' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom') THEN 1 ELSE 0 END
            WHEN N'Wheelchair Access' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom') THEN 1 ELSE 0 END
            WHEN N'Printer' THEN
                CASE WHEN stm.space_type IN (N'computer_laboratory', N'student_workspace') THEN 1 ELSE 0 END
            WHEN N'Projection Screen' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom', N'meeting_room') THEN 1 ELSE 0 END
            WHEN N'Speaker System' THEN
                CASE WHEN stm.space_type = N'auditorium' THEN 1 ELSE 0 END
            WHEN N'TV Monitor' THEN
                CASE WHEN stm.space_type IN (N'meeting_room', N'student_workspace') THEN 1 ELSE 0 END
            WHEN N'Charging Station' THEN
                CASE WHEN stm.space_type = N'student_workspace' THEN 2 ELSE 0 END
            WHEN N'Network Access Point' THEN 1
            WHEN N'External Display' THEN
                CASE WHEN stm.space_type IN (N'meeting_room', N'computer_laboratory') THEN 1 ELSE 0 END
            WHEN N'Recording Camera' THEN
                CASE WHEN stm.space_type = N'auditorium' THEN 1 ELSE 0 END
            ELSE 0
        END AS qty
    FROM space_type_map stm
    CROSS JOIN facility_map fm
)
INSERT INTO space_facilities (space_code, facility_id, quantity)
SELECT space_code, facility_id, qty
FROM profile
WHERE qty > 0;
GO

-- ============================================================================
-- 5. COMPLETED MAINTENANCE RECORDS (2600 rows) — inserted BEFORE bookings
--    Both impact levels, status completed only (BR-42). Completed records are
--    inert for the BR-44 / BR-46 booking triggers (they filter on
--    status IN (reported, in_progress)), so Wave-1 bookings may overlap them.
--    Reporter: any user. assigned_staff: facility_staff / facility_manager
--    (BR-NI-12). completion_time > start_time (BR-39).
--    Timeline: start_time spans 2023-09-01 .. 2026-08-15 (day_off % 1080);
--    completion_time adds +1..14 days, so every completion precedes the @Now
--    anchor (2026-08-31) — no future-dated completion records.
-- ============================================================================

DECLARE @AY1Start DATETIME2 = '2023-09-01 00:00:00';  -- Academic year 2023-24 (DATETIME2 per Temporal Data Handling)
DECLARE @UserCount INT = (SELECT COUNT(*) FROM users);
DECLARE @StaffCount INT = (SELECT COUNT(*) FROM users WHERE role IN (N'facility_staff', N'facility_manager'));

WITH
nums AS (
    SELECT TOP (2600) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_columns a
    CROSS JOIN sys.all_columns b
),
numbered_users AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM users
),
numbered_spaces AS (
    SELECT space_code, ROW_NUMBER() OVER (ORDER BY space_code) AS rn FROM spaces
),
staff_pool AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users WHERE role IN (N'facility_staff', N'facility_manager')
),
mgen AS (
    SELECT
        n,
        ABS(CHECKSUM(CONCAT('msp', n)))    % 40    + 1 AS space_rn,
        ABS(CHECKSUM(CONCAT('mrep', n)))   % @UserCount + 1 AS reporter_rn,
        ABS(CHECKSUM(CONCAT('mstf', n)))   % @StaffCount + 1 AS staff_rn,
        ABS(CHECKSUM(CONCAT('mday', n)))   % 1080       AS day_off,
        ABS(CHECKSUM(CONCAT('mhr', n)))    % 10 + 8     AS start_hr,
        ABS(CHECKSUM(CONCAT('mdur', n)))   % 14 + 1     AS comp_days,
        ABS(CHECKSUM(CONCAT('mlevel', n))) % 100        AS level_roll,
        ABS(CHECKSUM(CONCAT('mprob', n)))  % 8          AS prob_roll,
        ABS(CHECKSUM(CONCAT('mnote', n)))  % 12         AS note_roll
    FROM nums
)
INSERT INTO maintenance_records
    (reporter_id, space_code, assigned_staff_id, problem_description,
     start_time, completion_time, status, result_note, impact_level)
SELECT
    nu.user_id,
    ns.space_code,
    sp.user_id,
    CASE WHEN mgen.level_roll < 65 THEN
        -- advisory problems
        CASE mgen.prob_roll
            WHEN 0 THEN N'Air conditioning noise above normal level.'
            WHEN 1 THEN N'One whiteboard panel smudged and hard to erase.'
            WHEN 2 THEN N'Lighting flickers in one corner of the room.'
            WHEN 3 THEN N'Projector brightness lower than normal.'
            WHEN 4 THEN N'One chair wobbles slightly when occupied.'
            WHEN 5 THEN N'Network speed noticeably slower than usual.'
            WHEN 6 THEN N'Dust accumulation on equipment surfaces.'
            ELSE      N'Window seal draft causes temperature variance.'
        END
    ELSE
        -- out-of-service problems
        CASE mgen.prob_roll
            WHEN 0 THEN N'Complete power outage affecting the room.'
            WHEN 1 THEN N'Water leak from ceiling above the room.'
            WHEN 2 THEN N'Air conditioning unit failed completely.'
            WHEN 3 THEN N'Fire alarm panel fault - room temporarily unusable.'
            WHEN 4 THEN N'Broken window glass - hazard for occupants.'
            WHEN 5 THEN N'Network switch offline - no connectivity.'
            WHEN 6 THEN N'Projector failed and no replacement available.'
            ELSE      N'Floor damage poses a safety hazard.'
        END
    END,
    DATEADD(HOUR, mgen.start_hr, DATEADD(DAY, mgen.day_off, @AY1Start)),
    DATEADD(DAY, mgen.comp_days, DATEADD(HOUR, mgen.start_hr, DATEADD(DAY, mgen.day_off, @AY1Start))),
    N'completed',
    CASE mgen.note_roll
        WHEN 0  THEN N'Issue resolved successfully. All systems operational.'
        WHEN 1  THEN N'Equipment replaced with a new unit. Functionality restored.'
        WHEN 2  THEN N'Routine maintenance completed. No further action needed.'
        WHEN 3  THEN N'Component repaired and tested. Working correctly.'
        WHEN 4  THEN N'Electrician completed repairs. Safety check passed.'
        WHEN 5  THEN N'Network reconnected. Connectivity verified.'
        WHEN 6  THEN N'Glass replaced and area secured.'
        WHEN 7  THEN N'AC serviced and cooling restored to normal levels.'
        WHEN 8  THEN N'Cleaning and calibration completed. Ready for use.'
        WHEN 9  THEN N'Software reinstall completed. System rebooted.'
        WHEN 10 THEN N'Hardware diagnostic passed. No defects found.'
        ELSE          N'Maintenance completed per standard procedure.'
    END,
    CASE WHEN mgen.level_roll < 65 THEN N'advisory' ELSE N'out_of_service' END
FROM mgen
JOIN numbered_users nu ON nu.rn = mgen.reporter_rn
JOIN numbered_spaces ns ON ns.rn = mgen.space_rn
JOIN staff_pool sp ON sp.rn = mgen.staff_rn;
GO

-- ============================================================================
-- 6. WAVE-1 BOOKINGS (~120 000 rows) — inserted while no OPEN maintenance
--    record exists, therefore advisory_acknowledged = NULL is correct at
--    insert time (BR-45: no advisory was active at booking time). Section 12.2
--    later backfills the acknowledgement for the effective bookings that the
--    Section 7 advisories overlap, so the final dataset is fully BR-46-
--    consistent (see Section 12 for the resolution rationale).
--
--    Generation model (deterministic, set-based):
--      * Calendar  = every weekday (Mon-Sat) from 2023-09-01 to 2026-12-31
--                    (academic years 2023-24, 2024-25, 2025-26 plus the autumn
--                    2026 semester).
--      * Slots     = six 2-hour blocks per space-day: 08-10, 10-12, 12-14,
--                    14-16, 16-18, 18-20. A slot is included when a
--                    deterministic hash is below a space-type x weekday x
--                    block usage probability.
--      * Non-overlap: at most one booking per block per space-day, so no two
--                    bookings for the same space ever overlap (BR-14 / BR-50
--                    data-level realism).
--      * Non-uniform usage: teaching blocks (10-12, 14-16) and weekdays
--                    Mon-Thu are busier; lunch (12-14), Friday and Saturday
--                    are lighter.
--      * eff_pct = base_pct * dcf/100 * bcf/100 (integer math, / 10000),
--                    clamped to [4, 97] so low-usage combos stay sparse and
--                    high-usage combos cap below 100.
--      * Statuses: past bookings mostly completed/no_show/cancelled/rejected;
--                    future bookings mostly approved/pending.
-- ============================================================================

DECLARE @AY1Start DATE = '2023-09-01';           -- Academic year 2023-24
DECLARE @AY3Start DATE = '2025-09-01';           -- Academic year 2025-26
DECLARE @CalEnd   DATE = '2026-12-31';           -- incl. autumn 2026 semester
DECLARE @Now      DATETIME2 = '2026-08-31 00:00:00';  -- status "now" anchor
DECLARE @ReqCount INT = (SELECT COUNT(*) FROM users WHERE role IN (N'student', N'lecturer', N'teaching_assistant'));

WITH
nums AS (
    SELECT TOP (1400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_columns a
    CROSS JOIN sys.all_columns b
),
calendar AS (
    -- iso_dow is DATEFIRST-independent: 0=Mon .. 6=Sun (1900-01-01 was a Monday)
    SELECT
        DATEADD(DAY, n, @AY1Start) AS [day],
        DATEDIFF(DAY, '1900-01-01', DATEADD(DAY, n, @AY1Start)) % 7 AS iso_dow
    FROM nums
    WHERE DATEADD(DAY, n, @AY1Start) <= @CalEnd
      AND DATEDIFF(DAY, '1900-01-01', DATEADD(DAY, n, @AY1Start)) % 7 <= 5
),
space_info AS (
    SELECT space_code, space_type, capacity FROM spaces
),
blocks AS (
    SELECT n AS block_num FROM nums WHERE n BETWEEN 1 AND 6
),
prob AS (
    SELECT
        t.space_type,
        t.base_pct,
        df.iso_dow,
        df.dcf,
        bf.block_num,
        bf.bcf
    FROM (VALUES
        (N'auditorium',          35),
        (N'classroom',           78),
        (N'computer_laboratory', 70),
        (N'project_laboratory',  50),
        (N'meeting_room',        62),
        (N'student_workspace',   65)
    ) t(space_type, base_pct)
    CROSS JOIN (VALUES (0,105),(1,105),(2,100),(3,100),(4,80),(5,55)) df(iso_dow, dcf)
    CROSS JOIN (VALUES (1,90),(2,115),(3,30),(4,115),(5,100),(6,55),(7,75)) bf(block_num, bcf)
),
cand AS (
    SELECT
        c.[day],
        s.space_code,
        s.space_type,
        s.capacity,
        b.block_num,
        p.base_pct,
        p.dcf,
        p.bcf,
        CASE WHEN (p.base_pct * p.dcf * p.bcf) / 10000 < 4  THEN 4
             WHEN (p.base_pct * p.dcf * p.bcf) / 10000 > 97 THEN 97
             ELSE (p.base_pct * p.dcf * p.bcf) / 10000 END AS eff_pct,
        ABS(CHECKSUM(CONCAT('incl', s.space_code, CONVERT(varchar(10), c.[day], 112), b.block_num))) % 100 AS incl_roll,
        ABS(CHECKSUM(CONCAT('purp', s.space_code, CONVERT(varchar(10), c.[day], 112), b.block_num))) % 100 AS purp_roll,
        ABS(CHECKSUM(CONCAT('part', s.space_code, CONVERT(varchar(10), c.[day], 112), b.block_num))) % 100 AS part_roll,
        ABS(CHECKSUM(CONCAT('stat', s.space_code, CONVERT(varchar(10), c.[day], 112), b.block_num))) % 100 AS stat_roll,
        ABS(CHECKSUM(CONCAT('req',  s.space_code, CONVERT(varchar(10), c.[day], 112), b.block_num))) % @ReqCount AS req_off,
        CONVERT(datetime2, c.[day]) AS base_dt
    FROM calendar c
    CROSS JOIN space_info s
    CROSS JOIN blocks b
    JOIN prob p ON p.space_type = s.space_type AND p.iso_dow = c.iso_dow AND p.block_num = b.block_num
),
req_pool AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users WHERE role IN (N'student', N'lecturer', N'teaching_assistant')
)
INSERT INTO bookings
    (requester_id, space_code, requested_start_time, requested_end_time,
     purpose, expected_participants, status, advisory_acknowledged)
SELECT
    rp.user_id,
    c.space_code,
    DATEADD(HOUR, 8 + 2 * (c.block_num - 1), c.base_dt) AS start_t,
    DATEADD(HOUR, 10 + 2 * (c.block_num - 1), c.base_dt) AS end_t,
    -- purpose distribution is correlated with the space type (realism)
    CASE c.space_type
        WHEN N'auditorium' THEN
            CASE WHEN c.purp_roll < 35 THEN N'lecture'
                 WHEN c.purp_roll < 65 THEN N'seminar'
                 WHEN c.purp_roll < 85 THEN N'examination'
                 WHEN c.purp_roll < 95 THEN N'workshop'
                 ELSE N'administrative_event' END
        WHEN N'classroom' THEN
            CASE WHEN c.purp_roll < 55 THEN N'lecture'
                 WHEN c.purp_roll < 70 THEN N'examination'
                 WHEN c.purp_roll < 80 THEN N'seminar'
                 WHEN c.purp_roll < 90 THEN N'workshop'
                 WHEN c.purp_roll < 95 THEN N'student_activity'
                 ELSE N'administrative_event' END
        WHEN N'computer_laboratory' THEN
            CASE WHEN c.purp_roll < 45 THEN N'workshop'
                 WHEN c.purp_roll < 80 THEN N'lecture'
                 WHEN c.purp_roll < 90 THEN N'seminar'
                 ELSE N'student_activity' END
        WHEN N'project_laboratory' THEN
            CASE WHEN c.purp_roll < 40 THEN N'workshop'
                 WHEN c.purp_roll < 70 THEN N'student_activity'
                 WHEN c.purp_roll < 85 THEN N'seminar'
                 ELSE N'lecture' END
        WHEN N'meeting_room' THEN
            CASE WHEN c.purp_roll < 75 THEN N'meeting'
                 WHEN c.purp_roll < 90 THEN N'administrative_event'
                 ELSE N'seminar' END
        ELSE
            CASE WHEN c.purp_roll < 70 THEN N'student_activity'
                 WHEN c.purp_roll < 90 THEN N'meeting'
                 ELSE N'seminar' END
    END,
    -- expected_participants: 20%-79% of capacity, multiples of 5, clamped to
    -- [5, capacity] (BR-40: never exceeds the space capacity)
    CASE
        WHEN c.capacity <= 5 THEN 5
        ELSE
            CASE
                WHEN ((c.capacity * (0.20 + (c.part_roll % 60) / 100.0)) / 5) * 5 < 5 THEN 5
                WHEN ((c.capacity * (0.20 + (c.part_roll % 60) / 100.0)) / 5) * 5 > c.capacity THEN c.capacity
                ELSE CAST(((c.capacity * (0.20 + (c.part_roll % 60) / 100.0)) / 5) * 5 AS INT)
            END
    END,
    -- status lifecycle: future bookings are mostly approved/pending;
    -- past bookings reflect completed / no_show / cancelled / rejected mix
    CASE
        WHEN DATEADD(HOUR, 8 + 2 * (c.block_num - 1), c.base_dt) >= @Now THEN
            CASE WHEN c.stat_roll < 65 THEN N'approved'
                 WHEN c.stat_roll < 85 THEN N'pending'
                 WHEN c.stat_roll < 95 THEN N'cancelled'
                 ELSE N'rejected' END
        ELSE
            CASE WHEN c.stat_roll < 55 THEN N'completed'
                 WHEN c.stat_roll < 62 THEN N'no_show'
                 WHEN c.stat_roll < 74 THEN N'cancelled'
                 WHEN c.stat_roll < 82 THEN N'rejected'
                 WHEN c.stat_roll < 83 THEN N'checked_in'
                 WHEN c.stat_roll < 97 THEN N'approved'
                 ELSE N'pending' END
    END,
    NULL
FROM cand c
JOIN req_pool rp ON rp.rn = c.req_off + 1
WHERE c.incl_roll < c.eff_pct;
GO

-- ============================================================================
-- 7. OPEN ADVISORY MAINTENANCE RECORDS (320 rows) — inserted AFTER Wave-1,
--    BEFORE Wave-2.  status = reported/in_progress, completion_time = NULL.
--    These records overlap existing Wave-1 bookings (advisory does not block
--    booking — BR-45) and drive the advisory_acknowledged = 1 requirement for
--    Wave-2 bookings (BR-46). Multiple simultaneously active records per space
--    are allowed (BR-43). The Wave-1 overlaps these records create are
--    resolved by Section 12.2, which backfills advisory_acknowledged = 1.
--    Start times are clamped (day_off % 725) so every open advisory record
--    begins strictly before the @Now anchor (2026-08-31): an in_progress
--    record is never dated in the future.
-- ============================================================================

DECLARE @AY2Start DATETIME2 = '2024-09-01 00:00:00';  -- Academic year 2024-25 (DATETIME2 per Temporal Data Handling)
DECLARE @UserCount INT = (SELECT COUNT(*) FROM users);
DECLARE @StaffCount INT = (SELECT COUNT(*) FROM users WHERE role IN (N'facility_staff', N'facility_manager'));

WITH
nums AS (
    SELECT TOP (320) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_columns
),
numbered_users AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM users
),
numbered_spaces AS (
    SELECT space_code, ROW_NUMBER() OVER (ORDER BY space_code) AS rn FROM spaces
),
staff_pool AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users WHERE role IN (N'facility_staff', N'facility_manager')
),
mgen AS (
    SELECT
        n,
        ABS(CHECKSUM(CONCAT('bsp', n)))  % 40 + 1      AS space_rn,
        ABS(CHECKSUM(CONCAT('brep', n))) % @UserCount + 1 AS reporter_rn,
        ABS(CHECKSUM(CONCAT('bstf', n))) % @StaffCount + 1 AS staff_rn,
        ABS(CHECKSUM(CONCAT('bday', n)))  % 725         AS day_off,
        ABS(CHECKSUM(CONCAT('bhr', n)))  % 12          AS start_hr,
        ABS(CHECKSUM(CONCAT('bstat', n)))% 2           AS status_roll,
        ABS(CHECKSUM(CONCAT('bprob', n)))% 8           AS prob_roll
    FROM nums
)
INSERT INTO maintenance_records
    (reporter_id, space_code, assigned_staff_id, problem_description,
     start_time, completion_time, status, result_note, impact_level)
SELECT
    nu.user_id,
    ns.space_code,
    sp.user_id,
    CASE mgen.prob_roll
        WHEN 0 THEN N'Air conditioning noise above normal level.'
        WHEN 1 THEN N'One whiteboard panel smudged and hard to erase.'
        WHEN 2 THEN N'Lighting flickers in one corner of the room.'
        WHEN 3 THEN N'Projector brightness lower than normal.'
        WHEN 4 THEN N'One chair wobbles slightly when occupied.'
        WHEN 5 THEN N'Network speed noticeably slower than usual.'
        WHEN 6 THEN N'Dust accumulation on equipment surfaces.'
        ELSE      N'Window seal draft causes temperature variance.'
    END,
    DATEADD(HOUR, mgen.start_hr, DATEADD(DAY, mgen.day_off, @AY2Start)),
    NULL,
    CASE WHEN mgen.status_roll = 0 THEN N'reported' ELSE N'in_progress' END,
    NULL,
    N'advisory'
FROM mgen
JOIN numbered_users nu ON nu.rn = mgen.reporter_rn
JOIN numbered_spaces ns ON ns.rn = mgen.space_rn
JOIN staff_pool sp ON sp.rn = mgen.staff_rn;
GO

-- ============================================================================
-- 8. WAVE-2 BOOKINGS (~6 000 rows) — advisory-enabled bookings in the last
--    academic year and autumn 2026 semester, block 20:00-22:00 (a slot the
--    Wave-1 generator never uses, so no space can ever have two overlapping
--    bookings across the two waves).
--    One candidate per space-day: the prob CTE yields exactly one row per
--    space-type x weekday for block 7 (the bf cross join is restricted to the
--    single block-7 row), so the Section 6 non-overlap invariant holds within
--    Wave-2 as well — at most one booking per space-day at 20:00-22:00.
--    eff_pct uses the same / 10000 semantics as Wave-1 (see Section 6).
--
--    advisory_acknowledged is computed with EXACTLY the BR-46 trigger
--    predicate (open advisory record overlapping the requested period), so
--    every inserted row satisfies trg_bookings_br46_advisory_acknowledgement:
--       * overlapping open advisory  -> advisory_acknowledged = 1
--       * no overlapping open advisory -> NULL (BR-45)
--    No open out-of-service record exists yet, so the BR-44 trigger passes
--    for every row.
-- ============================================================================

DECLARE @AY3Start DATE = '2025-09-01';           -- Academic year 2025-26
DECLARE @CalEnd   DATE = '2026-12-31';
DECLARE @Now      DATETIME2 = '2026-08-31 00:00:00';
DECLARE @ReqCount INT = (SELECT COUNT(*) FROM users WHERE role IN (N'student', N'lecturer', N'teaching_assistant'));

WITH
nums AS (
    SELECT TOP (1400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_columns a
    CROSS JOIN sys.all_columns b
),
calendar AS (
    SELECT
        DATEADD(DAY, n, @AY3Start) AS [day],
        DATEDIFF(DAY, '1900-01-01', DATEADD(DAY, n, @AY3Start)) % 7 AS iso_dow
    FROM nums
    WHERE DATEADD(DAY, n, @AY3Start) <= @CalEnd
      AND DATEDIFF(DAY, '1900-01-01', DATEADD(DAY, n, @AY3Start)) % 7 <= 5
),
space_info AS (
    SELECT space_code, space_type, capacity FROM spaces
),
prob AS (
    SELECT
        t.space_type,
        t.base_pct,
        df.iso_dow,
        df.dcf,
        7 AS block_num,
        bf.bcf
    FROM (VALUES
        (N'auditorium',          35),
        (N'classroom',           78),
        (N'computer_laboratory', 70),
        (N'project_laboratory',  50),
        (N'meeting_room',        62),
        (N'student_workspace',   65)
    ) t(space_type, base_pct)
    CROSS JOIN (VALUES (0,105),(1,105),(2,100),(3,100),(4,80),(5,55)) df(iso_dow, dcf)
    CROSS JOIN (VALUES (7,75)) bf(block_num, bcf)
),
cand AS (
    SELECT
        c.[day],
        s.space_code,
        s.space_type,
        s.capacity,
        p.base_pct,
        p.dcf,
        p.bcf,
        CASE WHEN (p.base_pct * p.dcf * p.bcf) / 10000 < 4  THEN 4
             WHEN (p.base_pct * p.dcf * p.bcf) / 10000 > 97 THEN 97
             ELSE (p.base_pct * p.dcf * p.bcf) / 10000 END AS eff_pct,
        ABS(CHECKSUM(CONCAT('incl', s.space_code, CONVERT(varchar(10), c.[day], 112), 7))) % 100 AS incl_roll,
        ABS(CHECKSUM(CONCAT('purp', s.space_code, CONVERT(varchar(10), c.[day], 112), 7))) % 100 AS purp_roll,
        ABS(CHECKSUM(CONCAT('part', s.space_code, CONVERT(varchar(10), c.[day], 112), 7))) % 100 AS part_roll,
        ABS(CHECKSUM(CONCAT('stat', s.space_code, CONVERT(varchar(10), c.[day], 112), 7))) % 100 AS stat_roll,
        ABS(CHECKSUM(CONCAT('req',  s.space_code, CONVERT(varchar(10), c.[day], 112), 7))) % @ReqCount AS req_off,
        CONVERT(datetime2, c.[day]) AS base_dt,
        DATEADD(HOUR, 20, CONVERT(datetime2, c.[day])) AS start_t,
        DATEADD(HOUR, 22, CONVERT(datetime2, c.[day])) AS end_t
    FROM calendar c
    CROSS JOIN space_info s
    JOIN prob p ON p.space_type = s.space_type AND p.iso_dow = c.iso_dow
),
req_pool AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users WHERE role IN (N'student', N'lecturer', N'teaching_assistant')
)
INSERT INTO bookings
    (requester_id, space_code, requested_start_time, requested_end_time,
     purpose, expected_participants, status, advisory_acknowledged)
SELECT
    rp.user_id,
    c.space_code,
    c.start_t,
    c.end_t,
    -- evening sessions skew to workshops / student activities / meetings
    CASE c.space_type
        WHEN N'meeting_room' THEN
            CASE WHEN c.purp_roll < 60 THEN N'meeting'
                 WHEN c.purp_roll < 85 THEN N'administrative_event'
                 ELSE N'seminar' END
        WHEN N'student_workspace' THEN
            CASE WHEN c.purp_roll < 60 THEN N'student_activity'
                 WHEN c.purp_roll < 85 THEN N'meeting'
                 ELSE N'seminar' END
        WHEN N'computer_laboratory' THEN
            CASE WHEN c.purp_roll < 60 THEN N'workshop'
                 WHEN c.purp_roll < 80 THEN N'lecture'
                 ELSE N'student_activity' END
        WHEN N'project_laboratory' THEN
            CASE WHEN c.purp_roll < 55 THEN N'workshop'
                 ELSE N'student_activity' END
        WHEN N'auditorium' THEN
            CASE WHEN c.purp_roll < 50 THEN N'seminar'
                 WHEN c.purp_roll < 80 THEN N'examination'
                 ELSE N'administrative_event' END
        ELSE
            CASE WHEN c.purp_roll < 45 THEN N'lecture'
                 WHEN c.purp_roll < 70 THEN N'examination'
                 WHEN c.purp_roll < 85 THEN N'seminar'
                 ELSE N'workshop' END
    END,
    CASE
        WHEN c.capacity <= 5 THEN 5
        ELSE
            CASE
                WHEN ((c.capacity * (0.20 + (c.part_roll % 60) / 100.0)) / 5) * 5 < 5 THEN 5
                WHEN ((c.capacity * (0.20 + (c.part_roll % 60) / 100.0)) / 5) * 5 > c.capacity THEN c.capacity
                ELSE CAST(((c.capacity * (0.20 + (c.part_roll % 60) / 100.0)) / 5) * 5 AS INT)
            END
    END,
    CASE
        WHEN c.start_t >= @Now THEN
            CASE WHEN c.stat_roll < 65 THEN N'approved'
                 WHEN c.stat_roll < 85 THEN N'pending'
                 WHEN c.stat_roll < 95 THEN N'cancelled'
                 ELSE N'rejected' END
        ELSE
            CASE WHEN c.stat_roll < 55 THEN N'completed'
                 WHEN c.stat_roll < 62 THEN N'no_show'
                 WHEN c.stat_roll < 74 THEN N'cancelled'
                 WHEN c.stat_roll < 82 THEN N'rejected'
                 WHEN c.stat_roll < 83 THEN N'checked_in'
                 WHEN c.stat_roll < 97 THEN N'approved'
                 ELSE N'pending' END
    END,
    -- BR-46 predicate, mirrored exactly from the trigger
    CASE WHEN EXISTS
    (
        SELECT 1
          FROM maintenance_records m
         WHERE m.space_code     = c.space_code
           AND m.impact_level   = N'advisory'
           AND m.status         IN (N'reported', N'in_progress')
           AND c.end_t          > m.start_time
           AND (m.completion_time IS NULL OR c.start_t < m.completion_time)
    ) THEN 1 ELSE NULL END
FROM cand c
JOIN req_pool rp ON rp.rn = c.req_off + 1
WHERE c.incl_roll < c.eff_pct;
GO

-- ============================================================================
-- 9. APPROVALS (~116 000 rows) — one approval per decided booking
--    (approved / rejected / checked_in / completed / no_show, plus 60% of
--    cancelled bookings that were approved before cancellation).
--    Rules respected:
--      BR-NI-02/BR-28: approved bookings have an approval with decision
--                      approved (instant-booking approval record included).
--      BR-29: rejected bookings have decision rejected and a rejection_reason.
--      BR-NI-10: decision_time < requested_start_time.
--      BR-NI-11: approver_id != requester_id (approvers are admins/managers
--                while requesters are students/lecturers/teaching assistants).
-- ============================================================================

DECLARE @ApproverCount INT = (SELECT COUNT(*) FROM users WHERE role IN (N'department_administrator', N'facility_manager'));

WITH
approvers AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users WHERE role IN (N'department_administrator', N'facility_manager')
),
eligible AS (
    SELECT
        b.booking_id,
        b.requester_id,
        b.purpose,
        b.status,
        b.requested_start_time,
        ABS(CHECKSUM(CONCAT('appr',   b.booking_id))) % @ApproverCount + 1 AS appr_rn,
        ABS(CHECKSUM(CONCAT('dtime',  b.booking_id))) % 96 + 1            AS hours_before,
        ABS(CHECKSUM(CONCAT('reason', b.booking_id))) % 6                 AS reason_roll
    FROM bookings b
    WHERE b.status IN (N'approved', N'rejected', N'checked_in', N'completed', N'no_show')
       OR (b.status = N'cancelled' AND ABS(CHECKSUM(CONCAT('cxlappr', b.booking_id))) % 100 < 60)
)
INSERT INTO approvals (booking_id, approver_id, decision, decision_time, decision_note, rejection_reason)
SELECT
    e.booking_id,
    a.user_id,
    CASE WHEN e.status = N'rejected' THEN N'rejected' ELSE N'approved' END,
    DATEADD(HOUR, -1 * e.hours_before, e.requested_start_time),
    CASE
        WHEN e.status = N'rejected' THEN NULL
        ELSE CASE e.purpose
                 WHEN N'lecture'              THEN N'Lecture session approved.'
                 WHEN N'examination'          THEN N'Examination session approved. Proctors assigned.'
                 WHEN N'seminar'              THEN N'Seminar approved.'
                 WHEN N'workshop'             THEN N'Workshop approved.'
                 WHEN N'meeting'              THEN N'Meeting booking approved.'
                 WHEN N'student_activity'     THEN N'Student activity approved.'
                 WHEN N'administrative_event' THEN N'Administrative event approved.'
                 ELSE N'Booking approved.'
             END
    END,
    CASE
        WHEN e.status = N'rejected' THEN
            CASE e.reason_roll
                WHEN 0 THEN N'Scheduling conflict with an existing booking.'
                WHEN 1 THEN N'Requested capacity exceeds the room limit.'
                WHEN 2 THEN N'Duplicate request - an identical booking already exists.'
                WHEN 3 THEN N'Invalid booking details provided.'
                WHEN 4 THEN N'Room under out-of-service maintenance at the requested time.'
                ELSE      N'Insufficient resources available for this request.'
            END
        ELSE NULL
    END
FROM eligible e
JOIN approvers a ON a.rn = e.appr_rn;
GO

-- ============================================================================
-- 10. SESSIONS (~72 000 rows) — one session per actually-conducted booking
--     (completed / checked_in / no_show).  Only approved bookings can have
--     sessions (BR-NI-03 / BR-13).  Conductor is facility_staff or
--     facility_manager (BR-NI-12).  Session time ordering satisfies
--     BR-38 / ck_sessions_time_range.
-- ============================================================================

DECLARE @ConductorCount INT = (SELECT COUNT(*) FROM users WHERE role IN (N'facility_staff', N'facility_manager'));

WITH
conductors AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users WHERE role IN (N'facility_staff', N'facility_manager')
),
eligible AS (
    SELECT
        b.booking_id,
        b.requested_start_time,
        b.requested_end_time,
        b.status,
        ABS(CHECKSUM(CONCAT('cond',  b.booking_id))) % @ConductorCount + 1 AS cond_rn,
        ABS(CHECKSUM(CONCAT('sstart',b.booking_id))) % 14 + 2              AS late_min,
        ABS(CHECKSUM(CONCAT('send',  b.booking_id))) % 20                  AS end_var,
        ABS(CHECKSUM(CONCAT('sinit', b.booking_id))) % 5                   AS init_roll,
        ABS(CHECKSUM(CONCAT('sfin',  b.booking_id))) % 4                   AS fin_roll,
        ABS(CHECKSUM(CONCAT('snote', b.booking_id))) % 5                   AS note_roll
    FROM bookings b
    WHERE b.status IN (N'completed', N'checked_in', N'no_show')
)
INSERT INTO sessions
    (booking_id, conductor_id, actual_start_time, actual_end_time,
     initial_condition, final_condition, usage_notes)
SELECT
    e.booking_id,
    c.user_id,
    DATEADD(MINUTE, e.late_min, e.requested_start_time),
    CASE
        WHEN e.status IN (N'checked_in', N'no_show') THEN NULL
        -- actual_end = requested_end -10 .. +9 min, always > actual_start
        ELSE DATEADD(MINUTE, e.end_var - 10, e.requested_end_time)
    END,
    CASE e.init_roll
        WHEN 0 THEN N'Room clean and ready. Equipment functional.'
        WHEN 1 THEN N'Space prepared. All facilities operational.'
        WHEN 2 THEN N'Room in good condition. Setup completed.'
        WHEN 3 THEN N'Equipment checked and operational.'
        ELSE      N'Space ready for session.'
    END,
    CASE
        WHEN e.status = N'checked_in' THEN NULL
        ELSE CASE e.fin_roll
                 WHEN 0 THEN N'Room tidy. Equipment turned off.'
                 WHEN 1 THEN N'Space returned to neutral state.'
                 WHEN 2 THEN N'All equipment shut down. Room clean.'
                 ELSE      N'Session ended. Minor cleanup needed.'
             END
    END,
    CASE
        WHEN e.status = N'no_show' THEN N'No participants attended. Recorded as no-show.'
        ELSE CASE e.note_roll
                 WHEN 0 THEN N'Session conducted as planned.'
                 WHEN 1 THEN N'All activities completed successfully.'
                 WHEN 2 THEN N'Good attendance. Session productive.'
                 WHEN 3 THEN N'Session ran smoothly.'
                 ELSE      N'Standard session completed.'
             END
    END
FROM eligible e
JOIN conductors c ON c.rn = e.cond_rn;
GO

-- ============================================================================
-- 11. OPEN OUT-OF-SERVICE MAINTENANCE RECORDS (180 rows) — inserted LAST.
--     These represent recent escalations (RC-04 / RC-05).  Their periods may
--     overlap already-approved bookings: escalation surfaces affected
--     bookings for staff contact (BR-48). Inserting them after all bookings
--     is correct and cannot violate trg_bookings_br44_no_overlap_out_of_service.
--     Section 12.1 resolves the overlaps by cancelling every pending/approved
--     booking affected; conducted bookings (historical fact) are reported by
--     the Section 14 M-1h check instead.
--     Start times are clamped (day_off % 362) so every open out-of-service
--     record begins strictly before the @Now anchor (2026-08-31): an open
--     record is never dated in the future.
-- ============================================================================

DECLARE @AY3Start DATETIME2 = '2025-09-01 00:00:00';  -- Academic year 2025-26 (DATETIME2 per Temporal Data Handling)
DECLARE @UserCount INT = (SELECT COUNT(*) FROM users);
DECLARE @StaffCount INT = (SELECT COUNT(*) FROM users WHERE role IN (N'facility_staff', N'facility_manager'));

WITH
nums AS (
    SELECT TOP (180) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_columns
),
numbered_users AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM users
),
numbered_spaces AS (
    SELECT space_code, ROW_NUMBER() OVER (ORDER BY space_code) AS rn FROM spaces
),
staff_pool AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users WHERE role IN (N'facility_staff', N'facility_manager')
),
mgen AS (
    SELECT
        n,
        ABS(CHECKSUM(CONCAT('csp', n)))  % 40 + 1      AS space_rn,
        ABS(CHECKSUM(CONCAT('crep', n))) % @UserCount + 1 AS reporter_rn,
        ABS(CHECKSUM(CONCAT('cstf', n))) % @StaffCount + 1 AS staff_rn,
        ABS(CHECKSUM(CONCAT('cday', n))) % 362         AS day_off,
        ABS(CHECKSUM(CONCAT('chr', n)))  % 12          AS start_hr,
        ABS(CHECKSUM(CONCAT('cstat', n)))% 2           AS status_roll,
        ABS(CHECKSUM(CONCAT('cprob', n)))% 8           AS prob_roll
    FROM nums
)
INSERT INTO maintenance_records
    (reporter_id, space_code, assigned_staff_id, problem_description,
     start_time, completion_time, status, result_note, impact_level)
SELECT
    nu.user_id,
    ns.space_code,
    sp.user_id,
    CASE mgen.prob_roll
        WHEN 0 THEN N'Complete power outage affecting the room.'
        WHEN 1 THEN N'Water leak from ceiling above the room.'
        WHEN 2 THEN N'Air conditioning unit failed completely.'
        WHEN 3 THEN N'Fire alarm panel fault - room temporarily unusable.'
        WHEN 4 THEN N'Broken window glass - hazard for occupants.'
        WHEN 5 THEN N'Network switch offline - no connectivity.'
        WHEN 6 THEN N'Projector failed and no replacement available.'
        ELSE      N'Floor damage poses a safety hazard.'
    END,
    DATEADD(HOUR, mgen.start_hr, DATEADD(DAY, mgen.day_off, @AY3Start)),
    NULL,
    CASE WHEN mgen.status_roll = 0 THEN N'reported' ELSE N'in_progress' END,
    NULL,
    N'out_of_service'
FROM mgen
JOIN numbered_users nu ON nu.rn = mgen.reporter_rn
JOIN numbered_spaces ns ON ns.rn = mgen.space_rn
JOIN staff_pool sp ON sp.rn = mgen.staff_rn;
GO

-- ============================================================================
-- 12. MAINTENANCE-BOOKING RESOLUTION — resolve the two overlap scenarios the
--     generator creates on purpose so the final dataset is fully consistent
--     with the Phase 2 business rules (BR-44, BR-46):
--
--     12.1 Out-of-service (BR-44): the open out-of-service records inserted
--          in Section 11 overlap existing reservations. Escalation (RC-04 /
--          RC-05) triggers staff contact (BR-48) and affected future
--          bookings are rescheduled, so every pending/approved booking that
--          overlaps an open out-of-service record is cancelled. Conducted
--          bookings (checked_in / completed / no_show) are historical fact
--          and are NOT cancelled; they remain the BR-48 staff-contact
--          scenario and are reported by the Section 14 M-1h check.
--     12.2 Advisory (BR-46): every effective booking overlapping an open
--          advisory record must record the requester acknowledgement. Wave-1
--          bookings were inserted before the advisories existed (BR-45
--          boundary), but the dataset is resolved to a single consistent
--          state by backfilling advisory_acknowledged = 1 for those bookings
--          (the acknowledgement is treated as captured at booking time).
--
--     Trigger safety: cancelling is exempt from
--     trg_bookings_br44_no_overlap_out_of_service (status NOT IN
--     (rejected, cancelled)); backfilling the acknowledgement satisfies
--     trg_bookings_br46_advisory_acknowledgement (advisory_acknowledged = 1).
--     Both updates therefore execute without violating the migration
--     triggers, and both are idempotent for repeated runs of this script.
-- ============================================================================

DECLARE @OutOfServiceCancelled INT;
DECLARE @AdvisoryAckBackfilled  INT;

-- 12.1 Cancel cancellable bookings overlapping open out-of-service records.
UPDATE b
SET b.status = N'cancelled'
FROM bookings b
WHERE b.status IN (N'pending', N'approved')
  AND EXISTS
  (
      SELECT 1 FROM maintenance_records m
       WHERE m.space_code = b.space_code
         AND m.impact_level = N'out_of_service'
         AND m.status IN (N'reported', N'in_progress')
         AND b.requested_end_time > m.start_time
         AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
  );

SET @OutOfServiceCancelled = @@ROWCOUNT;
PRINT N'Out-of-service resolution: cancelled ' + CAST(@OutOfServiceCancelled AS VARCHAR(10)) + N' overlapping booking(s).';

-- 12.2 Backfill the acknowledgement for effective bookings overlapping an
--     open advisory record (BR-46).
UPDATE b
SET b.advisory_acknowledged = 1
FROM bookings b
WHERE b.status NOT IN (N'cancelled', N'rejected')
  AND (b.advisory_acknowledged IS NULL OR b.advisory_acknowledged = 0)
  AND EXISTS
  (
      SELECT 1 FROM maintenance_records m
       WHERE m.space_code = b.space_code
         AND m.impact_level = N'advisory'
         AND m.status IN (N'reported', N'in_progress')
         AND b.requested_end_time > m.start_time
         AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
  );

SET @AdvisoryAckBackfilled = @@ROWCOUNT;
PRINT N'Advisory resolution: acknowledged ' + CAST(@AdvisoryAckBackfilled AS VARCHAR(10)) + N' overlapping booking(s).';
GO

-- ============================================================================
-- 13. OVERLAP RECONCILIATION — detect and resolve overlapping effective
--     bookings (BR-14 / BR-50 data-level cleanliness).
--     The generator is non-overlapping by construction (at most one booking
--     per space-day block per wave), so this pass is normally a no-op. It is
--     a safety net that visibly repairs any overlapping bookings that a future
--     edit to this script might introduce.
--
--     Resolution policy:
--       * Occupying statuses are all statuses except cancelled / rejected.
--       * Overlap is detected with a running maximum end time per space (a
--         window function, O(n log n), instead of an O(n^2) interval
--         self-join over ~126 000 bookings).
--       * When a later booking overlaps an earlier one, the LATER booking is
--         cancelled so the earliest reservation survives.
--       * Only bookings that can still realistically be cancelled are updated
--         (status pending / approved). Overlaps between already-conducted
--         bookings (checked_in / completed / no_show) are historical fact and
--         are reported by the Section 14 overlap check, not auto-cancelled.
--
--     Trigger safety: updating a booking to status 'cancelled' is exempt from
--     trg_bookings_br44_no_overlap_out_of_service (status NOT IN
--     (rejected, cancelled)) and does not re-trigger the BR-46 acknowledgement
--     check (the trigger only re-checks statuses pending / approved). Existing
--     approval rows reference their bookings via FK only; the approval of a
--     cancelled booking is a valid 'approved-then-cancelled' history, and
--     sessions only exist for conducted bookings, which are never selected
--     here.
-- ============================================================================

DECLARE @OverlapsCancelled INT;

UPDATE b
SET b.status = N'cancelled'
FROM bookings b
JOIN (
    SELECT booking_id
    FROM (
        SELECT
            booking_id,
            requested_start_time,
            MAX(requested_end_time) OVER (
                PARTITION BY space_code
                ORDER BY requested_start_time, booking_id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS max_prev_end
        FROM bookings
        WHERE status NOT IN (N'cancelled', N'rejected')
    ) t
    WHERE t.max_prev_end IS NOT NULL
      AND t.requested_start_time < t.max_prev_end
) o ON o.booking_id = b.booking_id
WHERE b.status IN (N'pending', N'approved');

SET @OverlapsCancelled = @@ROWCOUNT;

PRINT N'Overlap reconciliation: cancelled ' + CAST(@OverlapsCancelled AS VARCHAR(10)) + N' overlapping booking(s).';
GO

-- ============================================================================
-- 14. DATA INTEGRITY SUMMARY — counts and cross-checks
--     Targets (approximate): users 1500, spaces 40, facilities 18,
--     space_facilities ~150, bookings > 100 000, approvals ~116 000,
--     sessions ~72 000, maintenance ~3100.
-- ============================================================================

SELECT N'users'              AS relation, COUNT(*) AS row_count FROM users
UNION ALL SELECT N'spaces',              COUNT(*) FROM spaces
UNION ALL SELECT N'facilities',          COUNT(*) FROM facilities
UNION ALL SELECT N'space_facilities',    COUNT(*) FROM space_facilities
UNION ALL SELECT N'bookings',            COUNT(*) FROM bookings
UNION ALL SELECT N'approvals',           COUNT(*) FROM approvals
UNION ALL SELECT N'sessions',            COUNT(*) FROM sessions
UNION ALL SELECT N'maintenance_records', COUNT(*) FROM maintenance_records;

GO

-- Booking span check: must cover at least three academic years.
SELECT MIN(requested_start_time) AS earliest_booking,
       MAX(requested_end_time)   AS latest_booking,
       DATEDIFF(YEAR, MIN(requested_start_time), MAX(requested_start_time)) AS years_span
FROM bookings;
GO

-- Overlap check (BR-14 / BR-50 data-level realism): expect 0.
-- Section 13 cancels any overlapping pending/approved bookings beforehand;
-- the only overlaps this query could still find would be between historical
-- statuses (checked_in / completed / no_show), which the generator does not
-- produce.
-- Uses a window function (LAG) so the check is O(n log n) per space instead
-- of an O(n^2) self-join over ~126 000 bookings.
SELECT COUNT(*) AS overlapping_approved_bookings
FROM
(
    SELECT
        space_code,
        requested_start_time,
        requested_end_time,
        LAG(requested_end_time) OVER (
            PARTITION BY space_code ORDER BY requested_start_time
        ) AS prev_end
    FROM bookings
    WHERE status IN (N'approved', N'checked_in', N'completed', N'no_show')
) t
WHERE t.prev_end IS NOT NULL
  AND t.requested_start_time < t.prev_end;
GO

-- BR-46 data-level consistency, direction 1 (must be 0): every booking with
-- advisory_acknowledged = 1 must overlap an open advisory record, i.e. an
-- acknowledgement can never be recorded without an actual overlapping
-- advisory (mirrors trg_bookings_br46_advisory_acknowledgement).
-- Direction 2 (an effective booking overlapping an open advisory without the
-- acknowledgement) is asserted by the M-2 check below and must be 0: Wave-2
-- rows are acknowledged at insert time and Section 12.2 backfills every
-- remaining Wave-1 overlap.
SELECT COUNT(*) AS acks_without_advisory
FROM bookings b
WHERE b.advisory_acknowledged = 1
  AND NOT EXISTS
(
    SELECT 1 FROM maintenance_records m
     WHERE m.space_code = b.space_code
       AND m.impact_level = N'advisory'
       AND m.status IN (N'reported', N'in_progress')
       AND b.requested_end_time > m.start_time
       AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
);
GO

-- ============================================================================
-- Maintenance / booking conflict checks (BR-44, BR-45, BR-46, BR-34/BR-39)
-- ----------------------------------------------------------------------------
-- M-1a BR-44 resolution check (must be 0): no pending/approved booking may
--     overlap an open out-of-service record. Section 12.1 cancelled every
--     such booking; any row found here is a generator regression.
-- M-1h BR-48 historical report (NON-ZERO by design): conducted bookings
--     (checked_in / completed / no_show) overlapping an open out-of-service
--     record. These preceded the escalation (RC-04 / RC-05) and are surfaced
--     for staff contact, never retroactively cancelled.
-- M-2 BR-46 resolution check (must be 0): no effective booking may overlap an
--     open advisory record without advisory_acknowledged = 1. Wave-2 rows are
--     acknowledged at insert time and Section 12.2 backfills every remaining
--     overlap; any row found here is a generator regression.
-- M-4 BR-34/BR-39 internal consistency (must be 0): no completed record has
--     a missing or non-increasing completion_time, and no open record carries
--     a completion_time or result_note.
-- ============================================================================

-- M-1a (BR-44): unresolved cancellable bookings vs open out-of-service records.
SELECT COUNT(*) AS unresolved_out_of_service_overlaps
FROM bookings b
WHERE b.status IN (N'pending', N'approved')
  AND EXISTS
(
    SELECT 1 FROM maintenance_records m
     WHERE m.space_code = b.space_code
       AND m.impact_level = N'out_of_service'
       AND m.status IN (N'reported', N'in_progress')
       AND b.requested_end_time > m.start_time
       AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
);
GO

-- M-1h (BR-48): conducted bookings overlapping open out-of-service records
--     (historical fact; NON-ZERO expected by design).
SELECT COUNT(*) AS conducted_bookings_overlapping_out_of_service
FROM bookings b
WHERE b.status IN (N'checked_in', N'completed', N'no_show')
  AND EXISTS
(
    SELECT 1 FROM maintenance_records m
     WHERE m.space_code = b.space_code
       AND m.impact_level = N'out_of_service'
       AND m.status IN (N'reported', N'in_progress')
       AND b.requested_end_time > m.start_time
       AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
);
GO

-- M-2 (BR-46): effective bookings overlapping an open advisory without an
--     acknowledgement (expect 0 after the Section 12.2 resolution).
SELECT COUNT(*) AS overlapping_advisory_without_ack
FROM bookings b
WHERE b.status NOT IN (N'cancelled', N'rejected')
  AND (b.advisory_acknowledged IS NULL OR b.advisory_acknowledged = 0)
  AND EXISTS
(
    SELECT 1 FROM maintenance_records m
     WHERE m.space_code = b.space_code
       AND m.impact_level = N'advisory'
       AND m.status IN (N'reported', N'in_progress')
       AND b.requested_end_time > m.start_time
       AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
);
GO

-- M-4 (BR-34/BR-39): maintenance record lifecycle consistency.
SELECT COUNT(*) AS maintenance_lifecycle_violations
FROM maintenance_records
WHERE (status = N'completed'
       AND (completion_time IS NULL OR completion_time <= start_time))
   OR (status IN (N'reported', N'in_progress')
       AND (completion_time IS NOT NULL OR result_note IS NOT NULL));
GO

-- BR-NI-10: every approval decision must precede the booking start. Expect 0.
SELECT COUNT(*) AS approvals_after_booking_start
FROM approvals a
JOIN bookings b ON b.booking_id = a.booking_id
WHERE a.decision_time >= b.requested_start_time;
GO

-- BR-29: rejected approvals must always carry a rejection reason. Expect 0.
SELECT COUNT(*) AS rejected_without_reason
FROM approvals
WHERE decision = N'rejected' AND (rejection_reason IS NULL OR rejection_reason = N'');
GO

-- BR-NI-04 / BR-NI-11: approver must differ from requester. Expect 0.
SELECT COUNT(*) AS self_approvals
FROM approvals a
JOIN bookings b ON b.booking_id = a.booking_id
WHERE a.approver_id = b.requester_id;
GO

-- ============================================================================
-- 15. HARD REQUIREMENT VALIDATION — skill objective guards
--     At least 100 000 bookings across a minimum of 3 academic years.
--     Fails loudly if a future edit regresses either requirement.
-- ============================================================================

IF (SELECT COUNT(*) FROM bookings) < 100000
    THROW 51010, N'Data generator regression: fewer than 100 000 bookings were produced.', 1;
GO

IF DATEDIFF(YEAR,
            (SELECT MIN(requested_start_time) FROM bookings),
            (SELECT MAX(requested_start_time) FROM bookings)) < 3
    THROW 51011, N'Data generator regression: bookings span fewer than three academic years.', 1;
GO

-- Maintenance / booking conflict guards (Section 14, M-1a, M-2 and M-4).
-- M-1a: no pending/approved booking may overlap an open out-of-service
--      record (BR-44). Section 12.1 cancels them; a non-zero result means
--      the resolution pass is broken.
IF EXISTS
(
    SELECT 1 FROM bookings b
     WHERE b.status IN (N'pending', N'approved')
       AND EXISTS
       (
           SELECT 1 FROM maintenance_records m
            WHERE m.space_code = b.space_code
              AND m.impact_level = N'out_of_service'
              AND m.status IN (N'reported', N'in_progress')
              AND b.requested_end_time > m.start_time
              AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
       )
)
    THROW 51014, N'Data generator regression: a pending/approved booking overlaps an open out-of-service record (BR-44).', 1;
GO

-- M-2: no effective booking may overlap an open advisory record without
--      advisory_acknowledged = 1 (BR-46, BR-45).
IF EXISTS
(
    SELECT 1 FROM bookings b
     WHERE b.status NOT IN (N'cancelled', N'rejected')
       AND (b.advisory_acknowledged IS NULL OR b.advisory_acknowledged = 0)
       AND EXISTS
       (
           SELECT 1 FROM maintenance_records m
            WHERE m.space_code = b.space_code
              AND m.impact_level = N'advisory'
              AND m.status IN (N'reported', N'in_progress')
              AND b.requested_end_time > m.start_time
              AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
       )
)
    THROW 51012, N'Data generator regression: an effective booking overlaps an open advisory record without advisory_acknowledged = 1 (BR-46).', 1;
GO

-- M-4: maintenance record lifecycle must be consistent (BR-34/BR-39).
IF (SELECT COUNT(*)
      FROM maintenance_records
     WHERE (status = N'completed'
            AND (completion_time IS NULL OR completion_time <= start_time))
        OR (status IN (N'reported', N'in_progress')
            AND (completion_time IS NOT NULL OR result_note IS NOT NULL))) > 0
    THROW 51013, N'Data generator regression: maintenance record lifecycle violation (BR-34/BR-39).', 1;
GO

PRINT N'Data generator OK: booking count, academic-year span, and maintenance/booking resolution satisfy the requirements.';
GO

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
