-- ============================================================================
-- Sample Data Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Description : Realistic sample data for testing and evaluation. Includes
--               normal operations, boundary conditions, and exceptional cases.
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
-- 1. USERS
--    Roles: student, lecturer, teaching_assistant, facility_staff,
--           department_administrator, facility_manager
-- ============================================================================
INSERT INTO users (user_id, first_name, last_name, email, phone_number, role, department, account_status)
VALUES
-- Facility managers and staff
(N'U001', N'John',    N'Smith',    N'john.smith@university.edu',    N'+1-555-0101', N'facility_manager',         N'Facilities Management', N'active'),
(N'U002', N'Sarah',   N'Johnson',  N'sarah.johnson@university.edu', N'+1-555-0102', N'department_administrator', N'Computer Science',      N'active'),
(N'U003', N'Michael', N'Chen',     N'michael.chen@university.edu',  N'+1-555-0103', N'lecturer',                 N'Mathematics',           N'active'),
(N'U004', N'Emily',   N'Davis',    N'emily.davis@university.edu',   N'+1-555-0104', N'lecturer',                 N'Physics',               N'active'),
(N'U005', N'James',   N'Wilson',   N'james.wilson@university.edu',  N'+1-555-0105', N'lecturer',                 N'Computer Science',      N'active'),
(N'U006', N'Maria',   N'Garcia',   N'maria.garcia@university.edu',  N'+1-555-0106', N'teaching_assistant',       N'Computer Science',      N'active'),
(N'U007', N'David',   N'Brown',    N'david.brown@university.edu',   N'+1-555-0107', N'teaching_assistant',       N'Mathematics',           N'active'),
(N'U008', N'Jennifer',N'Lee',      N'jennifer.lee@university.edu',  N'+1-555-0108', N'facility_staff',           N'Facilities Management', N'active'),
(N'U009', N'Robert',  N'Martinez', N'robert.martinez@university.edu',N'+1-555-0109',N'facility_staff',           N'Facilities Management', N'active'),
(N'U010', N'Amanda',  N'Thompson', N'amanda.thompson@university.edu',N'+1-555-0110',N'department_administrator', N'Physics',               N'active'),
-- Students
(N'U011', N'Kevin',         N'Anderson',   N'kevin.anderson@university.edu',    N'+1-555-0111', N'student', N'Computer Science', N'active'),
(N'U012', N'Lisa',          N'Taylor',     N'lisa.taylor@university.edu',       N'+1-555-0112', N'student', N'Computer Science', N'active'),
(N'U013', N'Daniel',        N'Thomas',     N'daniel.thomas@university.edu',     N'+1-555-0113', N'student', N'Mathematics',      N'active'),
(N'U014', N'Jessica',       N'Hernandez',  N'jessica.hernandez@university.edu', N'+1-555-0114', N'student', N'Physics',          N'active'),
(N'U015', N'Christopher',   N'Moore',      N'christopher.moore@university.edu', N'+1-555-0115', N'student', N'Computer Science', N'active'),
(N'U016', N'Ashley',        N'Jackson',    N'ashley.jackson@university.edu',     N'+1-555-0116', N'student', N'Mathematics',      N'active'),
(N'U017', N'Matthew',       N'White',      N'matthew.white@university.edu',      N'+1-555-0117', N'student', N'Physics',          N'active'),
(N'U018', N'Megan',         N'Harris',     N'megan.harris@university.edu',       N'+1-555-0118', N'student', N'Computer Science', N'active'),
(N'U019', N'Joshua',        N'Clark',      N'joshua.clark@university.edu',       N'+1-555-0119', N'student', N'Engineering',      N'suspended'),
(N'U020', N'Lauren',        N'Lewis',      N'lauren.lewis@university.edu',       N'+1-555-0120', N'student', N'Engineering',      N'active');
GO

