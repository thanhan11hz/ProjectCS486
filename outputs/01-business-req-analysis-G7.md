# Business Requirement Analysis

## 1. Business Purpose

### Primary Goal

Develop a database system to manage the booking and usage of shared campus spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, and student workspaces) used for teaching, seminars, examinations, workshops, student projects, research activities, and academic events.

### Business Problems Addressed

- Manual process is becoming difficult to manage as demand increases.
- No automated conflict detection — overlapping bookings can occur.
- Room availability is not visible in real time.
- Unavailable spaces (under maintenance, closed, or retired) can be booked accidentally.
- Usage history is fragmented across spreadsheets and shared calendars.

### Expected Outcomes

- Prevent overlapping approved bookings for the same space.
- Prevent booking of spaces that are under maintenance, closed, or retired.
- Enable staff to view upcoming bookings, booking history, spaces under maintenance, and no-show bookings.
- Record decision audit trail (who approved/rejected, when, and why, including rejection reason).
- Fair and transparent allocation of shared campus spaces.
- Reduced administrative overhead from manual coordination.
- Reliable usage history for reporting, planning, and utilization analysis.

---

## 2. Business Scope

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
- Automated notifications or email reminders.
- Integration with university course scheduling or timetabling systems.
- Self-service check-in or check-out by the requester (only facility staff can perform these actions).

---

## 3. Actors

| Actor | Description | Responsibilities |
|---------|-------------|------------------|
| Student | A university user who participates in academic activities and uses shared spaces | Submit booking requests for student activities; use booked spaces |
| Lecturer | A university user responsible for teaching and academic events | Submit booking requests for lectures, examinations, seminars, workshops; use booked spaces |
| Teaching Assistant | A university user who assists with teaching activities | Submit booking requests for academic sessions; use booked spaces |
| Facility Staff | Staff responsible for managing space bookings and maintenance | Approve or reject booking requests; check in and check out bookings; record space condition; manage maintenance records |
| Department Administrator | A university user handling administrative activities | Submit booking requests for administrative events; use booked spaces |
| Facility Manager | Senior staff who oversee the space management system | Approve or reject booking requests; oversee maintenance; manage system usage |

---

## 4. Entity Catalog

### Entity: User

**Description**

A person who interacts with the system. Users have university accounts and can act in various roles (student, lecturer, teaching assistant, facility staff, department administrator, facility manager).

**Attributes**

| Attribute | Description |
|------------|------------|
| user_id | Unique identifier for each user |
| full_name | User's full name |
| email | University email address |
| phone_number | Contact phone number |
| role | Enumeration: student, lecturer, teaching_assistant, facility_staff, department_administrator, facility_manager |
| department | Organizational affiliation |
| account_status | Enumeration: active, suspended |

---

### Entity: Space

**Description**

A bookable physical location on campus managed by the School of Computer Science.

**Attributes**

| Attribute | Description |
|------------|------------|
| space_code | Unique identifier for the space |
| space_name | Human-readable name for the space |
| space_type | Enumeration: auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace |
| building | Building name or code |
| floor | Floor number within the building |
| room_number | Room identifier within the building |
| capacity | Maximum number of occupants |
| status | Enumeration: available, in_use, under_maintenance, temporarily_closed, retired |
| usage_policy | Rules governing how the space may be used |

---

### Entity: Facility

**Description**

Equipment or amenities available in a space. Examples include projector, whiteboard, microphone, computer, livestreaming equipment, air conditioner.

**Attributes**

| Attribute | Description |
|------------|------------|
| facility_id | Unique identifier for each facility type |
| facility_name | Descriptive name of the facility |
| description | Optional details about the facility |

---

### Entity: Booking

**Description**

A request submitted by a user to reserve a space for a specific time period and purpose.

**Attributes**

| Attribute | Description |
|------------|------------|
| booking_id | Unique identifier for the booking request |
| requested_start_time | When the requester wants the booking to begin |
| requested_end_time | When the requester wants the booking to end |
| purpose | Enumeration: lecture, examination, seminar, workshop, meeting, student_activity, administrative_event |
| expected_participants | Number of people expected to attend |
| status | Enumeration: pending, approved, rejected, cancelled, checked_in, completed, no_show |

---

### Entity: Approval

**Description**

A decision made by facility staff or manager to approve or reject a booking request.

**Attributes**

| Attribute | Description |
|------------|------------|
| approval_id | Unique identifier for the approval decision |
| decision | Enumeration: approved, rejected |
| decision_time | When the decision was made |
| decision_note | Notes accompanying the decision |
| rejection_reason | Required if the booking was rejected |

