-- ============================================================================
-- Query Design Script
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Description : Realistic business queries for the booking system
-- Artifact    : outputs/07-query-design-G7.sql
-- Prerequisite: outputs/05-db-implementation-G7.sql
-- ============================================================================

USE [CS486_Booking_System];
GO

-- ============================================================================
-- Query 1: My Upcoming Bookings
-- ============================================================================

-- **Business Question:**
-- As a student or lecturer, what are my upcoming approved bookings for the
-- next 7 days, including the space details and approval status?

-- **Target Users:**
-- Student, Lecturer

-- **Why is it useful?**
-- Allows users to quickly view their schedule without navigating through
-- the entire system, helping them prepare for upcoming sessions.

-- **SQL Implementation:**
SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    s.building,
    s.room_number,
    b.requested_start_time,
    b.requested_end_time,
    b.purpose,
    b.status,
    a.decision AS approval_decision
FROM bookings b
JOIN spaces s ON b.space_code = s.space_code
LEFT JOIN approvals a ON b.booking_id = a.booking_id
WHERE b.requester_id = 'U001'
  AND b.requested_start_time >= GETDATE()
  AND b.requested_start_time < DATEADD(DAY, 7, GETDATE())
  AND b.status IN (N'approved', N'pending')
ORDER BY b.requested_start_time ASC;
GO

-- ============================================================================
-- Query 2: Available Spaces for a Given Time Slot
-- ============================================================================

-- **Business Question:**
-- Which spaces are available for booking on a specific date and time range,
-- considering their capacity and current status?

-- **Target Users:**
-- Student, Lecturer, Teaching Assistant

-- **Why is it useful?**
-- Helps users find suitable spaces for their activities without manually
-- checking each room's availability, reducing double-booking conflicts.

-- **SQL Implementation:**
DECLARE @SearchStart DATETIME2 = '2026-09-15 09:00:00';
DECLARE @SearchEnd   DATETIME2 = '2026-09-15 11:00:00';
DECLARE @MinCapacity INT = 20;

SELECT
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.floor,
    sp.room_number,
    sp.capacity,
    sp.space_type,
    sp.usage_policy
FROM spaces sp
WHERE sp.status = N'available'
  AND sp.capacity >= @MinCapacity
  AND sp.space_code NOT IN (
      SELECT b.space_code
      FROM bookings b
      WHERE b.status IN (N'approved', N'pending', N'checked_in')
        AND b.requested_start_time < @SearchEnd
        AND b.requested_end_time > @SearchStart
  )
ORDER BY sp.building, sp.floor, sp.room_number;
GO

-- ============================================================================
-- Query 3: Space Utilization Rate
-- ============================================================================

-- **Business Question:**
-- What is the utilization rate (percentage of booked time vs. total available
-- time) for each space over the past month?

-- **Target Users:**
-- Facility Manager

-- **Why is it useful?**
-- Helps identify underutilized or overutilized spaces, enabling better
-- resource allocation and capacity planning.

-- **SQL Implementation:**
DECLARE @MonthStart DATETIME2 = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @MonthEnd   DATETIME2 = DATEADD(MONTH, 1, @MonthStart);

SELECT
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.room_number,
    sp.capacity,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    ISNULL(SUM(DATEDIFF(MINUTE,
        CASE WHEN b.requested_start_time < @MonthStart THEN @MonthStart ELSE b.requested_start_time END,
        CASE WHEN b.requested_end_time > @MonthEnd THEN @MonthEnd ELSE b.requested_end_time END
    )), 0) AS booked_minutes,
    DATEDIFF(MINUTE, @MonthStart, @MonthEnd) AS total_minutes,
    ROUND(
        ISNULL(SUM(DATEDIFF(MINUTE,
            CASE WHEN b.requested_start_time < @MonthStart THEN @MonthStart ELSE b.requested_start_time END,
            CASE WHEN b.requested_end_time > @MonthEnd THEN @MonthEnd ELSE b.requested_end_time END
        )), 0) * 100.0 / NULLIF(DATEDIFF(MINUTE, @MonthStart, @MonthEnd), 0),
    2) AS utilization_pct
