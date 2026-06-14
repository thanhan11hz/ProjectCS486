# Business Requirement Analysis

## 1. Business Purpose

### Problem Statement

The School of Computer Science manages several shared physical spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, and student workspaces) used for teaching, seminars, examinations, workshops, student projects, research activities, and academic events. Currently, requests to use these spaces are handled manually via email, phone, or in-person visits. Facility staff check spreadsheets or shared calendars to determine availability, eligibility, equipment needs, and maintenance status. As the volume of classes, projects, workshops, seminars, and events grows, the manual process has become difficult to manage.

### System Purpose

The proposed database system will manage space booking, approval, usage sessions, maintenance, incident reporting, and facility utilization for the School of Computer Science. It will replace the manual workflow with a structured, automated system that enforces business rules and maintains a complete audit trail.

### Expected Outcomes

- Elimination of double-booked spaces
- Prevention of booking unavailable spaces (under maintenance, closed, or retired)
- Streamlined booking request and approval workflow
- Centralized maintenance tracking
- Historical records for reporting and analysis
- Fair and transparent space allocation

---

## 2. Actors

| Actor | Description | Responsibilities |
| ----- | ----------- | ---------------- |
| Student | A learner enrolled in the School of Computer Science | Submit booking requests for student activities; use booked spaces |
| Lecturer | A teaching faculty member | Submit booking requests for lectures, examinations, seminars |
| Teaching Assistant | Assists in teaching activities | Submit booking requests for tutorials, labs, or review sessions |
| Facility Staff | School staff who manage physical spaces | Check in / check out bookings; record maintenance; approve or reject bookings |
| Department Administrator | Administrative staff | Oversee booking policies; generate reports |
| Facility Manager | Manager of facility operations | Define space policies; assign maintenance staff; override approvals |

---

## 3. Candidate Entities

| Entity | Description | Justification |
| ------ | ----------- | ------------- |
| User | Individuals who interact with the system (students, lecturers, TAs, staff, administrators, managers) | Business rules require storing user identity, role, department, and account status |
| Space | A bookable physical location such as a classroom, lab, meeting room, or auditorium | Core resource being managed; has attributes like type, capacity, location, status, and policy |
| Facility | An equipment item or amenity available in a space (e.g., projector, whiteboard, microphone) | Requirements state each space may have several facilities; tracked independently for inventory |
| SpaceFacility | Association between a space and its installed facilities | Resolves the many-to-many relationship between Space and Facility |
| Booking | A request to reserve a space for a specific time period | Central transaction of the system; tracks requester, space, time, purpose, participants, and status |
| BookingApproval | The decision (approve/reject) on a booking request | Requirements mandate recording the approving staff, decision time, and note |
| BookingCheckIn | Record of the requester's arrival and space handover | Requirements specify recording actual start time, check-in person, and initial condition |
| BookingCheckOut | Record of session completion and space handback | Requirements specify recording actual end time, final condition, and usage notes |
| Maintenance | A problem report and resolution record for a space | Requirements specify tracking problems, reporter, assigned staff, dates, status, and result |

---

## 4. Relationships

| Relationship | Participating Entities | Description |
| ------------ | ---------------------- | ----------- |
| Makes | User → Booking | A user submits a booking request |
| Books | Space ← Booking | A booking is for a specific space |
| Contains | Space → SpaceFacility ← Facility | A space contains facilities; a facility may be installed in multiple spaces |
| Decides | Booking → BookingApproval ← User | A staff member approves or rejects a booking |
| Checks in | Booking → BookingCheckIn ← User | A staff member checks in a booking upon arrival |
| Checks out | Booking → BookingCheckOut ← User | A staff member completes a booking after the session ends |
| Reports | User → Maintenance | A user reports a maintenance issue |
| Assigned to | Maintenance ← User | A staff member is assigned to resolve a maintenance issue |
| Undergoes | Space ← Maintenance | A space may have maintenance records |

---

## 5. Attributes

