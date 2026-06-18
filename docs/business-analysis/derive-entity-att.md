# Entity and Attribute Analysis

## 1. Analysis Summary

### Business Domain Overview

- **What the system manages**: Shared campus spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, student workspaces) and their booking, usage, and maintenance.
- **Main business activities**: Submitting booking requests, approving/rejecting bookings, checking in and completing sessions, reporting and resolving maintenance issues.
- **Main business records**: Booking requests (with full lifecycle from submission to completion) and maintenance records (from reporting to resolution).
- **Important information that must be stored**: User accounts and profiles, space details and status, booking history with decisions and session logs, maintenance history, and facility equipment lists.

---

## 2. Candidate Concepts

| Concept | Requirement Evidence | Initial Category |
| ------- | -------------------- | ---------------- |
| User | "Each user must have a university account. The system stores basic user information…" | Business Object |
| Space | "The School manages many bookable spaces. For each space, the system stores a unique space code…" | Business Object |
| Facility | "Each space may have several facilities… The system should store the list of facilities available in each space." | Attribute Candidate |
| Booking | "Users can submit booking requests by selecting a space…" | Business Record |
| Approval | "A booking request may require approval from a facility staff member or manager." | Workflow Step |
| Check In | "When the requester arrives, facility staff can check in the booking." | Workflow Step |
| Completion | "When the session ends, facility staff can complete the booking…" | Workflow Step |
| Maintenance Record | "A space may have maintenance records for problems such as broken projectors…" | Business Record |
| Account Status | "…account status." | Attribute Candidate |
| Space Status | "…current status…" | Attribute Candidate |
| Booking Status | "Each booking request has a status, such as pending, approved…" | Attribute Candidate |
| Student | "A user may be a student…" | Classification Value |
| Lecturer | "…lecturer…" | Classification Value |
| Teaching Assistant | "…teaching assistant…" | Classification Value |
| Facility Staff | "…facility staff…" | Classification Value |
| Department Administrator | "…department administrator…" | Classification Value |
| Facility Manager | "…facility manager." | Classification Value |
| Available | "A space may be available…" | Status Value |
| In Use | "…in use…" | Status Value |
| Under Maintenance | "…under maintenance…" | Status Value |
| Temporarily Closed | "…temporarily closed…" | Status Value |
| Retired | "…or retired." | Status Value |
| Pending | "…pending…" | Status Value |
| Approved | "…approved…" | Status Value |
| Rejected | "…rejected…" | Status Value |
| Cancelled | "…cancelled…" | Status Value |
| Checked In | "…checked in…" | Status Value |
| Completed | "…completed…" | Status Value |
| No-show | "…or no-show." | Status Value |

---

## 3. Accepted Entities

| Entity | Entity Type | Justification |
| ------ | ----------- | ------------- |
| User | Business Object | Users are independently managed by the organization through university accounts. They participate in multiple business processes: submitting bookings, approving/rejecting requests, checking in sessions, and reporting maintenance issues. User information (name, email, role, department, status) must be stored and retrieved independently. |
| Space | Business Object | Spaces are managed physical resources with unique identity (space code), type classification, location attributes, capacity, and usage policy. Spaces have a status lifecycle (available, in use, under maintenance, closed, retired) that affects their ability to be booked. They are referenced by both bookings and maintenance records. |
| Booking | Business Record | Booking requests follow a complete business lifecycle: submission, approval/rejection, check-in, completion, cancellation, or no-show. Each booking has a status that transitions over time, and the system must prevent conflicting bookings and preserve historical records for reporting. |
| Maintenance Record | Business Record | Maintenance records track facility problems from reporting through resolution. Each record has a lifecycle (status transitions), is independently stored, and is auditable. Maintenance records reference a space, a reporter, and an assigned staff member. |

---

## 4. Rejected Concepts

