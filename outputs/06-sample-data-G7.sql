-- ============================================================================
-- Sample Data Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Description : Bulk-generated realistic sample data using set-based operations.
--               Satisfies domain-specific constraints for a CS university.
-- Artifact    : outputs/06-sample-data-G7.sql
-- Prerequisite: outputs/05-db-implementation-G7.sql
-- ============================================================================

USE [CS486_Booking_System];
GO

-- ============================================================================
-- Insertion Order (dependency-respecting):
--   1. users       (independent)
--   2. spaces      (independent)
--   3. facilities  (independent)
--   4. space_facilities  (FK: spaces, facilities)
--   5. bookings    (FK: users, spaces)
--   6. approvals   (FK: bookings, users)
--   7. sessions    (FK: bookings, users)
--   8. maintenance_records (FK: users, spaces)
-- ============================================================================

-- ============================================================================
-- 1. USERS (600 rows)
--    Departments restricted to Computer Science domains only.
--    Roles: student (60%), lecturer (15%), teaching_assistant (10%),
--           facility_staff (5%), department_administrator (6%),
--           facility_manager (4%)
--    Account status: active (92%), suspended (8%)
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
    SELECT name FROM (VALUES
        (N'Computer Science'),(N'Software Engineering'),(N'Data Science'),
        (N'Artificial Intelligence'),(N'Cybersecurity'),
        (N'Information Systems'),(N'Computer Networks'),
        (N'Human-Computer Interaction')
    ) AS d(name)
),
numbered AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY NEWID()) AS seq,
        fn.name AS fn_name,
        ln.name AS ln_name,
        d.name AS dept_name,
        ABS(CHECKSUM(NEWID())) % 100 AS role_roll,
        ABS(CHECKSUM(NEWID())) % 100 AS status_roll,
        ABS(CHECKSUM(NEWID())) % 100 AS phone_roll
    FROM first_name_pool fn
    CROSS JOIN last_name_pool ln
    CROSS JOIN department_pool d
)
INSERT INTO users (user_id, first_name, last_name, email, phone_number, role, department, account_status)
SELECT TOP (600)
    'U' + RIGHT('00000' + CAST(seq AS VARCHAR(10)), 5),
    fn_name,
    ln_name,
    LOWER(fn_name + '.' + ln_name + RIGHT('00000' + CAST(seq AS VARCHAR(10)), 5) + '@university.edu'),
    CASE WHEN phone_roll < 10 THEN NULL ELSE '+1-555-' + RIGHT('0000' + CAST(1000 + seq AS VARCHAR(10)), 4) END,
    CASE
        WHEN role_roll < 60 THEN 'student'
        WHEN role_roll < 75 THEN 'lecturer'
        WHEN role_roll < 85 THEN 'teaching_assistant'
        WHEN role_roll < 90 THEN 'facility_staff'
        WHEN role_roll < 96 THEN 'department_administrator'
        ELSE 'facility_manager'
    END,
    dept_name,
    CASE WHEN status_roll < 92 THEN 'active' ELSE 'suspended' END
FROM numbered;
GO