---

### Entity: Session

**Description**

The actual usage of a space corresponding to a booking. Captures what happened in reality versus what was requested.

**Attributes**

| Attribute | Description |
|------------|------------|
| session_id | Unique identifier for the session |
| actual_start_time | When the space was actually occupied |
| actual_end_time | When the usage actually ended |
| initial_condition | Condition of the space at check-in |
| final_condition | Condition of the space at completion |
| usage_notes | Any notes about the usage session |

---

### Entity: Maintenance Record

**Description**

A record of a maintenance issue reported for a space, tracking the problem through resolution.

**Attributes**

| Attribute | Description |
|------------|------------|
| maintenance_id | Unique identifier for the maintenance record |
| problem_description | Description of the issue |
| start_time | When the maintenance was reported or started |
| completion_time | When the maintenance was completed |
| status | Enumeration: reported, in_progress, completed |
| result_note | Outcome of the maintenance work |

---

## 5. Relationship Catalog

| Relationship | Source Entity | Target Entity | Cardinality | Description |
|--------------|--------------|--------------|-------------|-------------|
| submits | User | Booking | 1:N | A user (requester) creates a booking request to reserve a space |
| reserves | Booking | Space | N:1 | A booking request reserves a specific space for a defined time period |
| makes | User | Approval | 1:N | A facility staff member or manager makes an approval decision on a booking request |
| reviews | Approval | Booking | 1:1 | An approval decision reviews and determines the outcome of a specific booking request |
| conducts | User | Session | 1:N | Facility staff conduct a usage session by performing check-in and completion operations |
| tracks | Session | Booking | 1:1 | A session records the actual usage that corresponds to an approved booking |
| reports | User | Maintenance Record | 1:N | A user reports a maintenance issue, creating a maintenance record for a space |
| pertains_to | Maintenance Record | Space | N:1 | A maintenance record describes an issue with a specific space |
| equipped_with | Space | Facility | M:N | A space is equipped with various facilities; a facility may be available in multiple spaces |
| assigned_to | User | Maintenance Record | 1:N | A facility staff member is assigned to handle a specific maintenance record |

### Relationship Attributes

| Relationship | Attribute | Description |
|--------------|-----------|-------------|
| equipped_with | quantity | Number of units of a facility in a space |

---

## 6. Business Rules

### Entity Rules

| ID | Rule |
|----|------|
| BR-01 | Each user must have a university account. |
| BR-02 | A user may be a student, lecturer, teaching assistant, facility staff, department administrator, or facility manager. |
| BR-03 | A space may be available, in use, under maintenance, temporarily closed, or retired. |
| BR-04 | A booking may be for a lecture, examination, seminar, workshop, meeting, student activity, or administrative event. |
| BR-05 | Each booking request has a status: pending, approved, rejected, cancelled, checked in, completed, or no-show. |
| BR-06 | The system must keep historical records of bookings and maintenance activities. |

---

### Relationship Rules

| ID | Rule |
|----|------|
| BR-07 | A booking must be submitted by exactly one user. |
| BR-08 | A booking must reserve exactly one space. |
| BR-09 | A booking may have at most one approval decision. |
| BR-10 | A booking may have at most one corresponding session. |
| BR-11 | An approval decision must review exactly one booking. |
| BR-12 | A session must correspond to exactly one booking. |
| BR-13 | A session can only exist for a booking with status approved. |
| BR-14 | The same space cannot have two approved bookings with overlapping time periods. |
| BR-15 | A maintenance record must be reported by exactly one user. |
| BR-16 | A maintenance record must be assigned to exactly one facility staff member. |
| BR-17 | A maintenance record must be associated with exactly one space. |
| BR-18 | The reporter and assigned staff of a maintenance record may be different users. |
| BR-19 | A space may have multiple maintenance records over time but should not have overlapping active (open) maintenance records. |

---

### Status and Lifecycle Rules

