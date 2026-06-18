# Business Rules Analysis

## 1. Explicit Business Rules

Business rules stated directly in the requirements.

| ID | Rule |
| -- | ---- |
| BR-E001 | Each user must have a university account. |
| BR-E002 | A user may be a student, lecturer, teaching assistant, facility staff, department administrator, or facility manager. |
| BR-E003 | A space may be available, in use, under maintenance, temporarily closed, or retired. |
| BR-E004 | A booking may be for a lecture, examination, seminar, workshop, meeting, student activity, or administrative event. |
| BR-E005 | Each booking request has a status: pending, approved, rejected, cancelled, checked in, completed, or no-show. |
| BR-E006 | The same space cannot have two approved bookings with overlapping time periods. |
| BR-E007 | A space that is under maintenance, closed, or retired cannot be booked. |
| BR-E008 | A booking request may require approval from a facility staff member or manager. |
| BR-E009 | When a booking is approved or rejected, the system records the decision maker, decision time, and decision note. |
| BR-E010 | If a booking is rejected, the rejection reason must be stored. |
| BR-E011 | When the requester arrives, facility staff can check in the booking. |
| BR-E012 | When the session ends, facility staff can complete the booking. |
| BR-E013 | A space under maintenance cannot be booked. |
| BR-E014 | The system must keep historical records of bookings and maintenance activities. |

---

# 2. Entity-Based Rule Analysis

## Entity: User

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| user_id | Identifier | Unique identifier for each user |
| full_name | Text | User's full name |
| email | Text | University email address |
| phone_number | Text | Contact phone number |
| role | Enumeration | student, lecturer, teaching_assistant, facility_staff, department_administrator, facility_manager |
| department | Text | Organizational affiliation |
| account_status | Enumeration | Tracks whether account is active, suspended, etc. |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
| submits | Booking |
| makes | Approval |
| conducts | Session |
| reports | Maintenance Record |
| assigned_to | Maintenance Record |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
| None | | |

---

### 2.4 Related Entity Attributes

Attributes belonging to connected entities that may influence this entity.

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
| Booking | status | Current lifecycle state of the booking |
| Booking | requested_start_time | When the booking is requested to begin |
| Booking | requested_end_time | When the booking is requested to end |
| Approval | decision | Whether booking was approved or rejected |
| Session | actual_start_time | When the session actually started |
| Session | actual_end_time | When the session actually ended |
| Maintenance Record | status | Current state of the maintenance |

---

### 2.5 Cross-Entity Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| User.role + Approval decision making | Only certain roles can make approval decisions | Only facility staff and facility managers may approve or reject booking requests |
| User.account_status + Booking submission | Account status affects ability to book | Only users with active account status may submit booking requests |

---

### 2.6 Temporal Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| None specifically apply to User | User entity has no date/time attributes | |

---

### 2.7 Status-Based Constraint Analysis

#### Status Attribute: account_status

| Status Value | Required Data | Restricted Data | Candidate Rule |
| ------------ | ------------- | --------------- | -------------- |
| active | None | None | Users with active status may submit bookings and interact normally |
| suspended | None | Cannot submit bookings | Users with suspended account status cannot submit booking requests |

---

### 2.8 Enumeration Constraint Analysis

#### Enumeration Attribute: role

| Value | Impacted Elements | Candidate Rule |
| ----- | ----------------- | -------------- |
| facility_staff | Approval, Session, Maintenance Record.assigned_to | Facility staff may approve bookings, conduct sessions, and be assigned to maintenance |
| facility_manager | Approval | Facility managers may approve bookings |
| student, lecturer, teaching_assistant | Booking | Students, lecturers, and TAs may submit booking requests |
| department_administrator | Booking | Department administrators may submit booking requests |

---

### 2.9 Real-World Consistency Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| None specifically | User has no attributes requiring cross-field consistency | |

---

### 2.10 Relationship Constraint Analysis

#### Relationship: submits

##### Participating Entities

* User (Requester)
* Booking (Booking Request)

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each booking must have exactly one requester (mandatory participation) | A booking must be submitted by exactly one user |
| A user may exist without submitting any bookings | A user may exist in the system without having submitted any booking requests |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Booking depends on User existence | A booking cannot exist without a submitting user |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| A user can submit many bookings | A user may submit multiple booking requests |

---

#### Relationship: makes

##### Participating Entities

