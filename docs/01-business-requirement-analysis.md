# Business Requirement Analysis

## 1. Business Purpose

### Problem Statement

The School of Computer Science manages shared physical spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, and student workspaces). Currently, booking and management of these spaces is handled manually via email, phone, or in-person requests. Facility staff rely on spreadsheets and shared calendars to track availability. As the volume of classes, student projects, workshops, seminars, and academic events grows, the manual process has become difficult to manage, leading to scheduling conflicts, underutilization, and administrative overhead.

### System Purpose

Build a database system to manage space booking, approval workflows, usage session tracking, maintenance management, incident reporting, and facility utilization for the School of Computer Science.

### Expected Outcomes

- Enable fair and transparent management of shared campus spaces
- Prevent overlapping bookings and double-scheduling
- Block booking of unavailable spaces (under maintenance, closed, or retired)
- Preserve a complete historical record of bookings and maintenance activities
- Provide staff with visibility into booking history, upcoming bookings, spaces under maintenance, and no-show bookings

---

## 2. Actors

| Actor | Actor type | Description | Responsibilities |
| ----- | ---------- | ----------- | ---------------- |
| Requester | Parametric End User | A student, lecturer, or teaching assistant who needs to book a space for teaching, study, or events | Submits booking requests; views own bookings and booking history |
| Facility Staff | Casual End User | Staff members responsible for day-to-day facility operations | Approves or rejects booking requests; performs check-in and check-out; records maintenance issues; views reports |
| Facility Manager | Sophisticated End User | Senior staff member who oversees facility operations and staff | Manages user accounts and spaces; generates utilization reports; oversees facility staff; manages maintenance workflows |
| Department Administrator | Casual End User | Administrative staff from academic departments | May submit bookings on behalf of departments; views departmental booking history |

---

## 3. Entities

| Entity | Description | Justification |
| ------ | ----------- | ------------- |
| User | Individuals who interact with the booking system, including students, lecturers, teaching assistants, facility staff, department administrators, and the facility manager | Each user has a university account with stored information; users can submit bookings, approve requests, check in/out, and report maintenance |
| Space | Physical shared spaces managed by the School, such as auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, and student workspaces | Each space has unique identity (space code), physical attributes, current status, and usage policy; spaces are the central resource being managed |
| Facility | Types of equipment or amenities that may be available in a space, such as projectors, whiteboards, microphones, computers, livestreaming equipment, and air conditioners | The system must store which facilities are available in each space; facility types have independent identity and appear across multiple spaces |
| Booking | A request to use a space for a specific time period, tracking the full lifecycle from submission through approval, check-in, completion, or cancellation | Bookings are the core business transaction; they have identity and lifecycle; they connect users to spaces for specific time periods |
| MaintenanceRecord | A record of a maintenance problem reported for a space, tracking the issue from reporting through assignment to resolution | Maintenance records have independent identity, lifecycle, and status; they participate in relationships with space and users; they enforce business rules about space availability |

---

## 4. Relationships

| Relationship | Degree | Relationship Attributes | Participating Entities | Description |
| ------------ | ------ | ----------------------- | ---------------------- | ----------- |
| Submits | 1:N | None | User, Booking | A user submits zero or many booking requests; a booking is submitted by exactly one user |
| Concerns | 1:N | None | Space, Booking | A space is the subject of zero or many bookings; a booking concerns exactly one space |
| Approves | 1:N | decision_time, decision_note, rejection_reason | User (facility staff/manager), Booking | A facility staff member or manager approves or rejects zero or many bookings; a booking is approved or rejected by at most one staff member |
| Checks in | 1:N | actual_start_time, initial_condition | User (facility staff), Booking | A facility staff member checks in zero or many bookings; a booking is checked in by at most one staff member |
| Has facilities | M:N | None | Space, Facility | A space has zero or many facilities; a facility type may be present in zero or many spaces |
| Undergoes | 1:N | None | Space, MaintenanceRecord | A space undergoes zero or many maintenance activities; a maintenance record belongs to exactly one space |
| Reports | 1:N | None | User, MaintenanceRecord | A user reports zero or many maintenance issues; a maintenance record is reported by exactly one user |
| Is assigned to | 1:N | None | User (staff/manager), MaintenanceRecord | A facility staff member or manager is assigned to zero or many maintenance records; a maintenance record is assigned to at most one staff member |

---

## 5. Attributes

### Entity: User

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| user_id | Unique identifier for the user | Primary Key |
| full_name | User's full name | Mandatory |
| email | University email address | Mandatory, unique |
| phone | Contact phone number | Optional |
| role | User classification: student, lecturer, teaching_assistant, facility_staff, department_administrator, facility_manager | Mandatory, enumerated |
| department | Academic or administrative department | Mandatory |
| account_status | Whether the account is active or disabled | Mandatory, default active |