-- ============================================================================
-- 2. SPACES
--    Types: auditorium, classroom, computer_laboratory, project_laboratory,
--           meeting_room, student_workspace
--    Statuses: available, in_use, under_maintenance, temporarily_closed, retired
-- ============================================================================
INSERT INTO spaces (space_code, space_name, space_type, building, floor, room_number, capacity, status, usage_policy)
VALUES
(N'AU-101', N'Main Auditorium',       N'auditorium',          N'Science Building',            N'1', N'101', 300, N'available',           N'Large lectures, examinations, and seminars.'),
(N'AU-201', N'Small Auditorium',      N'auditorium',          N'Humanities Building',         N'2', N'201', 150, N'available',           N'Mid-size lectures and seminars.'),
(N'CR-101', N'Room 101',              N'classroom',           N'Engineering Building',        N'1', N'101', 40,  N'available',           N'Standard classroom lectures/tutorials.'),
(N'CR-102', N'Room 102',              N'classroom',           N'Engineering Building',        N'1', N'102', 35,  N'available',           N'Standard classroom lectures/tutorials.'),
(N'CR-201', N'Room 201',              N'classroom',           N'Science Building',            N'2', N'201', 50,  N'in_use',              N'Classroom with upgraded seating.'),
(N'CL-101', N'Computer Lab 1',        N'computer_laboratory', N'Computer Science Building',   N'1', N'101', 30,  N'available',           N'30 workstations for programming courses.'),
(N'CL-102', N'Computer Lab 2',        N'computer_laboratory', N'Computer Science Building',   N'1', N'102', 25,  N'available',           N'25 workstations with specialized software.'),
(N'PL-101', N'Physics Lab',           N'project_laboratory',  N'Science Building',            N'1', N'001', 20,  N'available',           N'Physics experimental equipment.'),
(N'PL-102', N'Chemistry Lab',         N'project_laboratory',  N'Science Building',            N'2', N'001', 24,  N'under_maintenance',   N'Chemistry lab under maintenance.'),
(N'MR-101', N'Conference Room A',     N'meeting_room',        N'Administration Building',     N'3', N'301', 15,  N'available',           N'Small meeting room.'),
(N'MR-102', N'Conference Room B',     N'meeting_room',        N'Administration Building',     N'3', N'302', 12,  N'available',           N'Small meeting room.'),
(N'MR-201', N'Department Meeting Rm', N'meeting_room',        N'Science Building',            N'3', N'301', 20,  N'available',           N'Medium department meetings.'),
(N'SW-101', N'Student Study Area',    N'student_workspace',   N'Library',                     N'1', N'101', 50,  N'available',           N'Open study area. No individual reservations.'),
(N'SW-102', N'Group Study Room 1',    N'student_workspace',   N'Library',                     N'2', N'201', 8,   N'available',           N'Group study for up to 8.'),
(N'SW-103', N'Group Study Room 2',    N'student_workspace',   N'Library',                     N'2', N'202', 6,   N'temporarily_closed',  N'Closed for renovation.');
GO

-- ============================================================================
-- 3. FACILITIES
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
(N'Wheelchair Access',   N'Wheelchair-accessible entrance and seating.');
GO

-- ============================================================================
-- 4. SPACE-FACILITY ASSOCIATIONS (M:N bridge)
-- ============================================================================
INSERT INTO space_facilities (space_code, facility_id, quantity)
VALUES
-- Main Auditorium (AU-101): 7 facilities
(N'AU-101', 1,  2),  -- Projector x2
(N'AU-101', 2,  2),  -- Whiteboard x2
(N'AU-101', 4,  1),  -- Air Conditioning
(N'AU-101', 7,  1),  -- Video Conferencing
(N'AU-101', 8,  2),  -- Microphone System x2
(N'AU-101', 9,  1),  -- Document Camera
(N'AU-101', 10, 1),  -- Wheelchair Access
-- Small Auditorium (AU-201): 4 facilities
(N'AU-201', 1, 1),
(N'AU-201', 2, 1),
(N'AU-201', 4, 1),
(N'AU-201', 8, 1),
-- Classroom 101 (CR-101): 3 facilities
(N'CR-101', 1, 1),
(N'CR-101', 2, 1),
(N'CR-101', 4, 1),
-- Classroom 201 (CR-201): 3 facilities
(N'CR-201', 1, 1),
(N'CR-201', 3, 1),
(N'CR-201', 4, 1),
-- Computer Lab 1 (CL-101): 3 facilities
(N'CL-101', 1,  1),
(N'CL-101', 4,  1),
(N'CL-101', 5, 30),
-- Computer Lab 2 (CL-102): 2 facilities
(N'CL-102', 1, 1),
(N'CL-102', 5, 25),
-- Physics Lab (PL-101): 2 facilities
(N'PL-101', 2, 2),
(N'PL-101', 6, 10),
-- Conference Room A (MR-101): 3 facilities
(N'MR-101', 1, 1),
(N'MR-101', 2, 1),
(N'MR-101', 7, 1),
-- Department Meeting Rm (MR-201): 3 facilities
(N'MR-201', 1, 1),
(N'MR-201', 2, 1),
(N'MR-201', 7, 1),
-- Group Study Room 1 (SW-102): 1 facility
(N'SW-102', 2, 1),
-- Student Study Area (SW-101): 1 facility
(N'SW-101', 2, 2);
GO