* User (Decision Maker)
* Approval (Approval Decision)

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each approval must have exactly one decision maker | An approval decision must be made by exactly one staff member |
| Not all users are decision makers | Only facility staff and facility managers may make approval decisions |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Approval depends on User existence | An approval cannot exist without a decision maker |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| One staff member can make many approval decisions | A staff member may approve or reject multiple booking requests |

---

#### Relationship: conducts

##### Participating Entities

* User (Staff Conductor)
* Session (Usage Session)

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each session must have exactly one conductor | A usage session must be conducted by exactly one facility staff member |
| Not all users are conductors | Only facility staff may conduct check-in and check-out operations |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Session depends on User existence | A usage session cannot exist without a conducting staff member |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| One staff member can conduct many sessions | A facility staff member may conduct multiple usage sessions |

---

#### Relationship: reports

##### Participating Entities

* User (Reporter)
* Maintenance Record

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each maintenance record must have exactly one reporter | A maintenance record must be reported by exactly one user |
| Not all users report maintenance | Any user may report a maintenance issue |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Maintenance Record depends on User existence | A maintenance record cannot exist without a reporting user |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| One user can report many maintenance issues | A user may report multiple maintenance issues |

---

#### Relationship: assigned_to

##### Participating Entities

* User (Assigned Staff)
* Maintenance Record

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each maintenance record must have exactly one assigned staff member | A maintenance record must be assigned to exactly one facility staff member |
| Not all users are assigned staff | Only facility staff may be assigned to handle maintenance records |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Maintenance Record depends on assigned User | A maintenance record cannot exist without an assigned staff member |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| reporter and assigned staff may be different users | The user who reports a maintenance issue may be different from the staff member assigned to resolve it |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| One staff member can be assigned to many maintenance records | A facility staff member may be assigned to multiple maintenance records |

---

### 2.11 Entity Rule Candidates

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| C001 | Only users with active account status may submit booking requests | Status (User.account_status) |
| C002 | Only facility staff and facility managers may approve or reject booking requests | Enumeration (User.role) |
| C003 | Only facility staff may conduct check-in and check-out sessions | Enumeration (User.role) |
| C004 | Only facility staff may be assigned to handle maintenance records | Enumeration (User.role) |
| C005 | A booking must be submitted by exactly one user | Relationship (submits) |
| C006 | An approval decision must be made by exactly one staff member | Relationship (makes) |
| C007 | A usage session must be conducted by exactly one facility staff member | Relationship (conducts) |
| C008 | A maintenance record must be reported by exactly one user | Relationship (reports) |
| C009 | A maintenance record must be assigned to exactly one facility staff member | Relationship (assigned_to) |
| C010 | The reporter and assigned staff of a maintenance record may be different users | Relationship (assigned_to) |

---

## Entity: Space

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| space_code | Identifier | Unique identifier for the space |
| space_name | Text | Human-readable name |
| space_type | Enumeration | auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace |
| building | Text | Building name or code |
| floor | Text | Floor number |
| room_number | Text | Room identifier within building |
| capacity | Numeric | Maximum number of occupants |
| status | Enumeration | available, in_use, under_maintenance, temporarily_closed, retired |
| usage_policy | Text | Rules governing how the space may be used |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
| reserves | Booking |
| pertains_to | Maintenance Record |
| equipped_with | Facility |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
| equipped_with | quantity | Number of units of a facility in a space |

---

### 2.4 Related Entity Attributes

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
| Booking | requested_start_time | When the booking is requested to begin |
| Booking | requested_end_time | When the booking is requested to end |
| Booking | status | Current lifecycle state of the booking |
| Booking | expected_participants | Number of expected attendees |
| Maintenance Record | status | Current state of maintenance for the space |
| Facility | facility_name | Name of the facility available in the space |

---

### 2.5 Cross-Entity Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Space.status + Booking creation | Space must be bookable | A space with status under_maintenance, temporarily_closed, or retired cannot be booked |
| Space.capacity + Booking.expected_participants | Capacity restriction | Expected participants must not exceed space capacity |
| Space.status + Maintenance Record.status | Space under maintenance cannot be booked | A space whose current or active maintenance record exists cannot accept new bookings |
| Space.status + Booking.status (approved) | Overlapping bookings | Two approved bookings for the same space must not have overlapping time periods |

---

### 2.6 Temporal Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| None for Space directly | Space has no date/time attributes | |

---

