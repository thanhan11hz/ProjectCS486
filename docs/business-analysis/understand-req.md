# Business Requirement Understanding

## 1. Business Context

### Domain

School of Computer Science — manages shared physical spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, and student workspaces) used for teaching, seminars, examinations, workshops, student projects, research activities, and academic events.

### Current Situation

Requests to use shared spaces are handled manually. Lecturers, teaching assistants, students, and staff contact the school office or facility staff by email, phone, or in person. Facility staff then check spreadsheets or shared calendars to determine room availability, whether the requester is allowed to use it, whether special equipment is needed, and whether the room is under maintenance.

### Problems and Pain Points

- Manual process is becoming difficult to manage as the number of classes, student projects, workshops, seminars, and academic events increases.
- No automated conflict detection — overlapping bookings can occur.
- Room availability is not visible in real time.
- Unavailable spaces (under maintenance, closed, or retired) can be booked accidentally.
- Usage history is fragmented across spreadsheets and shared calendars.

### Need for the Proposed System

The School requires a centralized database system to manage space booking, approval, usage sessions, maintenance, incident reporting, and facility utilization — replacing manual coordination with structured, conflict-free scheduling and reliable historical record keeping.

---

## 2. Business Purpose

### Primary Purpose

Develop a database system to manage the booking and usage of shared campus spaces such as classrooms, computer laboratories, meeting rooms, and auditoriums.

### Supporting Purposes

- Manage booking requests, approval/rejection workflows, check-in, and check-out processes.
- Track space maintenance, facility availability, and incident reporting.
- Preserve historical records of bookings and maintenance activities for reporting and planning.
- Prevent overlapping approved bookings and prevent booking of unavailable spaces.

---

## 3. Expected Outcomes

### Operational Outcomes

- Prevent overlapping approved bookings for the same space.
- Prevent booking of spaces that are under maintenance, closed, or retired.
- Enable staff to view upcoming bookings, booking history, spaces under maintenance, and no-show bookings.
- Record decision audit trail (who approved/rejected, when, and why, including rejection reason).

### Business Outcomes

- Fair and transparent allocation of shared campus spaces.
- Reduced administrative overhead from manual coordination via email, phone, and spreadsheets.
- Reliable usage history for reporting, planning, and utilization analysis.

### System Capabilities

- User account management with roles: student, lecturer, teaching assistant, facility staff, department administrator, facility manager.
- Space catalog with unique space code, name, type, building, floor, room number, capacity, current status, and usage policy.
- Facility inventory per space (projector, whiteboard, microphone, computer, livestreaming equipment, air conditioner, etc.).
- Booking request submission with space, requested time period, purpose, and participant count.
- Booking approval/rejection workflow with decision tracking (staff, time, note, rejection reason).
- Check-in recording (actual start time, person, initial space condition).
- Check-out recording (actual end time, final space condition, usage notes).
- Maintenance record management (space, reporter, assigned staff, problem description, start time, completion time, status, result note).
- Conflict detection to prevent double-booking and booking of unavailable spaces.

---

## 4. Actors

| Actor | Description | Responsibilities | System Interactions |
|---------|---------|---------|---------|
| Student | A university user who participates in academic activities and uses shared spaces | Submit booking requests for student activities; use booked spaces | Create booking requests; view own bookings |
| Lecturer | A university user responsible for teaching and academic events | Submit booking requests for lectures, examinations, seminars, workshops; use booked spaces | Create booking requests; view own bookings |
| Teaching Assistant | A university user who assists with teaching activities | Submit booking requests for academic sessions; use booked spaces | Create booking requests; view own bookings |
| Facility Staff | Staff responsible for managing space bookings and maintenance | Approve or reject booking requests; check in and check out bookings; record space condition; manage maintenance records | Process booking approvals; perform check-in/check-out; create and update maintenance records; view schedules and history |
| Department Administrator | A university user handling administrative activities | Submit booking requests for administrative events; use booked spaces | Create booking requests; view own bookings |
| Facility Manager | Senior staff who oversee the space management system | Approve or reject booking requests; oversee maintenance; manage system usage | Process booking approvals; view reports and history; manage spaces |

---

## 5. Major Business Activities

| Activity | Description | Participants |
|----------|------------|------------|
| Space Booking | Users submit booking requests for a specific space, requested time period, purpose, and expected participant count | All user roles (submit); Facility Staff and Facility Manager (process) |
| Booking Approval | Facility staff or manager reviews and approves or rejects a pending booking request, recording the decision, time, decision note, and rejection reason | Facility Staff, Facility Manager |
| Check-In | Facility staff records the actual start time, the person who checked in, and the initial condition of the space when the requester arrives | Facility Staff |
| Check-Out | Facility staff records the actual end time, final condition of the space, and usage notes when the session ends | Facility Staff |
| Maintenance Management | Facility staff records maintenance problems (broken equipment, cleaning, network, etc.), assigns staff, and tracks status and completion | Facility Staff |
| Usage Monitoring | Staff views booking history, upcoming bookings, spaces under maintenance, and no-show bookings | Facility Staff, Facility Manager |

---

## 6. Scope Summary

### In Scope

- User registration and role-based access (student, lecturer, teaching assistant, facility staff, department administrator, facility manager).
- Space catalog with unique code, name, type, building, floor, room number, capacity, status, and usage policy.
- Facility inventory listing per space (projector, whiteboard, microphone, computer, livestreaming equipment, air conditioner, etc.).
- Booking request creation with space, requested time period, purpose, and participant count.
- Booking approval/rejection workflow with decision audit trail (who, when, note, rejection reason).
- Check-in and check-out recording with actual times, responsible person, and space condition tracking.
- Maintenance record creation, assignment, and tracking linked to spaces.
- Conflict detection: no overlapping approved bookings for the same space; no booking of spaces under maintenance, closed, or retired.
- Historical record keeping for bookings and maintenance.
- Viewing capabilities: booking history, upcoming bookings, spaces under maintenance, no-show bookings.

### Out of Scope

- Direct integration with external calendar systems (e.g., Google Calendar, Outlook).
- Automated billing or payment processing for space usage.
- Real-time room occupancy sensors or IoT integration.
- Public-facing booking portal external to the university.
- Automated notifications or email reminders (not mentioned in requirements).
- Integration with university course scheduling or timetabling systems.
