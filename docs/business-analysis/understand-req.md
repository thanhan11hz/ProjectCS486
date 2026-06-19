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
- Historical record keeping for bookings and maintenance.

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
- Self-service check-in or check-out by the requester (only facility staff can perform these actions).

---

## 7. Requirement Ambiguities

| Requirement Statement | Reason for Ambiguity | Possible Interpretations | Impact | Recommended Interpretation |
| --------------------- | -------------------- | ------------------------ | ------ | -------------------------- |
| "A booking request may require approval from a facility staff member or manager." | The word "may" is ambiguous — it could indicate that approval is conditional on booking type, or it could simply describe who is authorized to approve. | (1) Every booking requires approval from either a facility staff member or manager. (2) Only certain booking types or certain spaces require approval; others are auto-approved. (3) "May" refers to who can approve (facility staff or manager), not whether approval is required. | Affects the approval workflow design, booking state machine, and business rules for when a booking transitions from pending to approved. | All bookings require approval from either a facility staff member or manager. The requirement lists approval as a core workflow step, and no exception or auto-approval path is described. |
| "The system must prevent conflicting bookings. The same space cannot have two approved bookings with overlapping time periods." | The requirement states approved bookings must not overlap, but does not address whether pending, cancelled, or rejected bookings factor into conflict detection. | (1) Conflict detection applies only to approved bookings; overlapping pending bookings are allowed. (2) Conflict detection applies to any active (non-cancelled, non-rejected) booking. | Affects booking conflict resolution logic and the booking state machine. | Conflict detection should apply to any approved booking. Pending, rejected, and cancelled bookings should not block new requests. |
| "When the requester arrives, facility staff can check in the booking." | Does not specify a time window for check-in or what happens if the requester does not arrive within a reasonable time. | (1) Check-in can occur at any time during the booked period. (2) There is an implied grace period after which the booking becomes a no-show. (3) No-show is triggered manually by staff observation. | Affects the no-show transition logic and booking lifecycle. | No-show should be a manual action performed by facility staff, consistent with the manual check-in/check-out pattern described. Clarification is recommended. |

---

## 8. Requirement Gaps

### Assumptions

| Assumption | Supporting Evidence | Reason | Risk if Incorrect |
| ---------- | ------------------- | ------ | ----------------- |
| A user may submit multiple booking requests. | No restriction on the number of bookings per user is specified. | Multiple bookings per user are common in space reservation scenarios. | Cardinality constraints and usage fairness policies may need adjustment if a per-user limit is introduced. |
| Booking lifecycle states follow the sequence: pending → approved/rejected → checked in → completed/no-show. | The requirement lists statuses but does not define permitted state transitions. | A lifecycle is needed for workflow design and database state management. | If the actual lifecycle includes additional transitions (e.g., modification after approval, re-submission after rejection), the state machine may need revision. |
| Facility staff and facility manager roles can both approve bookings and perform check-in/check-out. | The requirement states "a facility staff member or manager" for approval and "facility staff" for check-in/check-out. | The manager role is a senior staff role, so it likely inherits staff capabilities unless explicitly restricted. | If managers cannot perform check-in/check-out, the actor responsibility mapping must be revised. |

### Open Questions

| Question | Related Requirement | Why Clarification Is Needed | Impact |
| -------- | ------------------- | --------------------------- | ------ |
| Can an approved booking be modified after approval? | Booking Management | The booking lifecycle does not describe post-approval modifications. | May affect workflow analysis, status transitions, and later business rule derivation. |
| How is a maintenance staff member assigned to a maintenance record? | Maintenance Management | The requirement mentions "assigned staff member" but does not describe the assignment process. | Affects the maintenance workflow design and assignment business rules. |
| Is there a maximum duration or advance booking window for booking requests? | Booking Request | No restriction on booking duration or how far in advance a booking can be made is specified. | May affect data validation rules and conflict detection logic. |
| What happens when a booking is checked in late (after the requested start time)? | Check-In | The requirement does not address late arrivals or their effect on the booking. | Affects the check-in and no-show business rules. |
| Are facility staff allowed to submit booking requests for themselves, or do they only process requests from others? | Actors | The actor description does not explicitly state whether facility staff can also be requesters. | Affects actor capability mapping and access control rules. |

---

## 9. Analysis Notes

### Contradictions

| Conflict | Alternative Interpretations | Selected Interpretation | Justification |
| -------- | --------------------------- | ----------------------- | ------------- |
| No contradictions found. | — | — | The requirements are internally consistent. |

### Unresolved Issues

- The requirement mentions "incident reporting" in the need statement but does not describe any incident reporting process or data requirements. It is unclear whether this is a separate capability or part of maintenance management.

### Analyst Comments

- The requirement mentions roles (student, lecturer, teaching assistant, facility staff, department administrator, facility manager) but does not describe how roles are assigned or managed. This may need clarification in later stages.
- The space statuses (available, in use, under maintenance, temporarily closed, retired) may need a separate state machine definition to distinguish current operational status from booking-related status.
- The term "usage policy" is mentioned as an attribute of a space but is not defined. This may need to be clarified before implementation.