### 2.7 Status-Based Constraint Analysis

#### Status Attribute: status

| Status Value | Required Data | Restricted Data | Candidate Rule |
| ------------ | ------------- | --------------- | -------------- |
| available | None | None | Space is available for booking |
| in_use | None | None | Space is currently occupied; may still be bookable for future time slots |
| under_maintenance | Maintenance Record | Cannot accept new bookings | A space under maintenance cannot be booked for any time period |
| temporarily_closed | None | Cannot accept new bookings | A temporarily closed space cannot be booked for any time period |
| retired | None | Cannot accept new bookings | A retired space cannot be booked for any time period |

---

### 2.8 Enumeration Constraint Analysis

#### Enumeration Attribute: space_type

| Value | Impacted Elements | Candidate Rule |
| ----- | ----------------- | -------------- |
| auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace | Usage policy, capacity expectations | Each space type may have different usage policies or capacity ranges |

---

### 2.9 Real-World Consistency Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| None specifically | | |

---

### 2.10 Relationship Constraint Analysis

#### Relationship: reserves

##### Participating Entities

* Booking (Booking Request)
* Space (Reserved Space)

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each booking must reserve exactly one space | A booking must reserve exactly one space |
| A space may exist without any current bookings | A space may exist in the system without any booking requests |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Booking depends on Space existence | A booking cannot exist without a reserved space |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| A space cannot be double-booked | The same space cannot have two approved bookings with overlapping time periods |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Many bookings can reserve the same space at different times | Multiple bookings for the same space must have non-overlapping time ranges |

---

#### Relationship: pertains_to

##### Participating Entities

* Maintenance Record
* Space (Affected Space)

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each maintenance record must pertain to exactly one space | A maintenance record must be associated with exactly one space |
| A space may have zero or many maintenance records | A space may have multiple maintenance records over time |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Maintenance Record depends on Space existence | A maintenance record cannot exist without a related space |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| A space may have multiple maintenance records | A space may have many maintenance records across different time periods, but should not have overlapping active (open) maintenance records |

---

#### Relationship: equipped_with

##### Participating Entities

* Space
* Facility

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| quantity | Number of units of a facility in a space |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| A space may have zero or many facilities | A space may be equipped with any number of facilities, including none |
| A facility may be available in zero or many spaces | A facility type may be equipped in multiple spaces or in none |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| The equipped_with relationship depends on the existence of both Space and Facility | A facility assignment can only exist when both the space and facility exist |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

---

### 2.11 Entity Rule Candidates

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| C011 | A space with status under_maintenance, temporarily_closed, or retired cannot be booked | Status (Space.status) + Cross-Entity |
| C012 | Expected participants must not exceed space capacity | Cross-Entity (Space.capacity + Booking.expected_participants) |
| C013 | A booking must reserve exactly one space | Relationship (reserves) |
| C014 | Two approved bookings for the same space must not have overlapping time periods | Relationship (reserves) |
| C015 | A maintenance record must be associated with exactly one space | Relationship (pertains_to) |
| C016 | A space may have multiple maintenance records over time | Relationship (pertains_to) |

---

## Entity: Facility

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| facility_id | Identifier | Unique identifier for each facility type |
| facility_name | Text | Descriptive name (projector, whiteboard, etc.) |
| description | Text | Optional details about the facility |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
| equipped_with | Space |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
| equipped_with | quantity | Number of units of a facility in a space |

---

### 2.4 Related Entity Attributes

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
| Space | space_name | Name of the space containing the facility |
| Space | space_type | Type of the space containing the facility |

---

### 2.5 Cross-Entity Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| None | | |

---

### 2.6 Temporal Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| None | Facility has no date/time attributes | |

---

### 2.7 Status-Based Constraint Analysis

| Status Attribute | Observation | Candidate Rule |
| ---------------- | ----------- | -------------- |
| None | Facility has no status attribute | |

---

### 2.8 Enumeration Constraint Analysis

| Enumeration Attribute | Observation | Candidate Rule |
| --------------------- | ----------- | -------------- |
| None | Facility has no enumeration attribute | |

---

### 2.9 Real-World Consistency Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| None | | |

---

### 2.10 Relationship Constraint Analysis

(Relationship: equipped_with — already covered in Space section above)

---

### 2.11 Entity Rule Candidates

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| None | | |

---