### Entity: User

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| user_id | Unique identifier | Primary key |
| full_name | User's full name | |
| email | University email address | Unique, required |
| phone | Contact phone number | Optional |
| role | User role (student, lecturer, TA, facility_staff, admin, manager) | Enum |
| department | Department affiliation | |
| account_status | Active, suspended, disabled | Default: active |

### Entity: Space

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| space_code | Unique code for the space | Primary key |
| space_name | Descriptive name | |
| space_type | auditorium, classroom, computer_lab, project_lab, meeting_room, workspace | Enum |
| building | Building name or code | |
| floor | Floor number | |
| room_number | Room identifier within the building | |
| capacity | Maximum occupancy | Positive integer |
| current_status | available, in_use, under_maintenance, temporarily_closed, retired | Enum |
| usage_policy | Rules governing space use | Free text |

### Entity: Facility

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| facility_id | Unique identifier | Primary key |
| facility_name | Name (e.g., projector, whiteboard) | |
| description | Optional description | |

### Entity: SpaceFacility

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| space_code | Reference to Space | Composite PK, FK |
| facility_id | Reference to Facility | Composite PK, FK |
| quantity | Count of this facility in the space | Default: 1 |

### Entity: Booking

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| booking_id | Unique identifier | Primary key |
| requester_id | Reference to User | FK |
| space_code | Reference to Space | FK |
| requested_start | Intended start datetime | |
| requested_end | Intended end datetime | Must be after start |
| purpose | Description of intended use | |
| participant_count | Expected number of participants | |
| booking_type | lecture, examination, seminar, workshop, meeting, student_activity, admin_event | Enum |
| status | pending, approved, rejected, cancelled, checked_in, completed, no_show | Enum |
| created_at | Timestamp of submission | Auto-generated |

### Entity: BookingApproval

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| approval_id | Unique identifier | Primary key |
| booking_id | Reference to Booking | FK, unique (1:1) |
| approver_id | Reference to User (staff) | FK |
| decision | approved, rejected | |
| decision_time | Timestamp of decision | |
| decision_note | Optional note | |
| rejection_reason | Required if rejected | |

### Entity: BookingCheckIn

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| checkin_id | Unique identifier | Primary key |
| booking_id | Reference to Booking | FK, unique (1:1) |
| checked_by | Reference to User (staff) | FK |
| actual_start_time | Actual start datetime | |
| initial_condition | Condition of space upon arrival | Free text |

### Entity: BookingCheckOut

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| checkout_id | Unique identifier | Primary key |
| booking_id | Reference to Booking | FK, unique (1:1) |
| checked_by | Reference to User (staff) | FK |
| actual_end_time | Actual end datetime | |
| final_condition | Condition of space after use | Free text |
| usage_notes | Any notes about the session | |

### Entity: Maintenance

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| maintenance_id | Unique identifier | Primary key |
| space_code | Reference to Space | FK |
| reporter_id | Reference to User | FK |
| assigned_to | Reference to User (staff) | FK, nullable |
| problem_description | Description of the issue | |
| start_time | When maintenance was reported | |
| completion_time | When maintenance was completed | Nullable |
| status | reported, assigned, in_progress, completed, cancelled | Enum |
| result_note | Summary of work done | Nullable |

### Relationship: (none of the relationships carry additional attributes beyond the foreign keys captured above)

---

## 6. Cardinalities

| Relationship | Cardinality | Justification |
| ------------ | ----------- | ------------- |
| User → Booking | (1) → (N) | A user can make many bookings; a booking belongs to one user |
| Space → Booking | (1) → (N) | A space can have many bookings (over time); a booking is for one space |
| Space → SpaceFacility → Facility | (1) → (N) ← (1), (1) ← (N) ← (1) | A space can have many facilities; a facility can be installed in many spaces |
| Booking → BookingApproval | (1) → (1) | Each booking has at most one approval decision |
| Booking → BookingCheckIn | (1) → (1) | Each booking has at most one check-in record |
| Booking → BookingCheckOut | (1) → (1) | Each booking has at most one checkout record |
| User → BookingApproval | (1) → (N) | A staff member can approve/reject many bookings |
| User → BookingCheckIn | (1) → (N) | A staff member can check in many bookings |
| User → BookingCheckOut | (1) → (N) | A staff member can check out many bookings |
| User → Maintenance (reporter) | (1) → (N) | A user can report many maintenance issues |
| User → Maintenance (assigned) | (1) → (N) | A staff member can be assigned to many maintenance issues |
| Space → Maintenance | (1) → (N) | A space can have many maintenance records |