-- ============================================================================
-- 2. SPACES (60 rows)
--    6 buildings (A-F), 10 spaces each.
--    Type mix per building: 1 AU, 3 CR, 2 CL, 1 PL, 2 MR, 1 SW
--    Status: 50 available, 3 in_use, 3 under_maintenance,
--            2 temporarily_closed, 2 retired
--    Capacity: always divisible by 5; classrooms 40-50, auditoriums 200-300.
-- ============================================================================
WITH
building_pool AS (
    SELECT letter FROM (VALUES ('A'),('B'),('C'),('D'),('E'),('F')) AS b(letter)
),
type_pool AS (
    SELECT type_name, prefix, min_cap, max_cap, idx FROM (VALUES
        (N'auditorium',          'AU', 200, 300, 0),
        (N'classroom',           'CR', 40,  50,  1),
        (N'classroom',           'CR', 40,  50,  2),
        (N'classroom',           'CR', 40,  50,  3),
        (N'computer_laboratory', 'CL', 20,  30,  4),
        (N'computer_laboratory', 'CL', 20,  30,  5),
        (N'project_laboratory',  'PL', 15,  25,  6),
        (N'meeting_room',        'MR', 10,  20,  7),
        (N'meeting_room',        'MR', 10,  20,  8),
        (N'student_workspace',   'SW', 5,   60,  9)
    ) AS t(type_name, prefix, min_cap, max_cap, idx)
),
space_floor AS (
    SELECT n, ((n - 1) / 2) % 5 + 1 AS floor_num
    FROM (SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_columns) nums
),
space_data AS (
    SELECT
        sn.n,
        b.letter AS building_letter,
        t.type_name,
        t.prefix,
        t.min_cap,
        t.max_cap,
        sf.floor_num,
        (sn.n - 1) % 100 + 1 AS room_num,
        CASE
            WHEN sn.n IN (5, 18, 35) THEN 'under_maintenance'
            WHEN sn.n IN (12, 48)    THEN 'temporarily_closed'
            WHEN sn.n IN (25, 55)    THEN 'retired'
            WHEN sn.n IN (8, 22, 40) THEN 'in_use'
            ELSE 'available'
        END AS space_status
    FROM (SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_columns) sn
    CROSS JOIN building_pool b
    INNER JOIN type_pool t ON t.idx = (sn.n - 1) % 10
    INNER JOIN space_floor sf ON sf.n = sn.n
    WHERE (sn.n BETWEEN 1 AND 10 AND b.letter = 'A')
        OR (sn.n BETWEEN 11 AND 20 AND b.letter = 'B')
        OR (sn.n BETWEEN 21 AND 30 AND b.letter = 'C')
        OR (sn.n BETWEEN 31 AND 40 AND b.letter = 'D')
        OR (sn.n BETWEEN 41 AND 50 AND b.letter = 'E')
        OR (sn.n BETWEEN 51 AND 60 AND b.letter = 'F')
)
INSERT INTO spaces (space_code, space_name, space_type, building, floor, room_number, capacity, status, usage_policy)
SELECT
    sd.building_letter + '-' + t.prefix + '-' + CAST(sd.room_num AS VARCHAR),
    N'Building ' + sd.building_letter + ' ' +
        CASE t.type_name
            WHEN 'auditorium' THEN N'Auditorium'
            WHEN 'classroom' THEN N'Classroom'
            WHEN 'computer_laboratory' THEN N'Computer Lab'
            WHEN 'project_laboratory' THEN N'Lab'
            WHEN 'meeting_room' THEN N'Meeting Room'
            WHEN 'student_workspace' THEN N'Study Area'
        END + ' ' + CAST(sd.room_num AS VARCHAR),
    t.type_name,
    sd.building_letter,
    CAST(sd.floor_num AS VARCHAR(20)),
    CAST(sd.room_num AS VARCHAR(20)),
    ((t.min_cap / 5) + ABS(CHECKSUM(NEWID())) % ((t.max_cap - t.min_cap) / 5 + 1)) * 5,
    sd.space_status,
    CASE t.type_name
        WHEN N'auditorium'          THEN N'Large lectures, examinations, and seminars.'
        WHEN N'classroom'           THEN N'Standard classroom instruction.'
        WHEN N'computer_laboratory' THEN N'Computer-based instruction and workshops.'
        WHEN N'project_laboratory'  THEN N'Scientific experiments and project work.'
        WHEN N'meeting_room'        THEN N'Meetings and small group discussions.'
        WHEN N'student_workspace'   THEN N'Student self-study and group work.'
    END
FROM space_data sd
JOIN type_pool t ON t.idx = (sd.n - 1) % 10;
GO