## Entity: Booking

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| booking_id | Identifier | Unique identifier for the booking |
| requested_start_time | DateTime | When the requester wants the booking to begin |
| requested_end_time | DateTime | When the requester wants the booking to end |
| purpose | Enumeration | lecture, examination, seminar, workshop, meeting, student_activity, administrative_event |
| expected_participants | Numeric | Number of people expected to attend |
| status | Enumeration | pending, approved, rejected, cancelled, checked_in, completed, no_show |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
| submits | User |
| reserves | Space |
| reviews | Approval |
| tracks | Session |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
| None | | |

---

### 2.4 Related Entity Attributes

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
| User | full_name | Name of the requester |
| User | role | Role of the requester |
| Space | capacity | Maximum occupancy of the reserved space |
| Space | status | Current availability status of the space |
| Approval | decision | Whether the booking was approved or rejected |
| Approval | decision_time | When the decision was made |
| Approval | rejection_reason | Reason for rejection (if rejected) |
| Session | actual_start_time | When usage actually started |
| Session | actual_end_time | When usage actually ended |
| Session | initial_condition | Condition at check-in |
| Session | final_condition | Condition at completion |

---

### 2.5 Cross-Entity Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Booking.expected_participants + Space.capacity | Capacity limit | Expected participants must not exceed space capacity |
| Booking.requested_start_time + Booking.requested_end_time + Space (via reserves) + existing approved bookings | Overlap prevention | An approved booking for a space must not overlap in time with another approved booking for the same space |
| Booking.status = pending + Approval decision | Approval flow | A booking with status pending is eligible for review by facility staff |
| Booking.status + Session | Session can only occur for approved bookings | A session can only be created for a booking with status approved |
| Booking.status + Approval.decision | Approval outcome determines next status | If approval decision is approved, booking status transitions to approved; if rejected, booking status transitions to rejected |

---

### 2.6 Temporal Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Booking.requested_start_time + Booking.requested_end_time | Time range ordering | Requested start time must occur before requested end time |
| Booking.requested_start_time + current time | Future booking constraint | Booking requests must have a requested start time in the future (cannot book for past times) |

---

### 2.7 Status-Based Constraint Analysis

#### Status Attribute: status

| Status Value | Required Data | Restricted Data | Candidate Rule |
| ------------ | ------------- | --------------- | -------------- |
| pending | requested_start_time, requested_end_time, purpose, expected_participants, space, requester | Cannot have Session or Approval data | A pending booking awaiting review cannot have session or approval data |
| approved | Approval record with decision = approved | Cannot be modified or cancelled by requester without appropriate action | An approved booking requires an associated approval record and can proceed to check-in |
| rejected | Approval record with decision = rejected + rejection_reason | Cannot proceed to Session | A rejected booking must have a rejection reason; cannot be checked in |
| cancelled | None | Cannot proceed to session | A cancelled booking terminates the lifecycle and cannot proceed further |
| checked_in | Session record with actual_start_time and initial_condition | Cannot be modified; new bookings for same time should be prevented | A checked-in booking requires a session with actual start time and initial condition |
| completed | Session record with actual_end_time, final_condition | Closed state | A completed booking requires session completion data (actual end time, final condition, usage notes) |
| no_show | None | No session data | A no-show booking never resulted in a session |

---

### 2.8 Enumeration Constraint Analysis

#### Enumeration Attribute: purpose

| Value | Impacted Elements | Candidate Rule |
| ----- | ----------------- | -------------- |
| lecture, examination, seminar, workshop, meeting, student_activity, administrative_event | Space selection, capacity requirements | Booking purpose may influence which space types are appropriate or special setup requirements |

---

### 2.9 Real-World Consistency Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| requested_start_time + requested_end_time | Temporal consistency | Requested start time must be before requested end time |

---

### 2.10 Relationship Constraint Analysis

(Relationships: submits — covered under User; reserves — covered under Space; reviews — covered below)

#### Relationship: reviews

##### Participating Entities

* Approval (Approval Decision)
* Booking (Reviewed Booking)

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each approval reviews exactly one booking | An approval decision must review exactly one booking |
| A booking may have at most one approval decision | A booking may receive at most one approval decision |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Approval depends on Booking existence | An approval cannot exist without a corresponding booking |
| Only pending bookings can be reviewed | Only bookings with status pending may be reviewed for approval or rejection |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| One booking, one approval | A booking cannot have both an approved and rejected decision; at most one approval record per booking |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| None | |

