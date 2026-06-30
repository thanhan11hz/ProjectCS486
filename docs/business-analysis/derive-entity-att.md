# Entity and Attribute Analysis

## 1. Analysis Summary

### Business Domain Overview

* The system manages shared campus spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, student workspaces) used for teaching, seminars, examinations, workshops, student projects, research activities, and academic events.
* Main business activities: submitting booking requests, approving/rejecting bookings, checking in and completing usage sessions, recording maintenance issues, and tracking facility utilization.
* Main business records: booking requests, approval decisions, usage sessions, maintenance records.
* Important information that must be stored includes user details, space details, facility lists per space, booking request parameters, approval decisions, actual usage data, and maintenance history.

---

## 2. Candidate Concepts

List the major concepts discovered from the requirements before classification.

| Concept | Requirement Evidence | Initial Category |
| ------- | ------------------- | ---------------- |
| User | Lines 13-14 | Business Object |
| Space | Lines 15-16 | Business Object |
| Facility | Lines 17-18 | Business Object |
| Booking Request | Lines 19-21 | Business Record |
| Approval | Lines 23-24 | Business Record |
| Check-in | Lines 25-26 | Workflow Step |
| Check-out/Completion | Lines 25-26 | Workflow Step |
| Session | Lines 25-26 | Business Record |
| Maintenance Record | Lines 27-28 | Business Record |
| Incident Report | Line 8 | Business Record |
| Space Type | Line 15 | Classification Value |
| Booking Status | Lines 21-22 | Status Value |
| Space Status | Line 16 | Status Value |
| User Role | Lines 13-14 | Classification Value |
| Booking Purpose | Line 19 | Classification Value |
| Problem Type | Line 27 | Classification Value |

---

## 3. Accepted Entities

List only concepts that satisfy the entity identification rules.

| Entity | Entity Type | Justification |
| ------ | ----------- | ------------- |
| User | Business Object | Users are independently managed by the organization through university accounts with lifecycle (account status). Users participate in multiple processes. |
| Space | Business Object | Spaces are managed physical resources with their own lifecycle (available, in use, under maintenance, closed, retired). |
| Facility | Business Object | Facilities represent equipment/amenities in spaces. They require independent storage to support flexible assignment and future equipment tracking. |
| Booking | Business Record | Booking requests are the core business transaction with a complete lifecycle (pending, approved, rejected, cancelled, checked in, completed, no-show). |
| Approval | Business Record | Approval decisions are made by different actors (staff/manager) than the requester, with distinct data (decision, decision maker, time, note, reason). |
| Session | Business Record | Actual usage sessions have their own data (actual times, conditions, notes) managed by facility staff. A booking may never result in a session (no-show). |
| Maintenance Record | Business Record | Maintenance records have their own lifecycle (reported, in progress, completed) and are independent of the booking process. |

Entity Type values:

* Business Object
* Business Record

---

## 4. Rejected Concepts

List concepts that were considered but should not become entities.

| Concept | Classification | Reason for Rejection | Violated Rule |
| ------- | -------------- | -------------------- | ------------- |
| Check-in | Workflow Step | Represents a lifecycle event within Session rather than an independent business object. Merged into Session. | Lifecycle Independence |
| Check-out/Complete | Workflow Step | Represents a lifecycle event within Session. Cannot exist without check-in. Merged into Session. | Dependency Rule |
| Incident Report | Implementation Gap | Mentioned once (line 8) without any defined attributes, actors, or process. Insufficient to model. May overlap with Maintenance. | Entity Separation |
| Space Type | Classification Value | Describes a property of Space, not an independent concept with its own lifecycle. | Attribute Candidate |
| Booking Status | Status Value | Represents the current state of a Booking lifecycle. Should be an attribute of Booking. | Timestamp-Only / Status |
| Space Status | Status Value | Represents the current state of a Space lifecycle. Should be an attribute of Space. | Timestamp-Only / Status |
| User Role | Classification Value | Describes a property of User. Acts as a classification for access control. | Attribute Candidate |
| Booking Purpose | Classification Value | Describes the reason for a Booking. Should be an attribute of Booking. | Attribute Candidate |
| Problem Type | Classification Value | Describes the type of maintenance issue. Should be an attribute or reference for Maintenance Record. | Attribute Candidate |

Possible classifications:

* Workflow Step
* Status Value
* Classification Value
* Relationship Candidate
* Attribute Candidate
* Implementation Artifact

---

## 5. Entity Attributes

### Entity: User

#### Description

A person who interacts with the system. Users have university accounts and can act in various roles (student, lecturer, TA, facility staff, department administrator, facility manager).

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| user_id | Unique identifier for each user (line 13). |
| full_name | Required for identification and communication (line 13). |
| email | Required for notifications and account correspondence (line 13). |
| phone_number | Required for contact purposes (line 13). |
| role | Determines permissions and system capabilities (line 13). |
| department | Identifies organizational affiliation (line 13). |
| account_status | Tracks whether the account is active, suspended, etc. (line 13). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| staff/manager | This is a role value, not attribute |

---

### Entity: Space

#### Description