---

## 7. Business Rules

### Explicit Business Rules

| Rule ID | Rule |
| ------- | ---- |
| BR-01 | The same space cannot have two approved bookings with overlapping time periods. |
| BR-02 | A space that is under maintenance, temporarily closed, or retired cannot be booked. |
| BR-03 | Every user must have a university account with a valid email. |
| BR-04 | A booking request must specify a space, start time, end time, purpose, and participant count. |
| BR-05 | The end time of a booking must be after the start time. |
| BR-06 | Booking statuses are limited to: pending, approved, rejected, cancelled, checked in, completed, no-show. |
| BR-07 | Space statuses are limited to: available, in use, under maintenance, temporarily closed, retired. |
| BR-08 | Booking types are limited to: lecture, examination, seminar, workshop, meeting, student activity, administrative event. |
| BR-09 | When a booking is approved or rejected, the system must record the staff member, decision time, and decision note. |
| BR-10 | If a booking is rejected, the rejection reason must be stored. |
| BR-11 | Check-in records must include the actual start time, the person who checked in, and the initial condition of the space. |
| BR-12 | Check-out records must include the actual end time, the final condition of the space, and usage notes. |
| BR-13 | A maintenance record must include the related space, reporter, problem description, start time, and status. |
| BR-14 | A space that is under maintenance cannot be booked (enforced by BR-02). |
| BR-15 | User roles are limited to: student, lecturer, teaching assistant, facility staff, department administrator, facility manager. |

### Derived Business Rules

| Rule ID | Rule |
| ------- | ---- |
| DR-01 | A booking can only transition from pending to approved or rejected. From approved it can go to checked in. From checked in to completed. Any state can go to cancelled. Pending bookings that pass their start time without check-in become no-show. |
| DR-02 | Only facility staff and facility managers can approve or reject bookings. |
| DR-03 | Only facility staff can perform check-in and check-out. |
| DR-04 | A booking status change to "under maintenance" on a space should cancel all future approved bookings for that space during the maintenance period (cross-cutting concern with Maintenance). |

---

## 8. Assumptions and Ambiguities

### Assumptions

| ID | Assumption |
| -- | ---------- |
| A-01 | A booking's check-in and check-out are optional (not all bookings result in actual use). |
| A-02 | The approval is a 1:1 relationship — a booking is approved/rejected once, not by multiple approvers. |
| A-03 | A user's role determines what actions they can perform (e.g., only staff can approve/check in/check out). |
| A-04 | The system does not handle recurring bookings; each instance is a separate booking. |
| A-05 | Facility items are managed as a master list; spaces reference this list via SpaceFacility. |
| A-06 | Maintenance assignment links to a User record (the assigned staff member). |

### Ambiguities

| ID | Requirement Area | Possible Interpretations | Selected Interpretation | Justification |
| -- | ---------------- | ----------------------- | ----------------------- | ------------- |
| AM-01 | Booking approval workflow | (a) All bookings require approval; (b) only certain booking types require approval; (c) approval is optional | All bookings require approval | Simplifies the design; approval can be auto-approved in future enhancements |
| AM-02 | Check-in/check-out mandatory | (a) Every booking must have check-in and check-out; (b) check-in/out is optional | Check-in/out is optional | Realistically, some bookings may not show up or may not complete formalities |
| AM-03 | Overlap detection scope | (a) Only approved bookings conflict; (b) all non-cancelled bookings conflict | Only approved bookings conflict | Pending/rejected bookings do not occupy the space; matches BR-01 phrasing |

---

## 9. Validation Summary

* [x] Business purpose identified
* [x] Actors identified
* [x] Entities identified
* [x] Attributes identified
* [x] Relationships identified
* [x] Cardinalities identified
* [x] Business rules identified
* [x] Assumptions documented
* [x] Ambiguities documented