---

#### Relationship: tracks

##### Participating Entities

* Session (Actual Usage)
* Booking (Approved Booking)

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
| None | |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Each session tracks exactly one booking | A session must correspond to exactly one booking |
| A booking may have at most one session | A booking may have at most one corresponding session (some bookings never result in a session) |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| Session depends on an approved Booking | A session can only exist for a booking with status approved |
| Session cannot exist without a booking | A session must track an existing booking |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| One booking maps to at most one session | A booking cannot have multiple sessions |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
| If a booking reaches status approved and is checked in, exactly one session is created | An approved booking results in zero or one session depending on check-in |

---

### 2.11 Entity Rule Candidates

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| C017 | Requested start time must occur before requested end time | Temporal (Booking) |
| C018 | Booking requests must have a requested start time in the future | Temporal (Booking) |
| C019 | An approved booking requires an associated approval record with decision = approved | Status (Booking.status) |
| C020 | A rejected booking must have a rejection reason | Status (Booking.status) + Explicit (BR-E010) |
| C021 | A checked-in booking requires a session with actual start time and initial condition | Status (Booking.status) |
| C022 | A completed booking requires session completion data (actual end time, final condition, usage notes) | Status (Booking.status) |
| C023 | A session can only be created for a booking with status approved | Cross-Entity (Booking.status + Session) |
| C024 | Each session must correspond to exactly one booking | Relationship (tracks) |
| C025 | A booking may have at most one approval decision | Relationship (reviews) |
| C026 | A booking may have at most one corresponding session | Relationship (tracks) |
| C027 | Only bookings with status pending may be reviewed for approval or rejection | Relationship (reviews) |

---

## Entity: Approval

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| approval_id | Identifier | Unique identifier for the approval decision |
| decision | Enumeration | approved, rejected |
| decision_time | DateTime | When the decision was made |
| decision_note | Text | Notes accompanying the decision |
| rejection_reason | Text | Required if the booking was rejected |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
| makes | User |
| reviews | Booking |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
| None | | |

---

### 2.4 Related Entity Attributes

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
| User | full_name | Name of the decision maker |
| User | role | Role (must be facility_staff or facility_manager) |
| Booking | status | Current lifecycle state of the reviewed booking |
| Booking | requested_start_time | When the booking is requested to begin |
| Booking | requested_end_time | When the booking is requested to end |

---

### 2.5 Cross-Entity Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Approval.decision + Booking.status | Decision determines booking status | An approval decision of approved transitions the booking to approved; a decision of rejected transitions the booking to rejected |
| Approval.rejection_reason + Approval.decision | Rejection reason is conditional | Rejection reason must be provided when decision is rejected |

---

### 2.6 Temporal Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Approval.decision_time + Booking.requested_start_time | Decision must precede usage | Approval decision time must occur before the booking requested start time |

---

### 2.7 Status-Based Constraint Analysis

#### Status Attribute: decision

| Status Value | Required Data | Restricted Data | Candidate Rule |
| ------------ | ------------- | --------------- | -------------- |
| approved | decision_time, decision_note, decision_maker | rejection_reason must be null | An approved decision requires decision time and decision maker; rejection reason is not applicable |
| rejected | decision_time, rejection_reason, decision_maker | None | A rejected decision requires rejection reason, decision time, and decision maker |

---

### 2.8 Enumeration Constraint Analysis

#### Enumeration Attribute: decision

| Value | Impacted Elements | Candidate Rule |
| ----- | ----------------- | -------------- |
| approved | Booking.status transitions to approved; Session may be created later | An approved decision allows the booking to proceed to check-in |
| rejected | Booking.status transitions to rejected; rejection_reason required | A rejected decision prevents the booking from proceeding further |

---

### 2.9 Real-World Consistency Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Approval.decision + Approval.rejection_reason | Conditional requirement | Rejection reason must be provided if and only if the decision is rejected |

---

### 2.10 Relationship Constraint Analysis

(Relationships: makes — covered under User; reviews — covered under Booking)

---

### 2.11 Entity Rule Candidates

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| C028 | An approval decision of approved transitions the booking to approved; a decision of rejected transitions the booking to rejected | Cross-Entity (Approval.decision + Booking.status) |
| C029 | Rejection reason must be provided when decision is rejected | Status (Approval.decision) + Explicit (BR-E010) |
| C030 | Approval decision time must occur before the booking requested start time | Temporal (Approval.decision_time + Booking.requested_start_time) |