| Concept | Classification | Reason for Rejection | Violated Rule |
| ------- | -------------- | -------------------- | ------------- |
| Approval | Workflow Step | Represents a decision event in the Booking lifecycle rather than an independent business object. The approval information (who decided, when, notes) is stored as attributes of Booking. | Rule 3 — does not have an independent lifecycle. |
| Check In | Workflow Step | Represents a lifecycle event of Booking (arrival of requester). The information (actual start time, person who checked in, initial condition) belongs to Booking. | Rule 3 — does not have an independent lifecycle. |
| Completion | Workflow Step | Represents a lifecycle event of Booking (end of session). The information (actual end time, final condition, usage notes) belongs to Booking. | Rule 3 — does not have an independent lifecycle. |
| Facility | Attribute Candidate | The list of facilities describes the equipment available in a space rather than an independently managed business object. The requirements do not specify facility lifecycle, individual tracking, or cross-space portability. | Rule 4 — information that merely describes another object is not an entity. |
| Student | Classification Value | Represents a role value within the User entity rather than a separate business object. | Rule 5 — classification values are not entities. |
| Lecturer | Classification Value | Represents a role value within the User entity. | Rule 5 — classification values are not entities. |
| Teaching Assistant | Classification Value | Represents a role value within the User entity. | Rule 5 — classification values are not entities. |
| Facility Staff | Classification Value | Represents a role value within the User entity. | Rule 5 — classification values are not entities. |
| Department Administrator | Classification Value | Represents a role value within the User entity. | Rule 5 — classification values are not entities. |
| Facility Manager | Classification Value | Represents a role value within the User entity. | Rule 5 — classification values are not entities. |
| Pending | Status Value | Represents a booking status value rather than an entity. | Rule 5 — status values are not entities. |
| Approved | Status Value | Represents a booking status value. | Rule 5 — status values are not entities. |
| Rejected | Status Value | Represents a booking status value. | Rule 5 — status values are not entities. |
| Cancelled | Status Value | Represents a booking status value. | Rule 5 — status values are not entities. |
| Checked In | Status Value | Represents a booking status value. | Rule 5 — status values are not entities. |
| Completed | Status Value | Represents a booking status value. | Rule 5 — status values are not entities. |
| No-show | Status Value | Represents a booking status value. | Rule 5 — status values are not entities. |
| Available | Status Value | Represents a space status value. | Rule 5 — status values are not entities. |
| In Use | Status Value | Represents a space status value. | Rule 5 — status values are not entities. |
| Under Maintenance | Status Value | Represents a space status value. | Rule 5 — status values are not entities. |
| Temporarily Closed | Status Value | Represents a space status value. | Rule 5 — status values are not entities. |
| Retired | Status Value | Represents a space status value. | Rule 5 — status values are not entities. |

---

## 5. Entity Attributes

### Entity: User

#### Description

A person who holds a university account and interacts with the space management system. Users may have different roles (student, lecturer, teaching assistant, facility staff, department administrator, facility manager) that determine their permissions and responsibilities.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| user_id | Unique identifier for each user within the university system (requirement: "user ID"). |
| full_name | User's full name for identification (requirement: "full name"). |
| email | University email address for communication (requirement: "email"). |
| phone_number | Contact phone number (requirement: "phone number"). |
| role | Classification of the user's relationship to the School (requirement: "role"). Values: student, lecturer, teaching assistant, facility staff, department administrator, facility manager. |
| department | Academic or administrative department the user belongs to (requirement: "department"). |
| account_status | Whether the account is active or suspended (requirement: "account status"). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| *None* | All user-related information from the requirements is treated as descriptive attributes. |

---

### Entity: Space

#### Description

A physical room or area managed by the School of Computer Science that can be booked for teaching, seminars, examinations, workshops, student projects, research activities, and academic events.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| space_code | Unique alphanumeric code identifying the space (requirement: "unique space code"). |
| space_name | Readable name of the space (requirement: "space name"). |
| space_type | Classification of the space type (requirement: "space type"). Values: auditorium, classroom, computer laboratory, project laboratory, meeting room, student workspace. |
| building | Building where the space is located (requirement: "building"). |
| floor | Floor level within the building (requirement: "floor"). |
| room_number | Room number or identifier within the building (requirement: "room number"). |
| capacity | Maximum number of people the space can accommodate (requirement: "capacity"). |
| current_status | Current operational status of the space (requirement: "current status"). Values: available, in use, under maintenance, temporarily closed, retired. |
| usage_policy | Rules or guidelines governing how the space may be used (requirement: "usage policy"). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| facilities list | Descriptive list of equipment available in the space. Identified as an attribute candidate rather than a separate entity (see Rejected Concepts). |

---

### Entity: Booking

#### Description