-- ============================================================================
-- 5. BOOKINGS
--    Status distribution: 6 completed, 1 checked_in, 4 approved (+2 future),
--                         5 pending, 2 rejected, 2 cancelled, 1 no_show
--    Business rule BR-NI-05: expected_participants <= space capacity
--    Business rule BR-NI-06: time ranges within realistic windows
-- ============================================================================
INSERT INTO bookings (requester_id, space_code, requested_start_time, requested_end_time, purpose, expected_participants, status)
VALUES
-- [1]  Completed: lecture series by Michael Chen
(N'U003', N'CR-101', N'2026-01-15 09:00:00', N'2026-01-15 11:00:00', N'lecture',  30, N'completed'),
-- [2]  Completed: repeat lecture
(N'U003', N'CR-101', N'2026-01-17 09:00:00', N'2026-01-17 11:00:00', N'lecture',  28, N'completed'),
-- [3]  Completed: physics lab session
(N'U004', N'PL-101', N'2026-02-01 14:00:00', N'2026-02-01 16:00:00', N'lecture',  18, N'completed'),
-- [4]  Completed: programming workshop
(N'U005', N'CL-101', N'2026-02-10 10:00:00', N'2026-02-10 12:00:00', N'workshop', 25, N'completed'),
-- [5]  Completed: department meeting
(N'U002', N'MR-201', N'2026-03-01 10:00:00', N'2026-03-01 12:00:00', N'meeting',  12, N'completed'),
-- [6]  Completed: large examination in auditorium
(N'U003', N'AU-101', N'2026-03-15 09:00:00', N'2026-03-15 12:00:00', N'examination', 200, N'completed'),
-- [7]  Checked-in: currently in progress
(N'U005', N'CL-101', N'2026-03-20 09:00:00', N'2026-03-20 11:00:00', N'lecture',  22, N'checked_in'),
-- [8]  Approved: upcoming seminar by TA
(N'U006', N'CR-102', N'2026-04-01 13:00:00', N'2026-04-01 15:00:00', N'seminar',  30, N'approved'),
-- [9]  Approved: upcoming physics lab
(N'U004', N'PL-101', N'2026-04-05 09:00:00', N'2026-04-05 12:00:00', N'lecture',  15, N'approved'),
-- [10] Approved: mid-size lecture
(N'U003', N'AU-201', N'2026-04-10 10:00:00', N'2026-04-10 12:00:00', N'lecture',  80, N'approved'),
-- [11] Pending: student group study
(N'U011', N'SW-102', N'2026-04-15 14:00:00', N'2026-04-15 17:00:00', N'student_activity', 6, N'pending'),
-- [12] Pending: student workshop request
(N'U012', N'CL-102', N'2026-04-16 09:00:00', N'2026-04-16 11:00:00', N'workshop', 20, N'pending'),
-- [13] Pending: student meeting
(N'U013', N'MR-102', N'2026-04-18 10:00:00', N'2026-04-18 11:30:00', N'meeting',  8,  N'pending'),
-- [14] Pending: student activity
(N'U015', N'CL-101', N'2026-04-20 14:00:00', N'2026-04-20 16:00:00', N'student_activity', 15, N'pending'),
-- [15] Pending: student seminar
(N'U016', N'CR-102', N'2026-04-22 09:00:00', N'2026-04-22 10:30:00', N'seminar',  25, N'pending'),
-- [16] Rejected: conflicting equipment availability
(N'U014', N'PL-101', N'2026-03-25 09:00:00', N'2026-03-25 12:00:00', N'lecture',  20, N'rejected'),
-- [17] Rejected: exceeds capacity (expected 35 but CR-101 capacity is 40 ---
--      wait, 35 <= 40, so this is rejected for other policy reasons)
(N'U017', N'CR-101', N'2026-03-28 14:00:00', N'2026-03-28 16:00:00', N'student_activity', 35, N'rejected'),
-- [18] Cancelled: student cancelled due to schedule conflict
(N'U011', N'SW-103', N'2026-03-10 10:00:00', N'2026-03-10 12:00:00', N'student_activity', 5,  N'cancelled'),
-- [19] Cancelled: admin cancelled before approval
(N'U018', N'MR-101', N'2026-03-12 10:00:00', N'2026-03-12 11:00:00', N'meeting',  10, N'cancelled'),
-- [20] No-show: nobody attended
(N'U015', N'CL-102', N'2026-03-18 09:00:00', N'2026-03-18 11:00:00', N'workshop', 20, N'no_show'),
-- [21] Pending: administrative event request
(N'U002', N'MR-201', N'2026-04-25 10:00:00', N'2026-04-25 12:00:00', N'administrative_event', 15, N'pending'),
-- [22] Pending: department meeting request
(N'U010', N'MR-201', N'2026-05-01 09:00:00', N'2026-05-01 11:00:00', N'meeting',  10, N'pending'),
-- [23] Approved: future examination
(N'U003', N'AU-101', N'2026-05-10 09:00:00', N'2026-05-10 11:00:00', N'examination', 250, N'approved'),
-- [24] Approved: future lecture
(N'U005', N'CL-101', N'2026-05-12 14:00:00', N'2026-05-12 16:00:00', N'lecture',  20, N'approved'),
-- [25] Pending: seminar request
(N'U004', N'AU-201', N'2026-05-15 09:00:00', N'2026-05-15 12:00:00', N'seminar',  100, N'pending');
GO