### Entity: Space

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| space_code | Unique code identifying the physical space | Primary Key |
| space_name | Descriptive name of the space | Mandatory |
| space_type | Classification: auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace | Mandatory, enumerated |
| building | Building where the space is located | Mandatory |
| floor | Floor number within the building | Mandatory |
| room_number | Room number or identifier | Mandatory |
| capacity | Maximum number of people the space can accommodate | Mandatory, positive integer |
| current_status | Availability status: available, in_use, under_maintenance, temporarily_closed, retired | Mandatory, enumerated |
| usage_policy | Text describing rules and guidelines for using the space | Optional |

### Entity: Facility

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| facility_id | Unique identifier for the facility type | Primary Key |
| facility_name | Name of the facility (e.g., Projector, Whiteboard, Microphone) | Mandatory, unique |
| description | Optional description of the facility | Optional |

### Entity: Booking

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| booking_id | Unique identifier for the booking request | Primary Key |
| requester_id | The user who submitted the booking | Foreign Key to User |
| space_code | The space being booked | Foreign Key to Space |
| requested_start_time | Desired start date and time | Mandatory |
| requested_end_time | Desired end date and time | Mandatory |
| purpose | Free-text description of the reason for booking | Mandatory |
| expected_participants | Number of people expected to attend | Mandatory, positive integer |
| booking_category | Category of use: lecture, examination, seminar, workshop, meeting, student_activity, administrative_event | Mandatory, enumerated |
| status | Current state: pending, approved, rejected, cancelled, checked_in, completed, no_show | Mandatory, enumerated |
| approver_id | The staff member who approved or rejected the booking | Foreign Key to User, nullable |
| decision_time | Date and time when the decision was made | Nullable |
| decision_note | Note or comment about the approval decision | Nullable |
| rejection_reason | Reason for rejection, required when status is rejected | Nullable |
| actual_start_time | The actual start time recorded during check-in | Nullable |
| check_in_staff_id | The staff member who performed the check-in | Foreign Key to User, nullable |
| initial_condition | Description of the space condition at check-in | Nullable |
| actual_end_time | The actual end time recorded during check-out | Nullable |
| final_condition | Description of the space condition at check-out | Nullable |
| usage_notes | Notes about the usage session | Nullable |

### Entity: MaintenanceRecord

| Attribute | Description | Notes |
| --------- | ----------- | ----- |
| record_id | Unique identifier for the maintenance record | Primary Key |
| space_code | The space requiring maintenance | Foreign Key to Space |
| reporter_id | The user who reported the problem | Foreign Key to User |
| assigned_staff_id | The staff member assigned to handle the issue | Foreign Key to User, nullable |
| problem_description | Description of the maintenance problem | Mandatory |
| problem_category | Type of problem: broken_projector, ac_failure, damaged_furniture, cleaning, network, other | Mandatory, enumerated |
| start_time | Date and time when the maintenance was reported or started | Mandatory |
| completion_time | Date and time when the maintenance was completed | Nullable |
| status | Current state: reported, assigned, in_progress, completed, cancelled | Mandatory, enumerated |
| result_note | Notes about the resolution or outcome | Nullable |

---

## 6. Cardinalities

| Relationship | Cardinality | Justification |
| ------------ | ----------- | ------------- |
| User - Booking | 1:N | A user may submit multiple booking requests; each booking is submitted by exactly one user |
| Space - Booking | 1:N | A space may have multiple booking requests over time; each booking is for exactly one space |
| User (staff) - Booking (approval) | 1:N | A staff member may approve or reject multiple bookings; each booking is approved/rejected by at most one staff member |
| User (staff) - Booking (check-in) | 1:N | A staff member may check in multiple bookings; each booking is checked in by at most one staff member |
| Space - Facility | M:N | A space may have several facilities; a facility type may exist in multiple spaces |
| Space - MaintenanceRecord | 1:N | A space may undergo multiple maintenance activities over time; each maintenance record belongs to exactly one space |
| User - MaintenanceRecord (reporter) | 1:N | A user may report multiple maintenance issues; each record has exactly one reporter |
| User - MaintenanceRecord (assigned) | 1:N | A staff member may be assigned to multiple maintenance records; each record may be assigned to at most one staff member |

---

## 7. Business Rules

### Explicit Business Rules