FROM spaces sp
LEFT JOIN bookings b ON sp.space_code = b.space_code
    AND b.status IN (N'approved', N'checked_in', N'completed')
    AND b.requested_start_time < @MonthEnd
    AND b.requested_end_time > @MonthStart
GROUP BY sp.space_code, sp.space_name, sp.building, sp.room_number, sp.capacity
ORDER BY utilization_pct DESC;
GO

-- ============================================================================
-- Query 4: Overlapping Bookings Detection
-- ============================================================================

-- **Business Question:**
-- Are there any overlapping bookings for the same space that were incorrectly
-- approved due to a system or human error?

-- **Target Users:**
-- Department Administrator

-- **Why is it useful?**
-- Detects scheduling conflicts that could lead to double-booked rooms,
-- enabling administrators to resolve issues before they impact users.

-- **SQL Implementation:**
SELECT
    b1.booking_id AS booking_1_id,
    b2.booking_id AS booking_2_id,
    b1.space_code,
    sp.space_name,
    b1.requester_id AS requester_1,
    b2.requester_id AS requester_2,
    b1.requested_start_time AS start_1,
    b1.requested_end_time   AS end_1,
    b2.requested_start_time AS start_2,
    b2.requested_end_time   AS end_2
FROM bookings b1
JOIN bookings b2
    ON b1.space_code = b2.space_code
   AND b1.booking_id < b2.booking_id
   AND b1.requested_start_time < b2.requested_end_time
   AND b1.requested_end_time > b2.requested_start_time
JOIN spaces sp ON b1.space_code = sp.space_code
WHERE b1.status IN (N'approved', N'pending', N'checked_in')
  AND b2.status IN (N'approved', N'pending', N'checked_in')
ORDER BY b1.space_code, b1.requested_start_time;
GO

-- ============================================================================
-- Query 5: Pending Approvals Awaiting Decision
-- ============================================================================

-- **Business Question:**
-- Which booking requests are pending approval, and how long have they been
-- waiting for a decision?

-- **Target Users:**
-- Facility Manager

-- **Why is it useful?**
-- Enables facility managers to promptly review and process pending booking
-- requests, reducing user wait times and improving service responsiveness.

-- **SQL Implementation:**
SELECT
    b.booking_id,
    u.first_name + N' ' + u.last_name AS requester_name,
    u.department,
    u.email,
    sp.space_name,
    sp.building,
    sp.room_number,
    b.requested_start_time,
    b.requested_end_time,
    b.purpose,
    b.expected_participants,
    DATEDIFF(HOUR, b.requested_start_time, GETDATE()) AS hours_since_request
FROM bookings b
JOIN users u ON b.requester_id = u.user_id
JOIN spaces sp ON b.space_code = sp.space_code
WHERE b.status = N'pending'
ORDER BY b.requested_start_time ASC;
GO

-- ============================================================================
-- Query 6: Average Maintenance Resolution Time
-- ============================================================================

-- **Business Question:**
-- What is the average time taken to resolve maintenance issues, broken down
-- by space type?

-- **Target Users:**
-- Facility Manager, Facility Staff

-- **Why is it useful?**
-- Helps track maintenance efficiency and identify space types or buildings
-- that may need faster response times.

-- **SQL Implementation:**
SELECT
    sp.space_type,
    sp.building,
    COUNT(mr.maintenance_id) AS total_issues,
    COUNT(CASE WHEN mr.status = N'completed' THEN 1 END) AS resolved_issues,
    AVG(
        CASE
            WHEN mr.completion_time IS NOT NULL
            THEN DATEDIFF(HOUR, mr.start_time, mr.completion_time)
            ELSE NULL
        END
    ) AS avg_resolution_hours,
    MAX(
        CASE
            WHEN mr.completion_time IS NOT NULL
            THEN DATEDIFF(HOUR, mr.start_time, mr.completion_time)
            ELSE NULL
        END
    ) AS max_resolution_hours
FROM maintenance_records mr
JOIN spaces sp ON mr.space_code = sp.space_code
GROUP BY sp.space_type, sp.building
ORDER BY avg_resolution_hours DESC;
GO

-- ============================================================================
-- Query 7: Space Facilities Inventory
-- ============================================================================

-- **Business Question:**
-- What facilities are available in each space, and how many of each?

-- **Target Users:**
-- Facility Staff, Student, Lecturer