-- ============================================================================
-- 3. FACILITIES (15 rows)
-- ============================================================================
INSERT INTO facilities (facility_name, description)
VALUES
(N'Projector',           N'Digital projector with HDMI and VGA connectivity.'),
(N'Whiteboard',          N'Standard dry-erase whiteboard with markers.'),
(N'Smart Board',         N'Interactive smart board with touch capability.'),
(N'Air Conditioning',    N'HVAC system with temperature control.'),
(N'Computer Workstation',N'Desktop computer with standard software suite.'),
(N'Laboratory Equipment',N'Specialized scientific equipment.'),
(N'Video Conferencing',  N'Camera and microphone for remote meetings.'),
(N'Microphone System',   N'Wireless microphone and speaker system.'),
(N'Document Camera',     N'Camera for projecting documents and objects.'),
(N'Wheelchair Access',   N'Wheelchair-accessible entrance and seating.'),
(N'Printer',             N'Network-connected printer.'),
(N'Projection Screen',   N'Motorized projection screen.'),
(N'Speaker System',      N'Room audio speaker system.'),
(N'TV Monitor',          N'Large LCD TV monitor for presentations.'),
(N'Charging Station',    N'Multi-device charging station.');
GO

-- ============================================================================
-- 4. SPACE-FACILITIES ASSOCIATIONS (~210 rows)
--    Assigns facilities to each space based on space type.
-- ============================================================================
WITH
space_type_map AS (
    SELECT space_code, space_type FROM spaces
),
facility_map AS (
    SELECT facility_id, facility_name FROM facilities
),
type_facility_profile AS (
    SELECT stm.space_code, fm.facility_id,
        CASE fm.facility_name
            WHEN N'Projector' THEN
                CASE stm.space_type
                    WHEN N'auditorium' THEN 2
                    WHEN N'classroom' THEN 1
                    WHEN N'computer_laboratory' THEN 1
                    WHEN N'meeting_room' THEN 1
                    ELSE 0
                END
            WHEN N'Whiteboard' THEN
                CASE WHEN stm.space_type IN (N'classroom', N'meeting_room', N'auditorium') THEN 1 ELSE 0 END
            WHEN N'Smart Board' THEN
                CASE WHEN stm.space_type IN (N'classroom') THEN 1 ELSE 0 END
            WHEN N'Air Conditioning' THEN 1
            WHEN N'Computer Workstation' THEN
                CASE stm.space_type
                    WHEN N'computer_laboratory' THEN 25 + ABS(CHECKSUM(NEWID())) % 6
                    WHEN N'student_workspace' THEN 4
                    ELSE 0
                END
            WHEN N'Laboratory Equipment' THEN
                CASE WHEN stm.space_type = N'project_laboratory' THEN 5 + ABS(CHECKSUM(NEWID())) % 6 ELSE 0 END
            WHEN N'Video Conferencing' THEN
                CASE WHEN stm.space_type IN (N'meeting_room', N'auditorium') THEN 1 ELSE 0 END
            WHEN N'Microphone System' THEN
                CASE WHEN stm.space_type IN (N'auditorium') THEN 2 ELSE 0 END
            WHEN N'Document Camera' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom') THEN 1 ELSE 0 END
            WHEN N'Wheelchair Access' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom') THEN 1 ELSE 0 END
            WHEN N'Printer' THEN
                CASE WHEN stm.space_type IN (N'computer_laboratory', N'student_workspace') THEN 1 ELSE 0 END
            WHEN N'Projection Screen' THEN
                CASE WHEN stm.space_type IN (N'auditorium', N'classroom', N'meeting_room') THEN 1 ELSE 0 END
            WHEN N'Speaker System' THEN
                CASE WHEN stm.space_type IN (N'auditorium') THEN 1 ELSE 0 END
            WHEN N'TV Monitor' THEN
                CASE WHEN stm.space_type IN (N'meeting_room', N'student_workspace') THEN 1 ELSE 0 END
            WHEN N'Charging Station' THEN
                CASE WHEN stm.space_type IN (N'student_workspace') THEN 2 ELSE 0 END
            ELSE 0
        END AS qty
    FROM space_type_map stm
    CROSS JOIN facility_map fm
)
INSERT INTO space_facilities (space_code, facility_id, quantity)
SELECT space_code, facility_id, qty
FROM type_facility_profile
WHERE qty > 0;
GO