A bookable physical location on campus managed by the School of Computer Science.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| space_code | Unique identifier for the space (line 15). |
| space_name | Human-readable name for the space (line 15). |
| space_type | Classification of the space (auditorium, classroom, etc.) (line 15). |
| building | Identifies which building the space is in (line 15). |
| floor | Floor number within the building (line 15). |
| room_number | Room identifier within the building (line 15). |
| capacity | Maximum number of occupants (line 15). |
| status | Current availability state (line 16). |
| usage_policy | Rules governing how the space may be used (line 15). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| facilities | Relationship candidate (many-to-many with Facility) |

---

### Entity: Facility

#### Description

Equipment or amenities available in a space. Examples include projector, whiteboard, microphone, computer, livestreaming equipment, air conditioner.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| facility_id | Unique identifier for each facility type. |
| facility_name | Descriptive name of the facility (projector, etc.) (line 17). |
| description | Optional details about the facility. |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| space | Relationship candidate (many-to-many with Space) |

---

### Entity: Booking

#### Description

A request submitted by a user to reserve a space for a specific time period and purpose.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| booking_id | Unique identifier for the booking request. |
| requested_start_time | When the requester wants the booking to begin (line 19). |
| requested_end_time | When the requester wants the booking to end (line 19). |
| purpose | Reason for the booking (lecture, exam, etc.) (line 19). |
| expected_participants | Number of people expected to attend (line 19). |
| status | Current lifecycle state (pending, approved, etc.) (line 21). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| requester | Relationship candidate (references User) |
| space | Relationship candidate (references Space) |
| approval | Separate entity: Approval |
| check-in/out | Separate entity: Session |

---

### Entity: Approval

#### Description

A decision made by facility staff or manager to approve or reject a booking request.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| approval_id | Unique identifier for the approval decision. |
| decision | Whether the booking was approved or rejected (line 23). |
| decision_time | When the decision was made (line 23). |
| decision_note | Notes accompanying the decision (line 23). |
| rejection_reason | Required if the booking was rejected (line 24). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| decision_maker | Relationship candidate (references User/Staff) |
| booking | Relationship candidate (references Booking) |

---

### Entity: Session

#### Description

The actual usage of a space corresponding to a booking. Captures what happened in reality versus what was requested.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| session_id | Unique identifier for the session. |
| actual_start_time | When the space was actually occupied (line 25). |
| actual_end_time | When the usage actually ended (line 26). |
| initial_condition | Condition of the space at check-in (line 25). |
| final_condition | Condition of the space at completion (line 26). |
| usage_notes | Any notes about the usage session (line 26). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| checked_in_by | Relationship candidate (references User/Staff) |
| booking | Relationship candidate (references Booking) |

---

### Entity: Maintenance Record

#### Description

A record of a maintenance issue reported for a space, tracking the problem through resolution.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| maintenance_id | Unique identifier for the maintenance record. |
| problem_description | Description of the issue (line 27). |
| start_time | When the maintenance was reported or started (line 27). |
| completion_time | When the maintenance was completed (line 27). |
| status | Current state (reported, in progress, completed) (line 27). |
| result_note | Outcome of the maintenance work (line 27). |

#### Excluded Information

| Information | Reason |
| ----------- | ------ |
| space | Relationship candidate (references Space) |
| reporter | Relationship candidate (references User) |
| assigned_staff | Relationship candidate (references User/Staff) |

---

## 6. Workflow Consolidation Decisions

Document situations where multiple workflow concepts were merged into a single entity.

| Workflow Concepts | Consolidated Entity | Justification |
| ----------------- | ------------------- | ------------- |
| Check-in, Completion | Session | Check-in and completion are two lifecycle events of the same actual usage process. They cannot exist independently of each other (Dependency Rule). |

No other workflow fragmentation was identified.

---

## 7. Assumptions

List assumptions required to perform the analysis.

| ID | Assumption | Justification |
| -- | ---------- | ------------- |
| A-01 | A booking request is always associated with a single space. | The requirements describe booking as selecting "a space" (singular), not multiple spaces. |
| A-02 | A booking can have at most one approval decision. | The requirements describe a single approval/rejection flow. No multi-level approval is mentioned. |
| A-03 | A session is always linked to exactly one approved booking. | The requirements present check-in and completion as operations on a booking, not as walk-in usage. |
| A-04 | Facility is modeled as an entity rather than a multi-valued attribute to support future equipment tracking. | The requirements only require storing a list, but the Extensibility Rule favors an entity design. |

---

## 8. Unresolved Questions

List ambiguities that may affect entity identification.

| ID | Question | Potential Impact |
| -- | -------- | ---------------- |
| Q-01 | What does "incident reporting" (line 8) entail? Is it separate from maintenance records? | May require an additional Incident entity if scoped independently of maintenance. |
| Q-02 | Can a user have multiple roles? | Affects whether role is a single-valued or multi-valued attribute of User. |
| Q-03 | Can a booking be modified after submission (e.g., time change) before approval? | Affects Booking lifecycle states and whether modification history must be tracked. |
| Q-04 | What is the exact set of valid booking statuses and their allowed transitions? | Affects data validation rules for Booking.status. |

---

## 9. Final Entity List

### Business Objects

* User
* Space
* Facility

### Business Records

* Booking
* Approval
* Session
* Maintenance Record

Total Entities Identified: 7