| Rule ID | Rule |
| ------- | ---- |
| BR-01 | The same space cannot have two approved bookings with overlapping time periods. |
| BR-02 | A space that is under maintenance, closed, or retired cannot be booked. |
| BR-03 | Each user must have a university account to use the system. |
| BR-04 | A booking request may require approval from a facility staff member or manager before it becomes valid. |
| BR-05 | When a booking is approved or rejected, the system must record the staff member who made the decision, the decision time, and a decision note. |
| BR-06 | If a booking is rejected, the rejection reason must be stored. |
| BR-07 | When a booking is checked in, the system must record the actual start time, the person who checked in, and the initial condition of the space. |
| BR-08 | When a booking session ends, the system must record the actual end time, the final condition of the space, and any usage notes. |
| BR-09 | A space under maintenance cannot be booked (no new approved bookings with overlapping time). |
| BR-10 | The system must preserve historical records of bookings and maintenance activities. |

### Derived Business Rules

| Rule ID | Rule |
| ------- | ---- |
| DR-01 | A booking can only transition to "checked_in" status if its current status is "approved". |
| DR-02 | A booking can only transition to "completed" status if its current status is "checked_in". |
| DR-03 | A booking can only transition to "no_show" status if its current status is "approved" and the check-in window has passed without a check-in. |
| DR-04 | A booking with status "cancelled" can only be cancelled by the requester or by a facility staff member. |
| DR-05 | A maintenance record can only be assigned to a staff member who has the role "facility_staff" or "facility_manager". |
| DR-06 | A space's current_status must be "available" for a new booking to be approved. |
| DR-07 | A booking decision (approve/reject) can only be made by a user whose role is "facility_staff" or "facility_manager". |
| DR-08 | A check-in or check-out operation can only be performed by a user whose role is "facility_staff" or "facility_manager". |
| DR-09 | A user's account must be active (account_status = active) to submit a booking request or report maintenance. |
| DR-10 | The number of expected participants must not exceed the space capacity. |

---

## 8. Assumptions and Ambiguities

### Assumptions

| ID | Assumption |
| -- | ---------- |
| A-01 | A booking in "pending" status requires approval; an approved booking has status "approved". The approval process is handled by facility staff or manager. |
| A-02 | The facility assignment (which facilities are in which spaces) is managed as a many-to-many relationship, representing presence or absence of each facility type (not quantity). |
| A-03 | Booking status transitions follow a linear lifecycle: pending -> approved -> checked_in -> completed. Cancellation and rejection can occur at multiple points. No-show applies when an approved booking was not checked in. |
| A-04 | Existing bookings that overlap with a maintenance period are not automatically cancelled; they require manual handling (notification, rescheduling). |
| A-05 | The system does not handle recurring bookings; each booking is for a single time period. |
| A-06 | Space codes are assigned by the School and are unique across all buildings. |

### Ambiguities

| ID | Requirement Area | Possible Interpretations | Selected Interpretation | Justification |
| -- | ---------------- | ----------------------- | ----------------------- | ------------- |
| AM-01 | Approval requirement | 1. All bookings require approval. 2. Only bookings from certain user roles require approval. 3. Only bookings for certain space types or time ranges require approval. | All bookings require approval. | Simplest interpretation consistent with the requirement that the system tracks approval decisions. The requirement states "may require approval" but does not specify criteria for exemption. |
| AM-02 | Facility quantities | 1. Facility assignment records only presence/absence of a facility type. 2. Facility assignment records quantity (e.g., "30 computers"). | Facility assignment records only presence/absence. | The requirement mentions facility types but does not mention quantities. Quantities can be added later if needed. |
| AM-03 | Booking cancellation | 1. Only the requester can cancel their own booking. 2. Facility staff can cancel any booking. 3. Both. | Both requester and facility staff can cancel a booking, with appropriate tracking. | Reasonable operational policy; system should track who performed the cancellation. |
| AM-04 | Reporting vs. maintenance workflow | 1. Any user can report a problem directly as a maintenance record. 2. Problems are reported to facility staff who then create maintenance records. | Any user can report a problem, but the maintenance record is formally created by facility staff. | The requirement mentions "reporter" on the maintenance record, suggesting any user can report. However, facility staff likely manages the formal record. |
| AM-05 | Overlapping maintenance and bookings | 1. The system automatically prevents any new booking that overlaps with any maintenance period. 2. The system only prevents bookings when space status is "under_maintenance". | The system prevents bookings based on space status, not by checking individual maintenance periods. | The requirement explicitly states "A space under maintenance cannot be booked" referring to space status. The maintenance record updates the space status, which then blocks new bookings. |

---

## 9. Validation Summary

- [x] Business purpose identified
- [x] Actors identified
- [x] Entities identified
- [x] Attributes identified
- [x] Relationships identified
- [x] Cardinalities identified
- [x] Business rules identified
- [x] Assumptions documented
- [x] Ambiguities documented