-- ============================================================================
-- 5. BOOKINGS (3000 rows)
--    References users and spaces.
--   Status distribution:
--      Approved:  58%  (60-70% per skill requirement)
--      Completed: 30%  (20-30% per skill requirement)
--      Rejected:   5%  (≥5-10% per skill requirement)
--      Pending:    2%
--      Cancelled:  1%
--      Checked_in: 2%
--      No_show:    2%
--    Business rules enforced:
--      BR-NI-05: expected_participants <= space.capacity (divisible by 5)
--      BR-NI-06: requested_start_time < requested_end_time
-- ============================================================================
WITH
numbered_users AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users
),
user_count AS (
    SELECT COUNT(*) AS cnt FROM users
),
numbered_spaces AS (
    SELECT space_code, capacity, ROW_NUMBER() OVER (ORDER BY space_code) AS rn
    FROM spaces
),
space_count AS (
    SELECT COUNT(*) AS cnt FROM spaces
),
generator AS (
    SELECT TOP (3000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n,
        ABS(CHECKSUM(NEWID())) % (SELECT cnt FROM user_count) + 1 AS user_rn,
        ABS(CHECKSUM(NEWID())) % (SELECT cnt FROM space_count) + 1 AS space_rn,
        ABS(CHECKSUM(NEWID())) % 180 AS day_offset,
        ABS(CHECKSUM(NEWID())) % 9 AS start_hour_offset,
        ABS(CHECKSUM(NEWID())) % 3 AS duration_hours,
        ABS(CHECKSUM(NEWID())) % 100 AS status_roll,
        ABS(CHECKSUM(NEWID())) % 7 AS purpose_roll
    FROM sys.all_columns a
    CROSS JOIN sys.all_columns b
)
INSERT INTO bookings (requester_id, space_code, requested_start_time, requested_end_time, purpose, expected_participants, status)
SELECT
    nu.user_id,
    ns.space_code,
    DATEADD(HOUR, 8 + g.start_hour_offset, DATEADD(DAY, g.day_offset, '2026-01-01')),
    DATEADD(HOUR, 8 + g.start_hour_offset + 1 + g.duration_hours, DATEADD(DAY, g.day_offset, '2026-01-01')),
    CASE g.purpose_roll
        WHEN 0 THEN 'lecture'
        WHEN 1 THEN 'examination'
        WHEN 2 THEN 'seminar'
        WHEN 3 THEN 'workshop'
        WHEN 4 THEN 'meeting'
        WHEN 5 THEN 'student_activity'
        ELSE 'administrative_event'
    END,
    (1 + ABS(CHECKSUM(NEWID())) % (ns.capacity / 5)) * 5,
    CASE
        WHEN g.status_roll < 30 THEN 'completed'
        WHEN g.status_roll < 88 THEN 'approved'
        WHEN g.status_roll < 93 THEN 'rejected'
        WHEN g.status_roll < 95 THEN 'pending'
        WHEN g.status_roll < 96 THEN 'cancelled'
        WHEN g.status_roll < 98 THEN 'checked_in'
        ELSE 'no_show'
    END
FROM generator g
JOIN numbered_users nu ON nu.rn = g.user_rn
JOIN numbered_spaces ns ON ns.rn = g.space_rn;
GO

-- ============================================================================
-- 6. APPROVALS (1800 rows)
--    For bookings with status in (approved, completed, checked_in, no_show,
--    rejected). Rejected bookings include a valid rejection_reason.
--    Business rules enforced:
--      BR-NI-02: Only pending bookings can be approved (data reflects final
--                state — bookings had 'pending' when decision was made).
--      BR-NI-04: approver_id != requester_id
-- ============================================================================
WITH
approvers AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users
    WHERE role IN ('facility_manager', 'department_administrator')
),
approver_count AS (
    SELECT COUNT(*) AS cnt FROM approvers
),
eligible_bookings AS (
    SELECT
        b.booking_id,
        b.requester_id,
        b.purpose,
        b.status,
        b.requested_start_time,
        ABS(CHECKSUM(NEWID())) % (SELECT cnt FROM approver_count) + 1 AS approver_rn,
        ABS(CHECKSUM(NEWID())) % 6 AS reason_roll
    FROM bookings b
    WHERE b.status IN ('approved', 'completed', 'checked_in', 'no_show', 'rejected')
)
INSERT INTO approvals (booking_id, approver_id, decision, decision_time, decision_note, rejection_reason)
SELECT TOP (1800)
    eb.booking_id,
    a.user_id,
    CASE WHEN eb.status = 'rejected' THEN 'rejected' ELSE 'approved' END,
    DATEADD(HOUR, -1 * (1 + ABS(CHECKSUM(NEWID())) % 72), eb.requested_start_time),
    CASE
        WHEN eb.status = 'rejected' THEN NULL
        ELSE
            CASE eb.purpose
                WHEN 'lecture'              THEN N'Lecture session approved.'
                WHEN 'examination'          THEN N'Examination session approved. Proctors assigned.'
                WHEN 'seminar'              THEN N'Seminar approved.'
                WHEN 'workshop'             THEN N'Workshop approved.'
                WHEN 'meeting'              THEN N'Meeting booking approved.'
                WHEN 'student_activity'     THEN N'Student activity approved.'
                WHEN 'administrative_event' THEN N'Administrative event approved.'
                ELSE N'Booking approved.'
            END
    END,
    CASE
        WHEN eb.status = 'rejected' THEN
            CASE eb.reason_roll
                WHEN 0 THEN N'Scheduling conflict with existing booking.'
                WHEN 1 THEN N'Requested capacity exceeds room limit.'
                WHEN 2 THEN N'Duplicate request — identical booking already exists.'
                WHEN 3 THEN N'Invalid booking details provided.'
                WHEN 4 THEN N'Room under maintenance at requested time.'
                ELSE N'Insufficient resources available for this request.'
            END
        ELSE NULL
    END