-- **Why is it useful?**
-- Allows users and staff to check which facilities (projectors, whiteboards,
-- computers, etc.) are available in a space before making a booking.

-- **SQL Implementation:**
SELECT
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.floor,
    sp.room_number,
    sp.space_type,
    f.facility_name,
    sf.quantity
FROM spaces sp
JOIN space_facilities sf ON sp.space_code = sf.space_code
JOIN facilities f ON sf.facility_id = f.facility_id
ORDER BY sp.building, sp.floor, sp.room_number, f.facility_name;
GO

-- ============================================================================
-- Query 8: Booking History for a Specific User
-- ============================================================================

-- **Business Question:**
-- What is the complete booking history for a given user, including approval
-- decisions and session details?

-- **Target Users:**
-- Department Administrator

-- **Why is it useful?**
-- Enables administrators to audit a user's booking behavior, check for
-- policy violations, and verify usage patterns.

-- **SQL Implementation:**
SELECT
    b.booking_id,
    sp.space_name,
    sp.building,
    sp.room_number,
    b.requested_start_time,
    b.requested_end_time,
    b.purpose,
    b.expected_participants,
    b.status AS booking_status,
    a.decision AS approval_decision,
    a.decision_time,
    a.rejection_reason,
    s.actual_start_time,
    s.actual_end_time,
    s.usage_notes
FROM bookings b
JOIN spaces sp ON b.space_code = sp.space_code
LEFT JOIN approvals a ON b.booking_id = a.booking_id
LEFT JOIN sessions s ON b.booking_id = s.booking_id
WHERE b.requester_id = 'U001'
ORDER BY b.requested_start_time DESC;
GO

-- ============================================================================
-- Query 9: Most Frequently Booked Spaces
-- ============================================================================

-- **Business Question:**
-- Which spaces are booked most frequently, and what are their peak usage days?

-- **Target Users:**
-- Facility Manager

-- **Why is it useful?**
-- Identifies high-demand spaces to inform scheduling policies, maintenance
-- windows, and potential expansion needs.

-- **SQL Implementation:**
SELECT TOP 10
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.room_number,
    sp.space_type,
    sp.capacity,
    COUNT(b.booking_id) AS booking_count,
    DATENAME(WEEKDAY, b.requested_start_time) AS peak_day,
    COUNT(DISTINCT CAST(b.requested_start_time AS DATE)) AS active_days
FROM spaces sp
JOIN bookings b ON sp.space_code = b.space_code
WHERE b.status IN (N'approved', N'checked_in', N'completed')
GROUP BY sp.space_code, sp.space_name, sp.building, sp.room_number,
         sp.space_type, sp.capacity, DATENAME(WEEKDAY, b.requested_start_time)
ORDER BY booking_count DESC;
GO

-- ============================================================================
-- Query 10: Currently Active Sessions
-- ============================================================================

-- **Business Question:**
-- Which sessions are currently running right now, and who is conducting them?

-- **Target Users:**
-- Facility Staff

-- **Why is it useful?**
-- Allows facility staff to monitor real-time space usage, check for
-- unauthorized use, and provide immediate assistance if needed.

-- **SQL Implementation:**
SELECT
    s.session_id,
    b.booking_id,
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.room_number,
    u.first_name + N' ' + u.last_name AS conductor_name,
    u.role AS conductor_role,
    s.actual_start_time,
    s.initial_condition,
    b.purpose,
    b.expected_participants
FROM sessions s
JOIN bookings b ON s.booking_id = b.booking_id
JOIN spaces sp ON b.space_code = sp.space_code
JOIN users u ON s.conductor_id = u.user_id
WHERE s.actual_start_time <= GETDATE()
  AND (s.actual_end_time IS NULL OR s.actual_end_time > GETDATE())
ORDER BY sp.building, sp.floor;
GO

-- ============================================================================
-- Query 11: Unresolved Maintenance Issues
-- ============================================================================

-- **Business Question:**
-- Which maintenance issues are still unresolved, and how long have they been
-- open?

-- **Target Users:**
-- Facility Manager

-- **Why is it useful?**
-- Helps management prioritize and track outstanding maintenance work,
-- ensuring critical issues are addressed promptly.

