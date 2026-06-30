# Query Design — CS486 Booking System (Group 7)

**Artifact:** `outputs/07-query-design-G7.md`  
**DBMS:** Microsoft SQL Server (T-SQL)  
**Prerequisite:** `outputs/05-db-implementation-G7.sql`  

---

## Target Users

| # | Role | Description |
|---|------|-------------|
| 1 | Student | Books spaces for self-study or group work |
| 2 | Lecturer | Books classrooms/labs for lectures and seminars |
| 3 | Teaching Assistant | Assists with session management and space booking |
| 4 | Facility Staff | Handles maintenance and space readiness |
| 5 | Facility Manager | Approves bookings and monitors space utilization |
| 6 | Department Administrator | Runs reports and analytics across the system |

---

## Queries

---

### Query 1: Space Utilization Report

**Business Question:**  
Which spaces have the highest utilization rate based on the total hours of approved bookings in the current month?

**Target Users:**  
Facility Manager

**Why is it useful?**  
Identifies underutilized spaces that could be repurposed and overutilized spaces that may need scheduling adjustments or capacity expansion.

**SQL Implementation:**

```sql
SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.building,
    s.capacity,
    COUNT(b.booking_id)                                                  AS booking_count,
    ISNULL(SUM(DATEDIFF(HOUR, b.requested_start_time, b.requested_end_time)), 0)
                                                                         AS total_booked_hours
FROM spaces s
LEFT JOIN bookings b
    ON b.space_code = s.space_code
    AND b.status = N'approved'
    AND b.requested_start_time >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
GROUP BY s.space_code, s.space_name, s.space_type, s.building, s.capacity
ORDER BY total_booked_hours DESC;
```

---

### Query 2: Pending Booking Approvals

**Business Question:**  
What bookings are currently pending approval, and who requested them?

**Target Users:**  
Facility Manager

**Why is it useful?**  
Provides a decision queue so that the facility manager can quickly see all bookings awaiting approval, including requester details, purpose, and time slot.

**SQL Implementation:**

```sql
SELECT
    b.booking_id,
    b.requested_start_time,
    b.requested_end_time,
    b.purpose,
    b.expected_participants,
    u.first_name + N' ' + u.last_name AS requester_name,
    u.email                           AS requester_email,
    u.department                      AS requester_department,
    s.space_name,
    s.building,
    s.room_number
FROM bookings b
JOIN users u   ON u.user_id = b.requester_id
JOIN spaces s  ON s.space_code = b.space_code
WHERE b.status = N'pending'
ORDER BY b.requested_start_time ASC;
```

---

### Query 3: My Upcoming Approved Bookings