---

## Entity: Session

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| session_id | Identifier | Unique identifier for the session |
| actual_start_time | DateTime | When the space was actually occupied |
| actual_end_time | DateTime | When the usage actually ended |
| initial_condition | Text | Condition of the space at check-in |
| final_condition | Text | Condition of the space at completion |
| usage_notes | Text | Any notes about the usage session |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
| conducts | User |
| tracks | Booking |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
| None | | |

---

### 2.4 Related Entity Attributes

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
| User | full_name | Name of the conductor |
| Booking | requested_start_time | When the booking was requested to start |
| Booking | requested_end_time | When the booking was requested to end |
| Booking | status | Must be approved before check-in |

---

### 2.5 Cross-Entity Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Session.actual_start_time + Booking.requested_start_time | Early check-in constraint | Session actual start time should not precede the booking requested start time |
| Session.actual_end_time + Booking.requested_end_time | Late check-out may be permitted | Session actual end time may differ from requested end time |

---

### 2.6 Temporal Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Session.actual_start_time + Session.actual_end_time | Time range ordering | Actual start time must occur before actual end time |
| Session.actual_start_time + Booking.requested_start_time | Temporal ordering | Check-in must occur on or after the booking requested start time |

---

### 2.7 Status-Based Constraint Analysis

| Status Attribute | Observation | Candidate Rule |
| ---------------- | ----------- | -------------- |
| None | Session has no status attribute (status is on Booking) | |

---

### 2.8 Enumeration Constraint Analysis

| Enumeration Attribute | Observation | Candidate Rule |
| --------------------- | ----------- | -------------- |
| None | Session has no enumeration attribute | |

---

### 2.9 Real-World Consistency Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Session.actual_start_time + Session.actual_end_time | Temporal consistency | Actual start time must be before actual end time |
| Session.initial_condition + Session.final_condition | Condition comparison | Final condition may differ from initial condition; if damage is noted, a maintenance record may be required |

---

### 2.10 Relationship Constraint Analysis

(Relationships: conducts — covered under User; tracks — covered under Booking)

---

### 2.11 Entity Rule Candidates

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| C031 | Actual start time must occur before actual end time | Temporal (Session) |
| C032 | Check-in must occur on or after the booking requested start time | Temporal (Session.actual_start_time + Booking.requested_start_time) |

---

## Entity: Maintenance Record

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| maintenance_id | Identifier | Unique identifier for the maintenance record |
| problem_description | Text | Description of the issue |
| start_time | DateTime | When the maintenance was reported or started |
| completion_time | DateTime | When the maintenance was completed |
| status | Enumeration | reported, in_progress, completed |
| result_note | Text | Outcome of the maintenance work |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
| reports | User |
| pertains_to | Space |
| assigned_to | User |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
| None | | |

---

### 2.4 Related Entity Attributes

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
| User (reporter) | full_name | Name of the person who reported the issue |
| User (assigned staff) | full_name | Name of the staff member assigned to fix it |
| Space | space_code, space_name | Identity of the affected space |
| Space | status | Space may be set to under_maintenance while maintenance is active |

---

### 2.5 Cross-Entity Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Maintenance Record.status + Space.status | Maintenance affects space availability | When a maintenance record is in reported or in_progress status, the related space should be marked as under_maintenance, preventing new bookings |

---

### 2.6 Temporal Constraint Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Maintenance Record.start_time + Maintenance Record.completion_time | Completion must follow start | Completion time must occur after start time (when maintenance is completed) |
| Maintenance Record.start_time + current time | Past constraint | Maintenance start time must not be in the future (maintenance cannot be started before it is reported) |

---

### 2.7 Status-Based Constraint Analysis

#### Status Attribute: status

| Status Value | Required Data | Restricted Data | Candidate Rule |
| ------------ | ------------- | --------------- | -------------- |
| reported | problem_description, start_time, reporter, space, assigned_staff | completion_time, result_note must be null | A reported maintenance record requires problem description, start time, and assigned staff |
| in_progress | Same as reported | completion_time, result_note must be null | An in-progress maintenance record does not yet have completion data |
| completed | completion_time, result_note | None | A completed maintenance record requires completion time and result note |

---

### 2.8 Enumeration Constraint Analysis

#### Enumeration Attribute: status

