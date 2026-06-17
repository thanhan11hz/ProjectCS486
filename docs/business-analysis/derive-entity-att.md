# Entity and Attribute Analysis

## 1. Analysis Summary

### Business Domain Overview

The system manages shared physical spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, student workspaces) for the School of Computer Science.

Main business activities:

- Space booking request submission
- Booking approval and rejection
- Check-in and check-out of booked sessions
- Maintenance management for spaces
- Usage monitoring and history viewing

Main business records:

- Booking requests (with lifecycle: pending → approved/rejected → checked in → completed/no-show/cancelled)
- Maintenance records (with lifecycle: reported → assigned → in progress → completed)

Important information that must be stored:

- User identity, contact, role, and account status
- Space catalog with identifiers, location, capacity, status, and policy
- Facility inventory per space
- Booking request details, status, and decision audit trail
- Check-in and check-out session data
- Maintenance problem reports, assignment, and resolution

---

## 2. Candidate Concepts

| Concept | Requirement Evidence | Initial Category |
| ------- | -------------------- | ---------------- |
| User | "Each user must have a university account. The system stores basic user information, including user ID, full name, email, phone number, role, department, and account status." | Business Object |
| Space | "The School manages many bookable spaces. For each space, the system stores a unique space code, space name, space type, building, floor, room number, capacity, current status, and usage policy." | Business Object |
| Facility | "Each space may have several facilities, such as a projector, whiteboard, microphone, computer, livestreaming equipment, or air conditioner. The system should store the list of facilities available in each space." | Relationship Candidate |
| Booking | "Users can submit booking requests by selecting a space, requested start time, requested end time, purpose of use, and expected number of participants." | Business Record |
| Maintenance Record | "A space may have maintenance records for problems such as broken projectors, air-conditioning failure, damaged furniture, cleaning issues, or network problems." | Business Record |
| Check In | "When the requester arrives, facility staff can check in the booking. The system records the actual start time, the person who checked in the booking, and the initial condition of the space." | Workflow Step |
| Check Out / Completion | "When the session ends, facility staff can complete the booking by recording the actual end time, the final condition of the space, and any usage notes." | Workflow Step |
| Booking Approval | "A booking request may require approval from a facility staff member or manager. When a booking is approved or rejected, the system records the staff member who made the decision, the decision time, and a decision note." | Workflow Step |
| Space Type | "space type" (classroom, computer laboratory, meeting room, auditorium implied) | Classification Value |
| Space Status | "current status" (available, in use, under maintenance, temporarily closed, or retired) | Classification Value |
| Booking Status | "status, such as pending, approved, rejected, cancelled, checked in, completed, or no-show" | Classification Value |
| Maintenance Status | "status" | Classification Value |
| Role | "role" (student, lecturer, teaching assistant, facility staff, department administrator, facility manager) | Classification Value |
| Account Status | "account status" | Classification Value |
| Booking Purpose | "purpose of use" (lecture, examination, seminar, workshop, meeting, student activity, or administrative event) | Classification Value |
| Building | "building" | Attribute Candidate |
| Floor | "floor" | Attribute Candidate |
| Room Number | "room number" | Attribute Candidate |
| Capacity | "capacity" | Attribute Candidate |
| Usage Policy | "usage policy" | Attribute Candidate |

---

## 3. Accepted Entities

| Entity | Entity Type | Justification |
| ------ | ----------- | ------------- |
| User | Business Object | Users are independently managed by the university, have their own identity (university account), and participate in multiple business processes (booking, approval, check-in, maintenance). |
| Space | Business Object | Spaces are independently managed physical resources that can be booked, maintained, and referenced by multiple activities across the organization. |
| Booking | Business Record | Booking requests have a defined lifecycle (pending → approved/rejected → checked in → completed/no-show/cancelled), a status that transitions over time, and maintain historical audit information for reporting. |
| Maintenance Record | Business Record | Maintenance records track problems from reporting through resolution, have a lifecycle (reported → assigned → in progress → completed), a status, and must retain historical data for facility management. |

---