**Business Question:**  
What are my (a logged-in user's) approved bookings for the next seven days?

**Target Users:**  
Student, Lecturer, Teaching Assistant

**Why is it useful?**  
Allows any user to quickly see their upcoming schedule so they can prepare and avoid conflicts.

**SQL Implementation:**

```sql
DECLARE @MyUserId VARCHAR(50) = N'USER001';  -- Placeholder for application parameter

SELECT
    b.booking_id,
    s.space_name,
    s.building,
    s.room_number,
    b.requested_start_time,
    b.requested_end_time,
    b.purpose,
    b.expected_participants,
    a.decision,
    a.decision_note
FROM bookings b
JOIN spaces s ON s.space_code = b.space_code
LEFT JOIN approvals a ON a.booking_id = b.booking_id
WHERE b.requester_id = @MyUserId
  AND b.status IN (N'approved', N'checked_in')
  AND b.requested_start_time >= GETDATE()
  AND b.requested_start_time < DATEADD(DAY, 7, GETDATE())
ORDER BY b.requested_start_time ASC;
```

---

### Query 4: Overlapping Booking Detection

**Business Question:**  
Are there any approved bookings that overlap in time for the same space?

**Target Users:**  
Department Administrator, Facility Manager

**Why is it useful?**  
Detects scheduling conflicts that slipped through the application layer, ensuring data integrity and preventing double-booking.

**SQL Implementation:**

```sql
SELECT DISTINCT
    b1.booking_id        AS booking_id_a,
    b2.booking_id        AS booking_id_b,
    b1.space_code,
    s.space_name,
    b1.requested_start_time AS start_a,
    b1.requested_end_time   AS end_a,
    b2.requested_start_time AS start_b,
    b2.requested_end_time   AS end_b,
    u1.first_name + N' ' + u1.last_name AS requester_a,
    u2.first_name + N' ' + u2.last_name AS requester_b
FROM bookings b1
JOIN bookings b2
    ON b1.space_code = b2.space_code
    AND b1.booking_id < b2.booking_id
    AND b1.requested_start_time < b2.requested_end_time
    AND b2.requested_start_time < b1.requested_end_time
JOIN spaces s  ON s.space_code = b1.space_code
JOIN users u1  ON u1.user_id = b1.requester_id
JOIN users u2  ON u2.user_id = b2.requester_id
WHERE b1.status IN (N'approved', N'checked_in')
  AND b2.status IN (N'approved', N'checked_in')
ORDER BY b1.space_code, b1.requested_start_time;
```

---

### Query 5: Maintenance Resolution Time

**Business Question:**  
What is the average time (in hours) to complete maintenance tasks, broken down by space?

**Target Users:**  
Facility Manager

**Why is it useful?**  
Helps evaluate maintenance staff performance and identify spaces that experience prolonged downtime.

**SQL Implementation:**

```sql
SELECT
    s.space_code,
    s.space_name,
    s.building,
    COUNT(mr.maintenance_id)                                            AS total_issues,
    COUNT(CASE WHEN mr.status = N'completed' THEN 1 END)               AS resolved_issues,
    AVG(CASE
            WHEN mr.completion_time IS NOT NULL
            THEN DATEDIFF(HOUR, mr.start_time, mr.completion_time)
            ELSE NULL
        END)                                                            AS avg_resolution_hours,
    MAX(CASE
            WHEN mr.completion_time IS NOT NULL
            THEN DATEDIFF(HOUR, mr.start_time, mr.completion_time)
            ELSE NULL
        END)                                                            AS max_resolution_hours
FROM spaces s
JOIN maintenance_records mr ON mr.space_code = s.space_code
GROUP BY s.space_code, s.space_name, s.building
ORDER BY avg_resolution_hours DESC;
```

---

### Query 6: Space Facility Inventory

**Business Question:**  
What facilities are available in each space, and in what quantity?

**Target Users:**  
Facility Staff, Student, Lecturer

**Why is it useful?**  
Helps users choose a space based on required equipment, and helps staff verify that facility inventories are accurate.

**SQL Implementation:**

```sql
SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.building,
    s.room_number,
    f.facility_name,
    sf.quantity
FROM spaces s
JOIN space_facilities sf ON sf.space_code = s.space_code
JOIN facilities f       ON f.facility_id  = sf.facility_id
ORDER BY s.building, s.room_number, f.facility_name;
```

---

### Query 7: Active Maintenance Issues

**Business Question:**  
What maintenance issues are currently open (reported or in-progress) and who is assigned to them?

**Target Users:**  
Facility Staff, Facility Manager

**Why is it useful?**  
Provides a real-time view of outstanding maintenance work, enabling prioritization and assignment tracking.

**SQL Implementation:**

```sql
SELECT
    mr.maintenance_id,
    mr.problem_description,
    mr.start_time,
    mr.status,
    s.space_code,
    s.space_name,
    s.building,
    s.room_number,
    reporter.first_name + N' ' + reporter.last_name AS reporter_name,
    staff.first_name  + N' ' + staff.last_name     AS assigned_staff_name,
    DATEDIFF(DAY, mr.start_time, GETDATE())        AS days_since_report
FROM maintenance_records mr
JOIN spaces s  ON s.space_code = mr.space_code
JOIN users reporter ON reporter.user_id = mr.reporter_id
JOIN users staff    ON staff.user_id    = mr.assigned_staff_id
WHERE mr.status IN (N'reported', N'in_progress')
ORDER BY mr.start_time ASC;
```

---

### Query 8: Booking History by User

**Business Question:**  
What is the complete booking history for a specific user, including approval decisions and session details?

**Target Users:**  
Department Administrator

**Why is it useful?**  
Provides a comprehensive audit trail for a specific user, useful for investigating complaints, policy violations, or usage patterns.

**SQL Implementation:**

```sql
DECLARE @TargetUserId VARCHAR(50) = N'USER001';  -- Placeholder for application parameter

SELECT
    b.booking_id,
    b.requested_start_time,
    b.requested_end_time,
    b.purpose,
    b.expected_participants,
    b.status                              AS booking_status,
    s.space_name,
    a.decision,
    a.decision_time,
    a.rejection_reason,
    approver.first_name + N' ' + approver.last_name AS approver_name,
    ses.actual_start_time,
    ses.actual_end_time,
    ses.initial_condition,
    ses.final_condition
FROM bookings b
JOIN spaces s ON s.space_code = b.space_code
LEFT JOIN approvals a        ON a.booking_id = b.booking_id
LEFT JOIN users approver     ON approver.user_id = a.approver_id
LEFT JOIN sessions ses       ON ses.booking_id = b.booking_id
WHERE b.requester_id = @TargetUserId
ORDER BY b.requested_start_time DESC;
```

---

### Query 9: Popular Space Types

**Business Question:**  
Which space types (auditorium, classroom, lab, etc.) are booked most frequently?

**Target Users:**  
Facility Manager, Department Administrator

**Why is it useful?**  
Helps guide future space planning and renovation investments toward the most demanded space types.

**SQL Implementation:**

```sql
SELECT
    s.space_type,
    COUNT(b.booking_id)                       AS total_bookings,
    SUM(DATEDIFF(HOUR, b.requested_start_time, b.requested_end_time))
                                               AS total_hours_booked,
    COUNT(DISTINCT s.space_code)              AS number_of_spaces,
    CAST(COUNT(b.booking_id) AS FLOAT) /
        NULLIF(COUNT(DISTINCT s.space_code), 0) AS avg_bookings_per_space
FROM spaces s
LEFT JOIN bookings b ON b.space_code = s.space_code
                    AND b.status NOT IN (N'rejected', N'cancelled')
GROUP BY s.space_type
ORDER BY total_bookings DESC;
```

---

### Query 10: Approval Statistics by Approver

**Business Question:**  
How many bookings has each approver approved or rejected, and what is their approval rate?

**Target Users:**  
Facility Manager, Department Administrator

**Why is it useful?**  
Evaluates workload distribution among approvers and identifies potential bias or bottlenecks in the approval process.

**SQL Implementation:**

```sql
SELECT
    u.user_id,
    u.first_name + N' ' + u.last_name  AS approver_name,
    u.department,
    COUNT(a.booking_id)                                          AS total_decisions,
    SUM(CASE WHEN a.decision = N'approved' THEN 1 ELSE 0 END)   AS approved_count,
    SUM(CASE WHEN a.decision = N'rejected' THEN 1 ELSE 0 END)   AS rejected_count,
    CAST(SUM(CASE WHEN a.decision = N'approved' THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(COUNT(a.booking_id), 0) * 100                    AS approval_rate_pct
FROM users u
JOIN approvals a ON a.approver_id = u.user_id
GROUP BY u.user_id, u.first_name, u.last_name, u.department
ORDER BY total_decisions DESC;
```

---

### Query 11: No-Show Rate by Department

**Business Question:**  
Which departments have the highest rate of no-show bookings?

**Target Users:**  
Department Administrator

**Why is it useful?**  
Identifies departments that frequently waste space resources, enabling targeted policy communication or intervention.

**SQL Implementation:**

```sql
SELECT
    u.department,
    COUNT(b.booking_id)                                                     AS total_bookings,
    SUM(CASE WHEN b.status = N'no_show' THEN 1 ELSE 0 END)                 AS no_show_count,
    CAST(SUM(CASE WHEN b.status = N'no_show' THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(COUNT(b.booking_id), 0) * 100                             AS no_show_rate_pct
FROM users u
JOIN bookings b ON b.requester_id = u.user_id
WHERE b.status IN (N'no_show', N'completed', N'checked_in')
GROUP BY u.department
ORDER BY no_show_rate_pct DESC;
```

---

### Query 12: Space Capacity vs. Expected Participants

**Business Question:**  
Which bookings have expected participants that are either far below or exceeding the space capacity?

**Target Users:**  
Facility Manager

**Why is it useful?**  
Identifies inefficient space allocation (small group in a large room) or potential policy violations (over capacity), enabling better scheduling decisions.

**SQL Implementation:**

```sql
SELECT
    b.booking_id,
    u.first_name + N' ' + u.last_name  AS requester_name,
    s.space_name,
    s.capacity,
    b.expected_participants,
    s.capacity - b.expected_participants  AS unused_capacity,
    CASE
        WHEN b.expected_participants > s.capacity THEN N'OVER_CAPACITY'
        WHEN b.expected_participants <= s.capacity * 0.25 THEN N'severely_underutilized'
        WHEN b.expected_participants <= s.capacity * 0.50 THEN N'underutilized'
        ELSE N'reasonable'
    END AS utilization_category
FROM bookings b
JOIN spaces s ON s.space_code = b.space_code
JOIN users u  ON u.user_id    = b.requester_id
WHERE b.status NOT IN (N'rejected', N'cancelled')
ORDER BY unused_capacity DESC;
```

---

### Query 13: User Booking Frequency

**Business Question:**  
Which users make the most booking requests, and what is their approval success rate?

**Target Users:**  
Department Administrator

**Why is it useful?**  
Identifies power users who may need additional support or training, and helps detect potential abuse of the booking system.

**SQL Implementation:**

```sql
SELECT
    u.user_id,
    u.first_name + N' ' + u.last_name AS user_name,
    u.role,
    u.department,
    COUNT(b.booking_id)                                           AS total_requests,
    SUM(CASE WHEN b.status IN (N'approved', N'checked_in', N'completed')
             THEN 1 ELSE 0 END)                                   AS successful_bookings,
    SUM(CASE WHEN b.status = N'cancelled' THEN 1 ELSE 0 END)     AS cancelled_count,
    CAST(SUM(CASE WHEN a.decision = N'approved' THEN 1 ELSE 0 END) AS FLOAT)
        / NULLIF(SUM(CASE WHEN a.decision IS NOT NULL THEN 1 ELSE 0 END), 0) * 100
                                                                  AS approval_rate_pct
FROM users u
LEFT JOIN bookings b ON b.requester_id = u.user_id
LEFT JOIN approvals a ON a.booking_id = b.booking_id
GROUP BY u.user_id, u.first_name, u.last_name, u.role, u.department
ORDER BY total_requests DESC;
```

---

### Query 14: Cancelled Bookings Report

**Business Question:**  
What patterns exist in cancelled bookings — who cancels most often and for what purposes?

**Target Users:**  
Department Administrator

**Why is it useful?**  
Reveals whether certain purposes (e.g., student activities) or users have disproportionately high cancellation rates, informing policy changes.

**SQL Implementation:**

```sql
SELECT
    b.purpose,
    u.role,
    u.department,
    COUNT(b.booking_id)                        AS total_cancellations,
    COUNT(DISTINCT u.user_id)                  AS distinct_users,
    AVG(DATEDIFF(HOUR, GETDATE(), b.requested_start_time) * -1)
                                                 AS avg_hours_before_start
FROM bookings b
JOIN users u ON u.user_id = b.requester_id
WHERE b.status = N'cancelled'
  AND b.requested_start_time >= DATEADD(MONTH, -3, GETDATE())
GROUP BY b.purpose, u.role, u.department
ORDER BY total_cancellations DESC;
```

---

### Query 15: Facility Demand Analysis

**Business Question:**  
Which facilities are most commonly available across spaces, and which spaces offer the widest range of facilities?

**Target Users:**  
Facility Manager

**Why is it useful?**  
Helps plan facility procurement and identify spaces that may need additional equipment to meet user demand.

**SQL Implementation:**

```sql
SELECT
    f.facility_id,
    f.facility_name,
    COUNT(DISTINCT sf.space_code)       AS spaces_with_facility,
    SUM(sf.quantity)                    AS total_quantity_across_spaces
FROM facilities f
LEFT JOIN space_facilities sf ON sf.facility_id = f.facility_id
GROUP BY f.facility_id, f.facility_name
ORDER BY spaces_with_facility DESC, total_quantity_across_spaces DESC;
```

---

### Query 16: Today's Active Sessions

**Business Question:**  
What sessions are happening today, including the conductor, space, and time details?

**Target Users:**  
Facility Staff, Facility Manager

**Why is it useful?**  
Provides a daily operations overview so staff can prepare spaces and managers can monitor activity.

**SQL Implementation:**

```sql
SELECT
    ses.booking_id,
    ses.session_id,
    s.space_name,
    s.building,
    s.room_number,
    conductor.first_name + N' ' + conductor.last_name AS conductor_name,
    b.purpose,
    ses.actual_start_time,
    ses.actual_end_time,
    ses.initial_condition,
    ses.final_condition
FROM sessions ses
JOIN bookings b ON b.booking_id = ses.booking_id
JOIN spaces s   ON s.space_code = b.space_code
JOIN users conductor ON conductor.user_id = ses.conductor_id
WHERE CAST(ses.actual_start_time AS DATE) = CAST(GETDATE() AS DATE)
ORDER BY ses.actual_start_time ASC;
```

---

### Query 17: Department Space Preferences

**Business Question:**  
Which departments book which types of spaces most frequently?

**Target Users:**  
Department Administrator, Facility Manager

**Why is it useful?**  
Reveals departmental preferences for space types, informing allocation policies and long-term space planning.

**SQL Implementation:**

```sql
SELECT
    u.department,
    s.space_type,
    COUNT(b.booking_id)                             AS bookings_count,
    RANK() OVER (PARTITION BY u.department
                 ORDER BY COUNT(b.booking_id) DESC) AS type_rank
FROM users u
JOIN bookings b ON b.requester_id = u.user_id
JOIN spaces s   ON s.space_code  = b.space_code
WHERE b.status NOT IN (N'rejected', N'cancelled')
GROUP BY u.department, s.space_type
ORDER BY u.department, type_rank;
```

---

### Query 18: Unresolved Maintenance Aging

**Business Question:**  
How long have current maintenance issues been open, and which spaces are affected?

**Target Users:**  
Facility Manager, Facility Staff

**Why is it useful?**  
Flags aging maintenance tickets that need priority attention, preventing prolonged space unavailability.

**SQL Implementation:**

```sql
SELECT
    mr.maintenance_id,
    s.space_code,
    s.space_name,
    s.building,
    s.room_number,
    mr.problem_description,
    mr.status,
    mr.start_time,
    DATEDIFF(DAY, mr.start_time, GETDATE())                  AS days_open,
    staff.first_name + N' ' + staff.last_name               AS assigned_staff,
    DATEDIFF(DAY, mr.start_time, GETDATE()) / 7              AS weeks_open,
    CASE
        WHEN DATEDIFF(DAY, mr.start_time, GETDATE()) >= 30 THEN N'critical'
        WHEN DATEDIFF(DAY, mr.start_time, GETDATE()) >= 14 THEN N'overdue'
        WHEN DATEDIFF(DAY, mr.start_time, GETDATE()) >= 7  THEN N'aging'
        ELSE N'normal'
    END AS aging_category
FROM maintenance_records mr
JOIN spaces s ON s.space_code = mr.space_code
JOIN users staff ON staff.user_id = mr.assigned_staff_id
WHERE mr.status IN (N'reported', N'in_progress')
ORDER BY days_open DESC;
```

---

### Query 19: Peak Booking Periods

**Business Question:**  
Which hours of the day and days of the week have the highest booking demand?

**Target Users:**  
Facility Manager

**Why is it useful?**  
Identifies peak demand periods so scheduling policies, staffing, and opening hours can be optimized.

**SQL Implementation:**

```sql
SELECT
    DATENAME(WEEKDAY, b.requested_start_time) AS day_of_week,
    DATEPART(HOUR, b.requested_start_time)    AS hour_of_day,
    COUNT(b.booking_id)                       AS booking_count
FROM bookings b
WHERE b.status NOT IN (N'rejected', N'cancelled')
  AND b.requested_start_time >= DATEADD(MONTH, -6, GETDATE())
GROUP BY
    DATENAME(WEEKDAY, b.requested_start_time),
    DATEPART(HOUR, b.requested_start_time)
ORDER BY
    CASE DATENAME(WEEKDAY, b.requested_start_time)
        WHEN N'Monday'    THEN 1
        WHEN N'Tuesday'   THEN 2
        WHEN N'Wednesday' THEN 3
        WHEN N'Thursday'  THEN 4
        WHEN N'Friday'    THEN 5
        WHEN N'Saturday'  THEN 6
        WHEN N'Sunday'    THEN 7
    END,
    DATEPART(HOUR, b.requested_start_time);
```

---

### Query 20: Lecturer Teaching Schedule

**Business Question:**  
What is a specific lecturer's teaching schedule for the current semester, including space details and session status?

**Target Users:**  
Lecturer, Teaching Assistant

**Why is it useful?**  
Gives lecturers a consolidated view of their upcoming teaching commitments with session details, enabling preparation and time management.

**SQL Implementation:**

```sql
DECLARE @LecturerId VARCHAR(50) = N'LECT001';  -- Placeholder for application parameter

SELECT
    b.booking_id,
    b.purpose,
    b.requested_start_time,
    b.requested_end_time,
    b.expected_participants,
    b.status                                AS booking_status,
    s.space_name,
    s.building,
    s.room_number,
    s.capacity,
    ses.session_id,
    ses.actual_start_time,
    ses.actual_end_time,
    ses.initial_condition,
    ses.final_condition,
    CASE
        WHEN ses.actual_start_time IS NOT NULL AND ses.actual_end_time IS NULL
            THEN N'in_progress'
        WHEN ses.actual_end_time IS NOT NULL
            THEN N'completed'
        ELSE N'not_started'
    END                                     AS session_status
FROM bookings b
JOIN spaces s ON s.space_code = b.space_code
LEFT JOIN sessions ses ON ses.booking_id = b.booking_id
WHERE b.requester_id = @LecturerId
  AND b.status IN (N'approved', N'checked_in', N'completed')
  AND b.requested_start_time >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
ORDER BY b.requested_start_time ASC;
```

---

## Summary

| #  | Query Title                       | Target Users                              | Tables Joined | Aggregation |
|----|-----------------------------------|-------------------------------------------|---------------|-------------|
| 1  | Space Utilization Report          | Facility Manager                          | 2             | COUNT, SUM, AVG |
| 2  | Pending Booking Approvals         | Facility Manager                          | 3             | None |
| 3  | My Upcoming Approved Bookings     | Student, Lecturer, TA                     | 3             | None |
| 4  | Overlapping Booking Detection     | Dept Admin, Facility Manager              | 4             | DISTINCT |
| 5  | Maintenance Resolution Time       | Facility Manager                          | 2             | COUNT, AVG, MAX |
| 6  | Space Facility Inventory          | Facility Staff, Student, Lecturer         | 3             | None |
| 7  | Active Maintenance Issues         | Facility Staff, Facility Manager          | 4             | DATEDIFF |
| 8  | Booking History by User           | Department Administrator                  | 5             | None |
| 9  | Popular Space Types               | Facility Manager, Dept Admin              | 2             | COUNT, SUM, AVG |
| 10 | Approval Statistics by Approver   | Facility Manager, Dept Admin              | 2             | COUNT, SUM, AVG |
| 11 | No-Show Rate by Department        | Department Administrator                  | 2             | COUNT, SUM, AVG |
| 12 | Space Capacity vs Participants    | Facility Manager                          | 3             | CASE |
| 13 | User Booking Frequency            | Department Administrator                  | 3             | COUNT, SUM, AVG |
| 14 | Cancelled Bookings Report         | Department Administrator                  | 2             | COUNT, AVG |
| 15 | Facility Demand Analysis          | Facility Manager                          | 2             | COUNT, SUM |
| 16 | Today's Active Sessions           | Facility Staff, Facility Manager          | 4             | None |
| 17 | Department Space Preferences      | Dept Admin, Facility Manager              | 3             | COUNT, RANK |
| 18 | Unresolved Maintenance Aging      | Facility Manager, Facility Staff          | 3             | DATEDIFF, CASE |
| 19 | Peak Booking Periods              | Facility Manager                          | 1             | COUNT, DATEPART |
| 20 | Lecturer Teaching Schedule        | Lecturer, TA                              | 3             | CASE |

---

## Target User Coverage

| Target User           | Query Count | Query IDs                |
|-----------------------|-------------|--------------------------|
| Student               | 2           | 3, 6                     |
| Lecturer              | 3           | 3, 6, 20                 |
| Teaching Assistant    | 2           | 3, 20                    |
| Facility Staff        | 3           | 6, 7, 16, 18             |
| Facility Manager      | 12          | 1, 2, 4, 5, 7, 9, 10, 12, 15, 16, 18, 19 |
| Department Admin      | 8           | 4, 8, 9, 10, 11, 13, 14, 17 |

**Total queries:** 20  
**Distinct target users:** 6 (Student, Lecturer, Teaching Assistant, Facility Staff, Facility Manager, Department Administrator)