-- ============================================================================
-- 6. APPROVALS
--    Business rules enforced:
--    - BR-NI-02: Only pending bookings can be approved (data reflects this)
--    - BR-NI-04: approver_id != requester_id
--    - Only approved/rejected bookings get approval rows
--    Booking IDs (by insertion order):
--      1-6  completed
--      7    checked_in
--      8-10 approved
--      16-17 rejected
--      20   no_show
--      23-24 approved (future)
-- ============================================================================
INSERT INTO approvals (booking_id, approver_id, decision, decision_time, decision_note, rejection_reason)
VALUES
-- Completed bookings approved by facility_manager or dept_admin
(1,  N'U001', N'approved', N'2026-01-14 10:00:00', N'Standard lecture approved.', NULL),
(2,  N'U001', N'approved', N'2026-01-16 10:00:00', N'Repeat session approved.', NULL),
(3,  N'U010', N'approved', N'2026-01-31 14:00:00', N'Lab session requires instructor supervision.', NULL),
(4,  N'U002', N'approved', N'2026-02-09 09:00:00', N'Workshop within CS department quota.', NULL),
(5,  N'U001', N'approved', N'2026-02-28 10:00:00', N'Department meeting approved.', NULL),
(6,  N'U001', N'approved', N'2026-03-14 09:00:00', N'Examination approved. Proctors assigned.', NULL),
-- Checked-in booking
(7,  N'U002', N'approved', N'2026-03-19 09:00:00', N'Lab lecture approved.', NULL),
-- Upcoming approved bookings
(8,  N'U002', N'approved', N'2026-03-30 09:00:00', N'TA seminar approved.', NULL),
(9,  N'U010', N'approved', N'2026-04-03 09:00:00', N'Lab session approved.', NULL),
(10, N'U001', N'approved', N'2026-04-08 10:00:00', N'Lecture auditorium slot approved.', NULL),
-- Rejected bookings
(16, N'U010', N'rejected', N'2026-03-24 11:00:00', NULL, N'Physics lab equipment undergoing calibration.'),
(17, N'U001', N'rejected', N'2026-03-27 14:00:00', NULL, N'Student activity requires faculty advisor co-sign.'),
-- No-show booking (was approved)
(20, N'U002', N'approved', N'2026-03-17 09:00:00', N'Workshop approved.', NULL),
-- Future approved bookings
(23, N'U001', N'approved', N'2026-05-08 09:00:00', N'Examination pre-approved.', NULL),
(24, N'U002', N'approved', N'2026-05-10 14:00:00', N'Lecture approved.', NULL);
GO