## 4. Rejected Concepts

| Concept | Classification | Reason for Rejection | Violated Rule |
| ------- | -------------- | -------------------- | ------------- |
| Facility | Relationship Candidate | Represents equipment that describes a space rather than an independently managed object; requirements do not indicate independent lifecycle, tracking, or management of facilities. | Rule 4, Rule 6 |
| Check In | Workflow Step | A lifecycle event of Booking that records the actual start of a session; does not exist independently of a booking. | Rule 7 |
| Check Out / Completion | Workflow Step | A lifecycle event of Booking that records the end of a session; does not exist independently of a booking. | Rule 7 |
| Booking Approval | Workflow Step | Decision-making action within the Booking lifecycle; no evidence of independent approval management or multi-step approval workflow. | Rule 7 |
| Space Type | Classification Value | Classification of spaces into categories (classroom, laboratory, etc.); not an independently managed object. | Rule 5 |
| Space Status | Classification Value | Status value indicating current operational state of a space; stored as attribute value. | Rule 5 |
| Booking Status | Classification Value | Status value indicating where a booking is in its lifecycle; stored as attribute value. | Rule 5 |
| Maintenance Status | Classification Value | Status value indicating the stage of a maintenance task; stored as attribute value. | Rule 5 |
| Role | Classification Value | User role classification (student, lecturer, etc.); stored as attribute value. | Rule 5 |
| Account Status | Classification Value | Status value for user account state; stored as attribute value. | Rule 5 |
| Booking Purpose | Classification Value | Purpose classification for a booking; stored as attribute value. | Rule 5 |
| Building | Attribute Candidate | Describes a property of Space (location information). | Rule 4 |
| Floor | Attribute Candidate | Describes a property of Space (location information). | Rule 4 |
| Room Number | Attribute Candidate | Describes a property of Space (location information). | Rule 4 |
| Capacity | Attribute Candidate | Describes a property of Space (maximum occupancy). | Rule 4 |
| Usage Policy | Attribute Candidate | Describes rules governing how a Space may be used. | Rule 4 |

---

## 5. Entity Attributes

### Entity: User

#### Description

A person who has a university account and interacts with the space management system. Users may be students, lecturers, teaching assistants, facility staff, department administrators, or facility managers.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| user_id | Unique identifier from the university account system. |
| full_name | Personal name of the user. |
| email | Contact email address. |
| phone_number | Contact phone number. |
| role | User classification (student, lecturer, teaching assistant, facility staff, department administrator, facility manager). Classification value stored as attribute. |
| department | Department or organizational unit the user belongs to. |
| account_status | Indicates whether the account is active, suspended, etc. Classification value stored as attribute. |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| *None identified* | All discovered information about User is descriptive. |

---

### Entity: Space

#### Description

A physical room or area on campus that can be booked for teaching, seminars, examinations, workshops, student projects, research activities, and academic events.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| space_code | Unique identifier assigned to the space (e.g., room code). |
| space_name | Display name or label for the space. |
| space_type | Category of space (classroom, computer laboratory, meeting room, auditorium, etc.). Classification value stored as attribute. |
| building | Building where the space is located. |
| floor | Floor level within the building. |
| room_number | Room number or identifier within the building. |
| capacity | Maximum number of people the space can accommodate. |
| current_status | Operational state (available, in use, under maintenance, temporarily closed, retired). Classification value stored as attribute. |
| usage_policy | Rules or guidelines governing how the space may be used. |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| facilities | Relationship candidate — represents equipment associated with the space, not a descriptive attribute. |

---

### Entity: Booking

#### Description