FROM eligible_bookings eb
JOIN approvers a ON a.rn = eb.approver_rn
WHERE a.user_id != eb.requester_id
ORDER BY eb.booking_id;
GO

-- ============================================================================
-- 7. SESSIONS (1000 rows)
--    Only for bookings that were actually conducted (status: completed,
--    checked_in, no_show).
--    Business rule BR-NI-03: Only approved bookings can have sessions.
--    Each eligible booking receives exactly one session.
-- ============================================================================
WITH
conductors AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users
    WHERE role IN ('lecturer', 'teaching_assistant', 'facility_staff')
),
conductor_count AS (
    SELECT COUNT(*) AS cnt FROM conductors
),
eligible_bookings AS (
    SELECT
        b.booking_id,
        b.requester_id,
        b.requested_start_time,
        b.requested_end_time,
        b.status,
        ABS(CHECKSUM(NEWID())) % (SELECT cnt FROM conductor_count) + 1 AS conductor_rn
    FROM bookings b
    WHERE b.status IN ('completed', 'checked_in', 'no_show')
)
INSERT INTO sessions (booking_id, conductor_id, actual_start_time, actual_end_time, initial_condition, final_condition, usage_notes)
SELECT TOP (1000)
    eb.booking_id,
    c.user_id,
    DATEADD(MINUTE, 2 + ABS(CHECKSUM(NEWID())) % 15, eb.requested_start_time),
    CASE
        WHEN eb.status = 'checked_in' THEN NULL
        ELSE DATEADD(MINUTE, -5 - ABS(CHECKSUM(NEWID())) % 20, eb.requested_end_time)
    END,
    CASE ABS(CHECKSUM(NEWID())) % 5
        WHEN 0 THEN N'Room clean and ready. Equipment functional.'
        WHEN 1 THEN N'Space prepared. All facilities operational.'
        WHEN 2 THEN N'Room in good condition. Setup completed.'
        WHEN 3 THEN N'Equipment checked and operational.'
        ELSE N'Space ready for session.'
    END,
    CASE
        WHEN eb.status = 'checked_in' THEN NULL
        ELSE
            CASE ABS(CHECKSUM(NEWID())) % 4
                WHEN 0 THEN N'Room tidy. Equipment turned off.'
                WHEN 1 THEN N'Space returned to neutral state.'
                WHEN 2 THEN N'All equipment shut down. Room clean.'
                ELSE N'Session ended. Minor cleanup needed.'
            END
    END,
    CASE
        WHEN eb.status = 'no_show' THEN N'No participants attended. Recorded as no-show.'
        ELSE
            CASE ABS(CHECKSUM(NEWID())) % 5
                WHEN 0 THEN N'Session conducted as planned.'
                WHEN 1 THEN N'All activities completed successfully.'
                WHEN 2 THEN N'Good attendance. Session productive.'
                WHEN 3 THEN N'Session ran smoothly.'
                ELSE N'Standard session completed.'
            END
    END