A request to use a campus space for a specific time period and purpose. A booking progresses through a lifecycle: pending → approved/rejected → checked in → completed, or alternatively to cancelled or no-show.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| booking_id | Unique identifier for the booking request. |
| requested_start_time | The date and time the requester wants the booking to begin (requirement: "requested start time"). |
| requested_end_time | The date and time the requester wants the booking to end (requirement: "requested end time"). |
| purpose | The type or reason for the booking (requirement: "purpose of use"). Values: lecture, examination, seminar, workshop, meeting, student activity, administrative event. |
| expected_participants | Number of people expected to attend (requirement: "expected number of participants"). |
| status | Current state of the booking (requirement: "status"). Values: pending, approved, rejected, cancelled, checked in, completed, no-show. |
| decision_time | The date and time when the booking was approved or rejected (requirement: "decision time"). |
| decision_note | Note recorded by the staff member when making the decision (requirement: "decision note"). |
| rejection_reason | Specific reason provided if the booking was rejected (requirement: "rejection reason should be stored"). |
| actual_start_time | The actual time the session began, recorded at check-in (requirement: "actual start time"). |
| actual_end_time | The actual time the session ended, recorded at completion (requirement: "actual end time"). |
| initial_condition | Condition of the space at check-in time (requirement: "initial condition of the space"). |
| final_condition | Condition of the space at completion time (requirement: "final condition of the space"). |
| usage_notes | Notes recorded by staff about the usage session (requirement: "any usage notes"). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| requester | Relationship candidate — references a User who submitted the booking. |
| space | Relationship candidate — references the Space being booked. |
| approved_by / rejected_by | Relationship candidate — references the User (staff member) who made the decision. |
| checked_in_by | Relationship candidate — references the User who performed the check-in. |
| completed_by | Relationship candidate — references the User who performed the completion. |

---

### Entity: Maintenance Record

#### Description

A record of a problem or issue with a space that requires resolution, tracked from reporting through to completion.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| maintenance_id | Unique identifier for the maintenance record. |
| problem_description | Description of the issue (requirement: "problem description"). Examples: broken projector, air-conditioning failure, damaged furniture, cleaning issue, network problem. |
| start_time | The date and time the problem was reported or maintenance began (requirement: "start time"). |
| completion_time | The date and time maintenance was completed (requirement: "completion time"). |
| status | Current state of the maintenance record (requirement: "status"). |
| result_note | Note describing the outcome of the maintenance work (requirement: "result note"). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| space | Relationship candidate — references the Space under maintenance. |
| reporter | Relationship candidate — references the User who reported the problem. |
| assigned_staff | Relationship candidate — references the User assigned to resolve the problem. |

---

## 6. Workflow Consolidation Decisions

| Workflow Concepts | Consolidated Entity | Justification |
| ----------------- | ------------------ | ------------- |
| Approval, Check In, Completion | Booking | All three represent lifecycle events or status transitions of a Booking. Approval is the decision step that changes status from pending to approved or rejected. Check In records the actual start of the session. Completion records the end of the session. None have independent lifecycle or business meaning outside the Booking they belong to. |

---

## 7. Assumptions

| ID | Assumption | Justification |
| -- | ---------- | ------------- |
| A-01 | Facility information describes space equipment rather than independently tracked assets. | The requirements state "store the list of facilities available in each space" without specifying individual facility lifecycle, maintenance tracking, or cross-space portability. Facilities are therefore treated as descriptive attributes of a space. |
| A-02 | Approval, check-in, and completion are lifecycle events of Booking, not separate business records. | The requirements describe these as actions performed on a booking with no evidence of independent management, separate auditing, or independent lifecycle. |
| A-03 | The "purpose of use" for a booking is a classification value drawn from a controlled list. | The requirements enumerate purpose types (lecture, examination, seminar, workshop, meeting, student activity, administrative event), suggesting a constrained set of values rather than free text. |
| A-04 | Maintenance record status values are predefined but not enumerated in the requirements. | The requirements mention "status" for maintenance records without listing possible values. Reasonable values include: reported, in progress, completed, cancelled. |

---

## 8. Unresolved Questions

| ID | Question | Potential Impact |
| -- | -------- | ---------------- |
| Q-01 | Should the "list of facilities available in each space" be a free-text description, a controlled vocabulary, or a set of individually tracked equipment items? | Affects whether Facility becomes an entity or an attribute, and whether later stages require an associative table for space-facility assignments. |
| Q-02 | What are the valid values for maintenance record status? | Affects the attribute definition for maintenance status and any corresponding CHECK constraints. |
| Q-03 | Is a "usage policy" a free-text note or a controlled code? | Affects whether it is stored as a description field or a reference to a policy table. |
| Q-04 | Should the system store multiple concurrent maintenance records for the same space? | Affects whether a space being "under maintenance" is derived from active maintenance records or from an independent status field. |

---

## 9. Final Entity List

### Business Objects

- User
- Space

### Business Records

- Booking
- Maintenance Record

Total Entities Identified: 4