| Value | Impacted Elements | Candidate Rule |
| ----- | ----------------- | -------------- |
| reported | Space booking availability | A maintenance record with status reported or in_progress prevents the space from being booked |
| in_progress | Space booking availability | Same as reported: space cannot be booked |
| completed | Space may become bookable again | Once maintenance is completed, the space may return to available status |

---

### 2.9 Real-World Consistency Analysis

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
| Maintenance Record.start_time + Maintenance Record.completion_time | Temporal consistency | Completion time must be after start time (if maintenance is completed) |

---

### 2.10 Relationship Constraint Analysis

(Relationships: reports — covered under User; pertains_to — covered under Space; assigned_to — covered under User)

---

### 2.11 Entity Rule Candidates

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| C033 | Completion time must occur after start time when maintenance is completed | Temporal (Maintenance Record) |
| C034 | A maintenance record with status reported or in_progress prevents the related space from being booked | Status (Maintenance Record.status) + Cross-Entity |
| C035 | A completed maintenance record requires completion time and result note | Status (Maintenance Record.status) |

---

# 3. Rule Consolidation

## Duplicate Rules Removed

| Duplicate Rule | Retained Rule |
| -------------- | ------------- |
| BR-E013: A space under maintenance cannot be booked (duplicate of BR-E007) | BR-E007 |
| C011: A space with status under_maintenance, temporarily_closed, or retired cannot be booked (same as BR-E007) | BR-E007 |
| C034: A maintenance record with status reported or in_progress prevents the related space from being booked (covered by BR-E007) | BR-E007 |

---

## Rule Merges

| Related Candidate Rules | Consolidated Rule |
| ----------------------- | ----------------- |
| C020 (rejection reason for rejected booking) + BR-E010 | BR-E010 |
| C029 (rejection reason when decision is rejected) + BR-E010 | BR-E010 |
| C012 (expected participants vs capacity) + C017 (requested time ordering) | Cross-entity consistency rules |

---

# 4. Final Business Rules

## Validation Rules

| ID | Rule |
| -- | ---- |
| BR-V001 | Requested start time must occur before requested end time. |
| BR-V002 | Expected participants must not exceed the reserved space capacity. |
| BR-V003 | Actual start time must occur before actual end time. |
| BR-V004 | Completion time must occur after start time for completed maintenance records. |
| BR-V005 | Rejection reason must be provided when an approval decision is rejected. |

---

## Permission Rules

| ID | Rule |
| -- | ---- |
| BR-P001 | Only facility staff and facility managers may approve or reject booking requests. |
| BR-P002 | Only facility staff may conduct check-in and check-out sessions. |
| BR-P003 | Only facility staff may be assigned to handle maintenance records. |
| BR-P004 | Only users with an active account status may submit booking requests. |

---

## Lifecycle Rules

| ID | Rule |
| -- | ---- |
| BR-L001 | A booking must have status pending before it can be reviewed for approval or rejection. |
| BR-L002 | An approved booking transitions to checked_in when a session is started. |
| BR-L003 | A checked-in booking transitions to completed when the session is ended. |
| BR-L004 | A booking that is approved but never checked in by the requested end time transitions to no-show. |
| BR-L005 | An approved booking requires an associated approval record with decision approved. |
| BR-L006 | A rejected booking requires an associated approval record with decision rejected and a rejection reason. |
| BR-L007 | A checked-in booking requires a session with actual start time and initial condition. |
| BR-L008 | A completed booking requires a session with actual end time, final condition, and usage notes. |

---

## Temporal Rules

| ID | Rule |
| -- | ---- |
| BR-T001 | Requested start time must occur before requested end time. |
| BR-T002 | Booking requests must have a requested start time in the future. |
| BR-T003 | Approval decision time must occur before the booking requested start time. |
| BR-T004 | Actual start time must occur before actual end time. |
| BR-T005 | Completion time must occur after start time for completed maintenance records. |

---

## State-Based Rules

| ID | Rule |
| -- | ---- |
| BR-S001 | A space with status under_maintenance, temporarily_closed, or retired cannot be booked. |
| BR-S002 | A maintenance record with status reported or in_progress prevents the related space from being booked. |
| BR-S003 | A completed maintenance record requires completion time and result note. |

---

## Relationship Rules