-- **SQL Implementation:**
SELECT
    mr.maintenance_id,
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.floor,
    sp.room_number,
    reporter.first_name + N' ' + reporter.last_name AS reported_by,
    staff.first_name + N' ' + staff.last_name AS assigned_to,
    mr.problem_description,
    mr.start_time,
    mr.status,
    DATEDIFF(DAY, mr.start_time, GETDATE()) AS days_open,
    mr.result_note
FROM maintenance_records mr
JOIN spaces sp ON mr.space_code = sp.space_code
JOIN users reporter ON mr.reporter_id = reporter.user_id
JOIN users staff ON mr.assigned_staff_id = staff.user_id
WHERE mr.status IN (N'reported', N'in_progress')
ORDER BY mr.start_time ASC;
GO

-- ============================================================================
-- Query 12: Booking Distribution by Purpose
-- ============================================================================

-- **Business Question:**
-- How are bookings distributed across different purposes (lecture, seminar,
-- meeting, etc.) over the current academic term?

-- **Target Users:**
-- Department Administrator

-- **Why is it useful?**
-- Helps understand how spaces are being used, enabling better term planning
-- and resource allocation for different activity types.

-- **SQL Implementation:**
SELECT
    b.purpose,
    COUNT(b.booking_id) AS total_bookings,
    COUNT(DISTINCT b.requester_id) AS unique_users,
    COUNT(DISTINCT b.space_code) AS unique_spaces_used,
    SUM(b.expected_participants) AS total_participants,
    AVG(b.expected_participants) AS avg_participants_per_booking,
    ROUND(COUNT(b.booking_id) * 100.0 / NULLIF(SUM(COUNT(b.booking_id)) OVER (), 0), 2) AS pct_of_total
FROM bookings b
WHERE b.requested_start_time >= DATEFROMPARTS(2026, 1, 1)
  AND b.requested_start_time < DATEFROMPARTS(2026, 7, 1)
GROUP BY b.purpose
ORDER BY total_bookings DESC;
GO

-- ============================================================================
-- Query 13: Users with Frequent No-Shows
-- ============================================================================

-- **Business Question:**
-- Which users have the highest number of no-show or cancelled bookings,
-- indicating potential misuse of the booking system?

-- **Target Users:**
-- Department Administrator, Facility Manager

-- **Why is it useful?**
-- Identifies users who habitually book spaces but fail to use them, allowing
-- administrators to enforce penalties or warnings to improve space availability.

-- **SQL Implementation:**
SELECT TOP 10
    u.user_id,
    u.first_name + N' ' + u.last_name AS user_name,
    u.department,
    u.role,
    COUNT(CASE WHEN b.status = N'no_show' THEN 1 END) AS no_show_count,
    COUNT(CASE WHEN b.status = N'cancelled' THEN 1 END) AS cancellation_count,
    COUNT(b.booking_id) AS total_bookings,
    ROUND(
        (COUNT(CASE WHEN b.status IN (N'no_show', N'cancelled') THEN 1 END) * 100.0)
        / NULLIF(COUNT(b.booking_id), 0),
    2) AS misuse_pct
FROM users u
JOIN bookings b ON u.user_id = b.requester_id
GROUP BY u.user_id, u.first_name, u.last_name, u.department, u.role
HAVING COUNT(CASE WHEN b.status IN (N'no_show', N'cancelled') THEN 1 END) > 0
ORDER BY misuse_pct DESC;
GO

-- ============================================================================
-- Query 14: Capacity vs. Expected Participants
-- ============================================================================

-- **Business Question:**
-- Which approved bookings have expected participant counts dangerously close
-- to or exceeding the space capacity?

-- **Target Users:**
-- Lecturer, Facility Manager

-- **Why is it useful?**
-- Prevents overcrowding and ensures safety compliance by flagging bookings
-- where participant numbers approach or exceed room capacity.

-- **SQL Implementation:**
SELECT
    b.booking_id,
    u.first_name + N' ' + u.last_name AS requester_name,
    u.department,
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.room_number,
    sp.capacity,
    b.expected_participants,
    b.purpose,
    b.requested_start_time,
    b.requested_end_time,
    CASE
        WHEN b.expected_participants > sp.capacity THEN N'OVER CAPACITY'
        WHEN b.expected_participants >= sp.capacity * 0.9 THEN N'near_full'
        ELSE N'comfortable'
    END AS capacity_status