A request submitted by a user to reserve a specific space for a defined time period and purpose, with an associated lifecycle and decision audit trail.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| booking_id | Unique identifier for the booking request. |
| requested_start_time | Date and time when the requester wants the booking to begin. |
| requested_end_time | Date and time when the requester wants the booking to end. |
| purpose_of_use | Reason for the booking (lecture, examination, seminar, workshop, meeting, student activity, administrative event). Classification value stored as attribute. |
| expected_number_of_participants | Number of people expected to attend. |
| status | Current state in the booking lifecycle (pending, approved, rejected, cancelled, checked in, completed, no-show). Classification value stored as attribute. |
| decision_time | Date and time when the approval or rejection decision was made. |
| decision_note | Optional note recorded by the decision-maker. |
| rejection_reason | Reason provided when the booking is rejected. |
| actual_start_time | Actual start time recorded at check-in. |
| initial_condition | Condition of the space recorded at check-in. |
| actual_end_time | Actual end time recorded at check-out. |
| final_condition | Condition of the space recorded at check-out. |
| usage_notes | Notes recorded at check-out about the session. |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| requester | Relationship candidate — references the User who submitted the booking. |
| space | Relationship candidate — references the Space being booked. |
| staff_member_who_made_decision | Relationship candidate — references the User who approved or rejected. |
| person_who_checked_in | Relationship candidate — references the User who performed check-in. |

---

### Entity: Maintenance Record

#### Description

A record of a problem reported for a space, tracking the issue from reporting through assignment and resolution.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| maintenance_id | Unique identifier for the maintenance record. |
| problem_description | Description of the issue (broken projector, air-conditioning failure, damaged furniture, cleaning issue, network problem, etc.). |
| start_time | Date and time when the problem was reported. |
| completion_time | Date and time when the maintenance was completed. |
| status | Current state of the maintenance task (reported, assigned, in progress, completed). Classification value stored as attribute. |
| result_note | Note describing the resolution outcome. |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| related_space | Relationship candidate — references the Space being maintained. |
| reporter | Relationship candidate — references the User who reported the problem. |
| assigned_staff_member | Relationship candidate — references the User assigned to resolve the issue. |

---

## 6. Workflow Consolidation Decisions

| Workflow Concepts | Consolidated Entity | Justification |
| ----------------- | ------------------- | ------------- |
| Check In, Check Out / Completion, Booking Approval | Booking | Check-in, check-out, and approval are lifecycle events or actions performed on a Booking. They do not exist independently and are not managed as separate business records. Their data is captured as attributes within the Booking entity. |

---

## 7. Assumptions

| ID | Assumption | Justification |
| -- | ---------- | ------------- |
| A-01 | Each user has a unique university account identifier that can serve as a natural key. | The requirements state "Each user must have a university account" with a "user ID" but do not specify its format. |
| A-02 | Facilities are descriptive lists associated with spaces and are not independently managed. | The requirements only mention storing a list of facilities per space; no independent lifecycle, maintenance, or tracking of individual facility items is described. |
| A-03 | Booking approval is a single-step decision (approve or reject) with no multi-level or chain approval workflow. | The requirements describe approval as "a booking request may require approval from a facility staff member or manager" without mentioning multiple approvers or sequential approvals. |
| A-04 | The same user who checks in a booking is responsible for checking out (completing) the booking. | The requirements describe both check-in and check-out being performed by "facility staff" but do not specify whether the same person must perform both. The attributes for checked-in-by and actual start time are recorded separately from check-out attributes. |

---

## 8. Unresolved Questions

| ID | Question | Potential Impact |
| -- | -------- | ---------------- |
| Q-01 | Can a booking have multiple approval attempts (e.g., rejected then re-submitted and approved)? | May affect whether rejection_reason and decision fields need to support multiple decision records per booking. |
| Q-02 | Is the facility list for a space a fixed enumeration of types or can facility items be individually identified and tracked? | Affects whether Facility becomes its own entity in later design stages. |
| Q-03 | Can a space have multiple concurrent maintenance records? | Affects whether the relationship between Space and Maintenance Record is one-to-many and whether overlapping maintenance periods are permitted. |
| Q-04 | What is the exact behavior when a booking status transitions from "checked in" to "completed" versus "no-show"? | Affects whether additional rules are needed to determine no-show status (e.g., no check-in within a grace period). |

---

## 9. Final Entity List

### Business Objects

- User
- Space

### Business Records

- Booking
- Maintenance Record

Total Entities Identified: 4