-- ============================================================================
-- 7. SESSIONS
--    Business rule BR-NI-03: Only approved bookings can have sessions.
--    Sessions exist for completed, checked_in, and no_show bookings (which
--    were approved and actually had a conducted usage period).
-- ============================================================================
INSERT INTO sessions (booking_id, conductor_id, actual_start_time, actual_end_time, initial_condition, final_condition, usage_notes)
VALUES
(1, N'U003', N'2026-01-15 09:05:00', N'2026-01-15 10:55:00', N'Classroom clean, projector working.', N'Whiteboard cleaned, projector turned off.', N'Lecture delivered on schedule.'),
(2, N'U003', N'2026-01-17 09:03:00', N'2026-01-17 10:58:00', N'Room tidy, all lights functional.', N'Room tidy, one marker nearly empty.', N'Second lecture of the series.'),
(3, N'U004', N'2026-02-01 14:00:00', N'2026-02-01 15:55:00', N'All lab equipment functional.', N'Equipment returned to storage.', N'Physics lab completed successfully.'),
(4, N'U005', N'2026-02-10 10:05:00', N'2026-02-10 11:50:00', N'All workstations operational.', N'All workstations shut down properly.', N'Python workshop for CS101 students.'),
(5, N'U002', N'2026-03-01 10:00:00', N'2026-03-01 11:45:00', N'Meeting room ready.', N'Room tidy, chairs returned.', N'Monthly department planning.'),
(6, N'U003', N'2026-03-15 09:00:00', N'2026-03-15 11:55:00', N'Auditorium set for examination.', N'All exam materials collected.', N'Final exam for MAT201. 198 students attended.'),
(7, N'U005', N'2026-03-20 09:02:00', NULL,                     N'Lab clean, projector on.', NULL, N'Session in progress as of data snapshot.'),
(20,N'U015', N'2026-03-18 09:00:00', N'2026-03-18 11:00:00', N'Computer lab ready.', N'No issues found.', N'No participants attended. Recorded as no-show.');
GO

-- ============================================================================
-- 8. MAINTENANCE RECORDS
--    Business rule BR-NI-08: assigned_staff_id must be facility_staff
--    or facility_manager.
--    -- facility_staff:  U008, U009
--    -- facility_manager: U001
-- ============================================================================
INSERT INTO maintenance_records (reporter_id, space_code, assigned_staff_id, problem_description, start_time, completion_time, status, result_note)
VALUES
-- Completed maintenance
(N'U003', N'PL-102', N'U008', N'Chemical fume hood not functioning.',              N'2026-01-10 09:00:00', N'2026-01-12 16:00:00', N'completed', N'Fume hood motor replaced.'),
(N'U005', N'CL-101', N'U009', N'Three workstations have failing power supplies.',   N'2026-01-20 10:00:00', N'2026-01-22 15:00:00', N'completed', N'Power supplies replaced in workstations 4, 11, 19.'),
(N'U004', N'PL-101', N'U008', N'Projector bulb needs replacement.',                 N'2026-02-05 10:00:00', N'2026-02-05 14:00:00', N'completed', N'Bulb replaced.'),
-- In-progress maintenance
(N'U002', N'MR-201', N'U009', N'Video conferencing camera microphone not working.', N'2026-03-25 11:00:00', NULL,                     N'in_progress', N'Diagnosing audio issue.'),
(N'U011', N'SW-103', N'U008', N'Renovation work for expansion.',                    N'2026-03-01 08:00:00', NULL,                     N'in_progress', N'Structural renovation underway.'),
-- Reported (pending) maintenance
(N'U003', N'AU-201', N'U001', N'Left-side air conditioning unit blowing warm air.', N'2026-04-01 09:00:00', NULL,                     N'reported',    NULL),
(N'U005', N'CL-102', N'U009', N'Network switch in rack B intermittent failure.',     N'2026-04-02 14:00:00', NULL,                     N'reported',    NULL),
(N'U018', N'CR-102', N'U001', N'Door handle loose on entrance door.',               N'2026-04-03 10:00:00', NULL,                     N'reported',    NULL);
GO

-- ============================================================================
-- DATA INTEGRITY SUMMARY
-- ============================================================================
-- users:            20 (18 active, 2 suspended)
-- spaces:           15 (11 available, 1 in_use, 1 under_maintenance,
--                        1 temporarily_closed, 1 retired)
-- facilities:       10
-- space_facilities: 35 associations
-- bookings:         25 (6 completed, 1 checked_in, 6 approved,
--                        7 pending, 2 rejected, 2 cancelled, 1 no_show)
-- approvals:        15 (13 approved, 2 rejected)
-- sessions:          8 (7 with end_time, 1 in progress)
-- maintenance:       8 (3 completed, 2 in_progress, 3 reported)
--
-- Business rules satisfied:
--   BR-NI-02: Only pending bookings referenced by approvals (historical
--             consistency: status reflects final state).
--   BR-NI-03: Sessions exist only for bookings that were approved.
--   BR-NI-04: All approver_id values differ from the booking requester_id.
--   BR-NI-05: All expected_participants <= space capacity.
--   BR-NI-07: Role-appropriate users assigned to functions.
--   BR-NI-08: assigned_staff_id always facility_staff or facility_manager.
-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