FROM bookings b
JOIN spaces sp ON b.space_code = sp.space_code
JOIN users u ON b.requester_id = u.user_id
WHERE b.status = N'approved'
  AND b.expected_participants >= sp.capacity * 0.9
ORDER BY b.expected_participants DESC;
GO

-- ============================================================================
-- Query 15: Approval Decision Summary
-- ============================================================================

-- **Business Question:**
-- What is the approval/rejection summary for each facility manager, including
-- their average decision time?

-- **Target Users:**
-- Facility Manager, Department Administrator

-- **Why is it useful?**
-- Provides accountability and performance metrics for approvers, helping
-- ensure timely and fair decisions on booking requests.

-- **SQL Implementation:**
SELECT
    approver.user_id AS approver_id,
    approver.first_name + N' ' + approver.last_name AS approver_name,
    COUNT(a.approval_id) AS total_decisions,
    SUM(CASE WHEN a.decision = N'approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(CASE WHEN a.decision = N'rejected' THEN 1 ELSE 0 END) AS rejected_count,
    ROUND(
        AVG(DATEDIFF(MINUTE, b.requested_start_time, a.decision_time)),
    0) AS avg_decision_minutes,
    ROUND(
        SUM(CASE WHEN a.decision = N'approved' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(a.approval_id), 0),
    2) AS approval_rate_pct
FROM approvals a
JOIN users approver ON a.approver_id = approver.user_id
JOIN bookings b ON a.booking_id = b.booking_id
GROUP BY approver.user_id, approver.first_name, approver.last_name
ORDER BY total_decisions DESC;
GO

-- ============================================================================
-- Query 16: Full Maintenance History for a Space
-- ============================================================================

-- **Business Question:**
-- What is the complete maintenance history for a specific space, including
-- problem descriptions, assigned staff, and resolution outcomes?

-- **Target Users:**
-- Facility Staff

-- **Why is it useful?**
-- Helps staff track recurring issues for a particular space, identify
-- patterns, and plan preventative maintenance.

-- **SQL Implementation:**
SELECT
    mr.maintenance_id,
    reporter.first_name + N' ' + reporter.last_name AS reported_by,
    staff.first_name + N' ' + staff.last_name AS assigned_staff,
    mr.problem_description,
    mr.start_time,
    mr.completion_time,
    mr.status,
    mr.result_note,
    DATEDIFF(DAY, mr.start_time, ISNULL(mr.completion_time, GETDATE())) AS days_in_maintenance
FROM maintenance_records mr
JOIN users reporter ON mr.reporter_id = reporter.user_id
JOIN users staff ON mr.assigned_staff_id = staff.user_id
WHERE mr.space_code = 'LAB-101'
ORDER BY mr.start_time DESC;
GO

-- ============================================================================
-- Query 17: Booking Requests per Department
-- ============================================================================

-- **Business Question:**
-- How many booking requests come from each department, and what is their
-- approval rate?

-- **Target Users:**
-- Department Administrator

-- **Why is it useful?**
-- Reveals which departments are the heaviest users of space resources,
-- supporting data-driven decisions for departmental space allocation.

-- **SQL Implementation:**
SELECT
    u.department,
    COUNT(b.booking_id) AS total_requests,
    COUNT(DISTINCT u.user_id) AS unique_requesters,
    SUM(CASE WHEN b.status IN (N'approved', N'checked_in', N'completed') THEN 1 ELSE 0 END) AS successful_bookings,
    SUM(CASE WHEN b.status = N'rejected' THEN 1 ELSE 0 END) AS rejected_bookings,
    ROUND(
        SUM(CASE WHEN b.status IN (N'approved', N'checked_in', N'completed') THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(b.booking_id), 0),
    2) AS success_rate_pct
FROM users u
JOIN bookings b ON u.user_id = b.requester_id
GROUP BY u.department
ORDER BY total_requests DESC;
GO

-- ============================================================================
-- Query 18: Sessions Exceeding Scheduled Duration
-- ============================================================================

-- **Business Question:**
-- Which sessions ran longer than their scheduled booking time, and by how
-- much?

-- **Target Users:**
-- Facility Manager

-- **Why is it useful?**
-- Detects overruns that may disrupt subsequent bookings, enabling managers
-- to enforce time limits and improve scheduling accuracy.

-- **SQL Implementation:**
SELECT
    s.session_id,
    b.booking_id,
    u.first_name + N' ' + u.last_name AS conductor_name,
    sp.space_code,
    sp.space_name,
    sp.building,
    sp.room_number,
    b.requested_start_time,
    b.requested_end_time AS scheduled_end_time,
    s.actual_start_time,
    s.actual_end_time,
    DATEDIFF(MINUTE, b.requested_start_time, b.requested_end_time) AS scheduled_duration_min,
    DATEDIFF(MINUTE, s.actual_start_time, s.actual_end_time) AS actual_duration_min,
    DATEDIFF(MINUTE, b.requested_end_time, s.actual_end_time) AS overrun_minutes
FROM sessions s
JOIN bookings b ON s.booking_id = b.booking_id
JOIN spaces sp ON b.space_code = sp.space_code
JOIN users u ON s.conductor_id = u.user_id
WHERE s.actual_end_time IS NOT NULL
  AND s.actual_end_time > b.requested_end_time
ORDER BY overrun_minutes DESC;
GO

-- ============================================================================
-- Query 19: Facilities Not Assigned to Any Space
-- ============================================================================

-- **Business Question:**
-- Which facilities exist in the system but are not currently assigned to any
-- space?

-- **Target Users:**
-- Facility Manager, Facility Staff

-- **Why is it useful?**
-- Identifies orphaned facility records that may indicate incomplete data
-- entry or facilities that were removed from spaces but not cleaned up.

-- **SQL Implementation:**
SELECT
    f.facility_id,
    f.facility_name,
    f.description
FROM facilities f
LEFT JOIN space_facilities sf ON f.facility_id = sf.facility_id
WHERE sf.space_code IS NULL
ORDER BY f.facility_name;
GO

-- ============================================================================
-- Query 20: Weekly Booking Report
-- ============================================================================

-- **Business Question:**
-- Provide a comprehensive weekly summary of all booking activity, including
-- new requests, approvals, cancellations, and completed sessions.

-- **Target Users:**
-- Department Administrator, Facility Manager

-- **Why is it useful?**
-- Delivers a bird's-eye view of system activity for weekly operational
-- reviews, helping management spot trends and address issues proactively.

-- **SQL Implementation:**
DECLARE @WeekStart DATETIME2 = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
DECLARE @WeekEnd   DATETIME2 = CAST(GETDATE() AS DATE);

SELECT
    N'New Requests' AS metric, COUNT(*) AS value
FROM bookings
WHERE requested_start_time >= @WeekStart AND requested_start_time < @WeekEnd
UNION ALL
SELECT N'Approved', COUNT(*)
FROM approvals
WHERE decision = N'approved' AND decision_time >= @WeekStart AND decision_time < @WeekEnd
UNION ALL
SELECT N'Rejected', COUNT(*)
FROM approvals
WHERE decision = N'rejected' AND decision_time >= @WeekStart AND decision_time < @WeekEnd
UNION ALL
SELECT N'Cancelled', COUNT(*)
FROM bookings
WHERE status = N'cancelled' AND requested_start_time >= @WeekStart AND requested_start_time < @WeekEnd
UNION ALL
SELECT N'No-Shows', COUNT(*)
FROM bookings
WHERE status = N'no_show' AND requested_start_time >= @WeekStart AND requested_start_time < @WeekEnd
UNION ALL
SELECT N'Completed Sessions', COUNT(*)
FROM sessions s
JOIN bookings b ON s.booking_id = b.booking_id
WHERE s.actual_end_time IS NOT NULL
  AND s.actual_end_time >= @WeekStart AND s.actual_end_time < @WeekEnd
UNION ALL
SELECT N'New Maintenance Issues', COUNT(*)
FROM maintenance_records
WHERE start_time >= @WeekStart AND start_time < @WeekEnd
UNION ALL
SELECT N'Maintenance Resolved', COUNT(*)
FROM maintenance_records
WHERE completion_time >= @WeekStart AND completion_time < @WeekEnd
ORDER BY metric;
GO

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