| ID | Rule |
|----|------|
| BR-20 | Only users with an active account status may submit booking requests. |
| BR-21 | Only facility staff and facility managers may approve or reject booking requests. |
| BR-22 | Only facility staff may conduct check-in and check-out sessions. |
| BR-23 | Only facility staff may be assigned to handle maintenance records. |
| BR-24 | A booking must have status pending before it can be reviewed for approval or rejection. |
| BR-25 | An approved booking transitions to checked_in when a session is started. |
| BR-26 | A checked-in booking transitions to completed when the session is ended. |
| BR-27 | A booking that is approved but never checked in by the requested end time transitions to no-show. |
| BR-28 | An approved booking requires an associated approval record with decision approved. |
| BR-29 | A rejected booking requires an associated approval record with decision rejected and a rejection reason. |
| BR-30 | A checked-in booking requires a session with actual start time and initial condition. |
| BR-31 | A completed booking requires a session with actual end time, final condition, and usage notes. |
| BR-32 | A space with status under_maintenance, temporarily_closed, or retired cannot be booked. |
| BR-33 | A maintenance record with status reported or in_progress prevents the related space from being booked. |
| BR-34 | A completed maintenance record requires completion time and result note. |

---

### Temporal Rules

| ID | Rule |
|----|------|
| BR-35 | Requested start time must occur before requested end time. |
| BR-36 | Booking requests must have a requested start time in the future. |
| BR-37 | Approval decision time must occur before the booking requested start time. |
| BR-38 | Actual start time must occur before actual end time. |
| BR-39 | Completion time must occur after start time for completed maintenance records. |

---

### Validation and Consistency Rules

| ID | Rule |
|----|------|
| BR-40 | Expected participants must not exceed the reserved space capacity. |
| BR-41 | Rejection reason must be provided when an approval decision is rejected. |

---

## 7. Assumptions

| ID | Assumption |
|----|------------|
| A-01 | A booking request is always associated with a single space. |
| A-02 | A booking can have at most one approval decision. |
| A-03 | A session is always linked to exactly one approved booking. |
| A-04 | Facility is modeled as an entity rather than a multi-valued attribute to support future equipment tracking. |
| A-05 | A user may submit multiple booking requests (no explicit limitation specified). |
| A-06 | Booking lifecycle states follow the sequence: pending, approved/rejected, checked_in, completed/no-show. |
| A-07 | Facility staff and facility manager roles can both approve bookings and perform check-in/check-out operations (manager inherits staff capabilities). |

---

## 8. Ambiguities

| ID | Requirement Area | Description |
|----|------------------|-------------|
| AM-01 | Incident Reporting | What does "incident reporting" entail? Is it separate from maintenance records? May require an additional Incident entity if scoped independently of maintenance. |
| AM-02 | User Roles | Can a user have multiple roles? Affects whether role is a single-valued or multi-valued attribute of User. |
| AM-03 | Booking Modification | Can a booking be modified after submission (e.g., time change) before approval? Affects Booking lifecycle states and whether modification history must be tracked. |
| AM-04 | Booking Status Transitions | What is the exact set of valid booking statuses and their allowed transitions? Affects data validation rules for Booking.status. |
| AM-05 | Booking Duration Limits | Is there a maximum duration or advance booking window for booking requests? No restriction is specified in the requirements. |
| AM-06 | Facility Staff as Requesters | Are facility staff allowed to submit booking requests for themselves, or do they only process requests from others? The actor description does not explicitly state this. |

---

## 9. Validation Summary

### Coverage Summary

| Area | Status |
|--------|--------|
| Business Purpose | Complete |
| Actors | Complete |
| Entities | Complete |
| Relationships | Complete |
| Business Rules | Complete |

---

### Validation Findings

#### Duplicates Removed

| Duplicate | Action |
|-----------|--------|
| BR-E013 ("A space under maintenance cannot be booked") | Removed — duplicate of BR-E007 |
| C011 ("A space with status under_maintenance, temporarily_closed, or retired cannot be booked") | Removed — duplicate of BR-E007 |
| C034 ("A maintenance record with status reported or in_progress prevents the related space from being booked") | Removed — covered by BR-E007 |
| C020, C029 (rejection reason rules) | Merged — consolidated into BR-41 |
| Temporal rules overlapping across BR-V00x, BR-T00x, BR-C00x categories | Consolidated — unique rules retained in Temporal Rules section (BR-35 to BR-39) and Validation section (BR-40 to BR-41) |

#### Inconsistencies Found

- None. All artifacts were consistent. No naming conflicts, contradictory definitions, or orphan elements were found.

#### Unresolved Issues

- Incident reporting scope (AM-01) remains unresolved — may require clarification from stakeholders on whether this is separate from maintenance records.
- Booking duration limits (AM-05) and facility staff as requesters (AM-06) are open questions requiring stakeholder input.

---

## 10. Final Analysis Summary

### Total Actors

6

### Total Entities

7

### Total Relationships

10

### Total Business Rules

41

### Readiness Assessment

The business requirement analysis is complete and suitable as input for Conceptual ERD Design.