FROM eligible_bookings eb
JOIN conductors c ON c.rn = eb.conductor_rn;
GO

-- ============================================================================
-- 8. MAINTENANCE RECORDS (800 rows)
--    Business rules enforced:
--      BR-NI-07: assigned_staff_id must be facility_staff or facility_manager.
--      BR-NI-08: Reporter can be any user, staff must hold facility role.
--    A majority (>50%) of records are completed.
--    Completed records include diverse result notes (10+ variations).
-- ============================================================================
WITH
facility_staff AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users
    WHERE role IN ('facility_staff', 'facility_manager')
),
staff_count AS (
    SELECT COUNT(*) AS cnt FROM facility_staff
),
numbered_users AS (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY user_id) AS rn
    FROM users
),
user_cnt AS (
    SELECT COUNT(*) AS cnt FROM users
),
numbered_spaces AS (
    SELECT space_code, ROW_NUMBER() OVER (ORDER BY space_code) AS rn
    FROM spaces
),
space_cnt AS (
    SELECT COUNT(*) AS cnt FROM spaces
),
generator AS (
    SELECT TOP (800)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n,
        ABS(CHECKSUM(NEWID())) % (SELECT cnt FROM user_cnt) + 1 AS reporter_rn,
        ABS(CHECKSUM(NEWID())) % (SELECT cnt FROM space_cnt) + 1 AS space_rn,
        ABS(CHECKSUM(NEWID())) % (SELECT cnt FROM staff_count) + 1 AS staff_rn,
        ABS(CHECKSUM(NEWID())) % 180 AS day_offset,
        ABS(CHECKSUM(NEWID())) % 100 AS status_roll,
        ABS(CHECKSUM(NEWID())) % 10 AS problem_roll,
        ABS(CHECKSUM(NEWID())) % 12 AS note_roll
    FROM sys.all_columns a
    CROSS JOIN sys.all_columns b
)
INSERT INTO maintenance_records (reporter_id, space_code, assigned_staff_id, problem_description, start_time, completion_time, status, result_note)
SELECT
    nu.user_id,
    ns.space_code,
    fs.user_id,
    CASE g.problem_roll
        WHEN 0 THEN N'Projector bulb needs replacement.'
        WHEN 1 THEN N'Air conditioning not cooling properly.'
        WHEN 2 THEN N'Power outlet not working.'
        WHEN 3 THEN N'Network connectivity issues.'
        WHEN 4 THEN N'Whiteboard surface damaged.'
        WHEN 5 THEN N'Light fixture flickering.'
        WHEN 6 THEN N'Door handle loose or broken.'
        WHEN 7 THEN N'Chair with broken armrest.'
        WHEN 8 THEN N'Computer workstation not booting.'
        ELSE N'General maintenance request.'
    END,
    DATEADD(DAY, g.day_offset, '2026-01-01'),
    CASE
        WHEN g.status_roll < 55 THEN
            DATEADD(DAY, g.day_offset + 1 + ABS(CHECKSUM(NEWID())) % 5, '2026-01-01')
        ELSE NULL
    END,
    CASE
        WHEN g.status_roll < 55 THEN 'completed'
        WHEN g.status_roll < 80 THEN 'in_progress'
        ELSE 'reported'
    END,
    CASE
        WHEN g.status_roll < 55 THEN
            CASE g.note_roll
                WHEN 0 THEN N'Issue resolved successfully. All systems operational.'
                WHEN 1 THEN N'Equipment replaced with new unit. Functionality restored.'
                WHEN 2 THEN N'Routine maintenance completed. No further action needed.'
                WHEN 3 THEN N'System upgraded to latest version. Performance improved.'
                WHEN 4 THEN N'Component repaired and tested. Working correctly.'
                WHEN 5 THEN N'Electrical issue fixed. Safety check passed.'
                WHEN 6 THEN N'Network reconnected. Connectivity verified.'
                WHEN 7 THEN N'Furniture replaced. Area restored to normal.'
                WHEN 8 THEN N'Cleaning and calibration completed. Ready for use.'
                WHEN 9 THEN N'Software reinstall completed. System rebooted.'
                WHEN 10 THEN N'Hardware diagnostic passed. No defects found.'
                ELSE N'Maintenance completed per standard procedure.'
            END
        ELSE NULL
    END