| ID | Rule |
| -- | ---- |
| BR-R001 | A booking must be submitted by exactly one user. |
| BR-R002 | A booking must reserve exactly one space. |
| BR-R003 | A booking may have at most one approval decision. |
| BR-R004 | A booking may have at most one corresponding session. |
| BR-R005 | An approval decision must review exactly one booking. |
| BR-R006 | A session must correspond to exactly one booking. |
| BR-R007 | A session can only exist for a booking with status approved. |
| BR-R008 | The same space cannot have two approved bookings with overlapping time periods. |
| BR-R009 | A maintenance record must be reported by exactly one user. |
| BR-R010 | A maintenance record must be assigned to exactly one facility staff member. |
| BR-R011 | A maintenance record must be associated with exactly one space. |
| BR-R012 | The reporter and assigned staff of a maintenance record may be different users. |

---

## Real-World Consistency Rules

| ID | Rule |
| -- | ---- |
| BR-C001 | Expected participants must not exceed the reserved space capacity. |
| BR-C002 | Actual start time must occur before actual end time. |
| BR-C003 | Completion time must occur after start time for completed maintenance records. |

---

# 5. Rule Traceability Matrix

| Final Rule | Source Entity | Analysis Type | Source Elements |
| ---------- | ------------- | ------------- | --------------- |
| BR-V001 | Booking | Temporal | requested_start_time, requested_end_time |
| BR-V002 | Booking + Space | Cross-Entity | expected_participants, Space.capacity |
| BR-V003 | Session | Temporal | actual_start_time, actual_end_time |
| BR-V004 | Maintenance Record | Temporal | start_time, completion_time |
| BR-V005 | Approval | Status | decision, rejection_reason |
| BR-P001 | User | Enumeration | role |
| BR-P002 | User | Enumeration | role |
| BR-P003 | User | Enumeration | role |
| BR-P004 | User | Status | account_status |
| BR-L001 | Booking | Relationship | status, reviews |
| BR-L002 | Booking | Status | status, tracks |
| BR-L003 | Booking | Status | status |
| BR-L004 | Booking | Status | status, requested_end_time |
| BR-L005 | Booking | Status | status |
| BR-L006 | Booking + Approval | Status | status, decision, rejection_reason |
| BR-L007 | Booking + Session | Status | status, actual_start_time, initial_condition |
| BR-L008 | Booking + Session | Status | status, actual_end_time, final_condition |
| BR-T001 | Booking | Temporal | requested_start_time, requested_end_time |
| BR-T002 | Booking | Temporal | requested_start_time |
| BR-T003 | Approval + Booking | Temporal | decision_time, requested_start_time |
| BR-T004 | Session | Temporal | actual_start_time, actual_end_time |
| BR-T005 | Maintenance Record | Temporal | start_time, completion_time |
| BR-S001 | Space | Status | status |
| BR-S002 | Maintenance Record + Space | Status | status, Space.status |
| BR-S003 | Maintenance Record | Status | status |
| BR-R001 | Booking + User | Relationship | submits |
| BR-R002 | Booking + Space | Relationship | reserves |
| BR-R003 | Booking + Approval | Relationship | reviews |
| BR-R004 | Booking + Session | Relationship | tracks |
| BR-R005 | Approval + Booking | Relationship | reviews |
| BR-R006 | Session + Booking | Relationship | tracks |
| BR-R007 | Session + Booking | Relationship | tracks |
| BR-R008 | Booking + Space | Relationship | reserves |
| BR-R009 | Maintenance Record + User | Relationship | reports |
| BR-R010 | Maintenance Record + User | Relationship | assigned_to |
| BR-R011 | Maintenance Record + Space | Relationship | pertains_to |
| BR-R012 | Maintenance Record + User | Relationship | reports, assigned_to |
| BR-C001 | Booking + Space | Cross-Entity | expected_participants, Space.capacity |
| BR-C002 | Session | Temporal | actual_start_time, actual_end_time |
| BR-C003 | Maintenance Record | Temporal | start_time, completion_time |

---

# 6. Validation Checklist

* [x] All explicit business rules captured
* [x] All entities analyzed
* [x] All relationships analyzed
* [x] Related entity attributes analyzed
* [x] Cross-entity constraints analyzed
* [x] Temporal constraints analyzed
* [x] Status constraints analyzed
* [x] Enumeration constraints analyzed
* [x] Consistency constraints analyzed
* [x] Relationship constraints analyzed
* [x] Duplicate rules removed
* [x] All final rules traceable to source analysis