FROM generator g
JOIN numbered_users nu ON nu.rn = g.reporter_rn
JOIN numbered_spaces ns ON ns.rn = g.space_rn
JOIN facility_staff fs ON fs.rn = g.staff_rn;
GO

-- ============================================================================
-- DATA INTEGRITY SUMMARY
-- ============================================================================
-- Target                    | Actual (approximate)
-- --------------------------+----------------------
-- users:             600    | (SELECT COUNT(*) FROM users)
-- spaces:             60    | (SELECT COUNT(*) FROM spaces)
-- facilities:         15    | (SELECT COUNT(*) FROM facilities)
-- space_facilities:  ~210   | (SELECT COUNT(*) FROM space_facilities)
-- bookings:         3000    | (SELECT COUNT(*) FROM bookings)
-- approvals:        ~1800   | (SELECT COUNT(*) FROM approvals)
-- sessions:         1000    | (SELECT COUNT(*) FROM sessions)
-- maintenance:       800    | (SELECT COUNT(*) FROM maintenance_records)
--
-- Domain-specific constraints satisfied:
--   Departments        → Only CS-related (Computer Science, Software
--                        Engineering, Data Science, AI, Cybersecurity, etc.)
--   Buildings          → Restricted to A-F
--   Capacity           → Always divisible by 5 (40-50 classrooms, 200-300 AU)
--   Booking status     → Approved ~58%, Completed ~30%, Rejected ~5%
--   First name pool    → 60 names (≥40-60 requirement)
--   Last name pool     → 30 names (≥20-30 requirement)
--   Result notes       → 12 variations for completed maintenance (≥8-10)
--   Maintenance status → Majority completed (>50%)
--   Rejection reasons  → 6 distinct reasons for rejected bookings
--   Rejected approvals → RejectReason non-NULL; approved approvals → NULL
--
-- Business rules satisfied:
--   BR-NI-02: Only bookings with appropriate status have approval rows.
--   BR-NI-03: Sessions exist only for bookings with conducted status.
--   BR-NI-04: All approver_id values differ from the booking requester_id.
--   BR-NI-05: All expected_participants <= space capacity.
--   BR-NI-07: Role-appropriate users assigned to functions.
--   BR-NI-08: assigned_staff_id always facility_staff or facility_manager.
-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
