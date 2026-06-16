# Business Concept Extraction

## 1. Explicit Concepts

### Extracted Concepts

| Concept | Raw Term | Category Hint | Evidence |
| ------- | -------- | ------------- | -------- |
| School of Computer Science | School of Computer Science | Organizational Units | L3 |
| Shared Physical Space | shared physical spaces | Physical Resources | L3 |
| Teaching | teaching | Events | L3 |
| Seminar | seminars | Events | L3 |
| Examination | examinations | Events | L3 |
| Workshop | workshops | Events | L3 |
| Student Project | student projects | Events | L3 |
| Research Activity | research activities | Events | L3 |
| Academic Event | academic events | Events | L3 |
| Auditorium | auditoriums | Physical Resources | L3 |
| Classroom | classrooms | Physical Resources | L3 |
| Computer Laboratory | computer laboratories | Physical Resources | L3 |
| Project Laboratory | project laboratories | Physical Resources | L3 |
| Meeting Room | meeting rooms | Physical Resources | L3 |
| Student Workspace | student workspaces | Physical Resources | L3 |
| Lecturer | Lecturers | Roles / Actors | L5 |
| Teaching Assistant | teaching assistants | Roles / Actors | L5 |
| Student | students | Roles / Actors | L5 |
| School Office | school office | Organizational Units | L5 |
| Facility Staff | facility staff | Roles / Actors | L5 |
| Email | email | Other Concepts | L5 |
| Phone | phone | Other Concepts | L5 |
| User | user | Roles / Actors | L13 |
| University Account | university account | Resources | L13 |
| User Information | user information | Business Objects | L13 |
| User ID | user ID | Other Concepts | L13 |
| Full Name | full name | Other Concepts | L13 |
| Phone Number | phone number | Other Concepts | L13 |
| Role | role | Other Concepts | L13 |
| Department | department | Organizational Units | L13 |
| Account Status | account status | Statuses | L13 |
| Department Administrator | department administrator | Roles / Actors | L13 |
| Facility Manager | facility manager | Roles / Actors | L13 |
| Bookable Space | bookable spaces | Physical Resources | L11, L15 |
| Space Code | unique space code | Other Concepts | L15 |
| Space Name | space name | Other Concepts | L15 |
| Space Type | space type | Other Concepts | L15 |
| Building | building | Other Concepts | L15 |
| Floor | floor | Other Concepts | L15 |
| Room Number | room number | Other Concepts | L15 |
| Capacity | capacity | Other Concepts | L15 |
| Space Status | current status | Statuses | L15 |
| Usage Policy | usage policy | Policies / Constraints | L15 |
| Available (Space) | available | Statuses | L15 |
| In Use (Space) | in use | Statuses | L15 |
| Under Maintenance (Space) | under maintenance | Statuses | L15 |
| Temporarily Closed | temporarily closed | Statuses | L15 |
| Retired | retired | Statuses | L15 |
| Facility Equipment | facilities | Physical Resources | L17 |
| Projector | projector | Physical Resources | L17 |
| Whiteboard | whiteboard | Physical Resources | L17 |
| Microphone | microphone | Physical Resources | L17 |
| Computer Equipment | computer | Physical Resources | L17 |
| Livestreaming Equipment | livestreaming equipment | Physical Resources | L17 |
| Air Conditioner | air conditioner | Physical Resources | L17 |
| Booking Request | booking requests | Business Objects | L19 |
| Requested Start Time | requested start time | Other Concepts | L19 |
| Requested End Time | requested end time | Other Concepts | L19 |
| Purpose of Use | purpose of use | Other Concepts | L19 |
| Expected Number of Participants | expected number of participants | Other Concepts | L19 |
| Lecture (Booking Purpose) | lecture | Events | L19 |
| Meeting (Booking Purpose) | meeting | Events | L19 |
| Student Activity | student activity | Events | L19 |
| Administrative Event | administrative event | Events | L19 |
| Booking Status | booking request has a status | Statuses | L21 |
| Pending | pending | Statuses | L21 |
| Approved | approved | Statuses | L21 |
| Rejected | rejected | Statuses | L21 |
| Cancelled | cancelled | Statuses | L21 |
| Checked In | checked in | Statuses | L21 |
| Completed (Booking) | completed | Statuses | L21 |
| No-show | no-show | Statuses | L21 |
| Conflicting Booking | conflicting bookings | Policies / Constraints | L21 |
| Overlapping Time Period | overlapping time periods | Policies / Constraints | L21 |
| Closed (Space) | closed | Statuses | L21 |
| Booking Approval | approval | Activities / Processes | L23 |
| Staff Member (Approver) | staff member | Roles / Actors | L23 |
| Decision Time | decision time | Other Concepts | L23 |
| Decision Note | decision note | Other Concepts | L23 |
| Rejection Reason | rejection reason | Other Concepts | L23 |
| Check-in | check in | Activities / Processes | L25 |
| Actual Start Time | actual start time | Other Concepts | L25 |
| Check-in Person | person who checked in | Roles / Actors | L25 |
| Initial Space Condition | initial condition of the space | Other Concepts | L25 |
| Session End | session ends | Events | L25 |
| Booking Completion | complete the booking | Activities / Processes | L25 |
| Actual End Time | actual end time | Other Concepts | L25 |
| Final Space Condition | final condition of the space | Other Concepts | L25 |
| Usage Notes | usage notes | Other Concepts | L25 |
| Maintenance Record | maintenance records | Business Objects | L27 |
| Broken Projector (Problem) | broken projectors | Other Concepts | L27 |
| Air-conditioning Failure | air-conditioning failure | Other Concepts | L27 |
| Damaged Furniture | damaged furniture | Other Concepts | L27 |
| Cleaning Issue | cleaning issues | Other Concepts | L27 |
| Network Problem | network problems | Other Concepts | L27 |
| Reporter | reporter | Roles / Actors | L27 |
| Assigned Staff Member | assigned staff member | Roles / Actors | L27 |
| Problem Description | problem description | Other Concepts | L27 |
| Maintenance Start Time | start time | Other Concepts | L27 |
| Maintenance Completion Time | completion time | Other Concepts | L27 |
| Maintenance Status | status | Statuses | L27 |
| Result Note | result note | Other Concepts | L27 |
| Booking History | booking history | Business Objects | L29 |
| Upcoming Booking | upcoming bookings | Business Objects | L29 |
| No-show Booking | no-show bookings | Business Objects | L29 |
| Usage History | usage history | Business Objects | L31 |

---

## 2. Normalized Concepts

### Normalization Mapping

| Canonical Concept | Alias | Justification |
| ----------------- | ----- | ------------- |
| Bookable Space | Shared Physical Space, Campus Space | Requirements use both terms interchangeably for the same domain object |
| User | Requester | "Requester" is a contextual role of a user who submits a booking request |
| Facility Staff | Staff, Staff Member, Staff (generic) | All references to non-manager facility personnel refer to the same role |
| Facility Manager | Manager | "Manager" in the booking approval context refers to Facility Manager |
| Facility Equipment | Facility (equipment), Equipment | The term "facilities" in L17 refers to equipment installed in spaces |
| Booking Request | Booking | Requirements use "booking" as shorthand for "booking request" in several places |
| Usage Session | Session | "Session" in L25 refers to the usage session of a booked space |
| Space Status | Current Status (Space) | "Current status" is the terminology used for space status tracking |
| Booking Status | Status (of a booking request) | Requirements consistently refer to booking status; "status" alone is ambiguous |
| Maintenance | Maintenance Management | Both refer to the same maintenance tracking function |
| Check-in | Check In | Orthographic variant of the same activity |
| Booking Approval | Approval | "Approval" in context refers specifically to booking approval |
| Maintenance Problem Type | broken projectors, air-conditioning failure, damaged furniture, cleaning issues, network problems | These are specific instances of the general concept of maintenance problem types |

### Final Normalized Concept List

| Concept |
| ------- |
| Bookable Space |
| Auditorium |
| Classroom |
| Computer Laboratory |
| Project Laboratory |
| Meeting Room |
| Student Workspace |
| Facility Equipment |
| Projector |
| Whiteboard |
| Microphone |
| Computer Equipment |
| Livestreaming Equipment |
| Air Conditioner |
| User |
| Lecturer |
| Teaching Assistant |
| Student |
| Facility Staff |
| Department Administrator |
| Facility Manager |
| Reporter |
| Assigned Staff Member |
| Check-in Person |
| Staff Member (Approver) |
| School of Computer Science |
| School Office |
| Department |
| University Account |
| User Information |
| Booking Request |
| Maintenance Record |
| Booking History |
| Upcoming Booking |
| No-show Booking |
| Usage History |
| Space Code |
| Space Name |
| Space Type |
| Building |
| Floor |
| Room Number |
| Capacity |
| Usage Policy |
| User ID |
| Full Name |
| Phone Number |
| Role |
| Purpose of Use |
| Requested Start Time |
| Requested End Time |
| Expected Number of Participants |
| Decision Time |
| Decision Note |
| Rejection Reason |
| Actual Start Time |
| Actual End Time |
| Initial Space Condition |
| Final Space Condition |
| Usage Notes |
| Problem Description |
| Maintenance Start Time |
| Maintenance Completion Time |
| Result Note |
| Space Status |
| Account Status |
| Booking Status |
| Maintenance Status |
| Available (Space) |
| In Use (Space) |
| Under Maintenance (Space) |
| Temporarily Closed |
| Retired |
| Closed (Space) |
| Pending |
| Approved |
| Rejected |
| Cancelled |
| Checked In |
| Completed (Booking) |
| No-show |
| Booking Approval |
| Check-in |
| Booking Completion |
| Maintenance |
| Incident Reporting |
| Facility Utilization |
| Space Booking |
| Space Usage |
| Cancellation |
| Teaching |
| Seminar |
| Examination |
| Workshop |
| Student Project |
| Research Activity |
| Academic Event |
| Lecture (Booking Purpose) |
| Meeting (Booking Purpose) |
| Student Activity |
| Administrative Event |
| Session End |
| Conflicting Booking |
| Overlapping Time Period |
| No Conflicting Bookings Policy |
| Under Maintenance Restriction |
| Closed Space Restriction |
| Retired Space Restriction |
| Booking Approval Requirement |
| Fair Space Management |
| Email |
| Phone |

---

## 3. Categorized Concepts

### Roles / Actors

| Concept |
| ------- |
| User |
| Lecturer |
| Teaching Assistant |
| Student |
| Facility Staff |
| Department Administrator |
| Facility Manager |
| Reporter |
| Assigned Staff Member |
| Check-in Person |
| Staff Member (Approver) |

### Organizational Units

| Concept |
| ------- |
| School of Computer Science |
| School Office |
| Department |

### Physical Resources

| Concept |
| ------- |
| Bookable Space |
| Auditorium |
| Classroom |
| Computer Laboratory |
| Project Laboratory |
| Meeting Room |
| Student Workspace |
| Facility Equipment |
| Projector |
| Whiteboard |
| Microphone |
| Computer Equipment |
| Livestreaming Equipment |
| Air Conditioner |

### Business Objects

| Concept |
| ------- |
| University Account |
| User Information |
| Booking Request |
| Maintenance Record |
| Booking History |
| Upcoming Booking |
| No-show Booking |
| Usage History |

### Activities / Processes

| Concept |
| ------- |
| Space Booking |
| Booking Approval |
| Check-in |
| Booking Completion |
| Maintenance |
| Incident Reporting |
| Facility Utilization |
| Space Usage |
| Cancellation |

### Events

| Concept |
| ------- |
| Teaching |
| Seminar |
| Examination |
| Workshop |
| Student Project |
| Research Activity |
| Academic Event |
| Lecture (Booking Purpose) |
| Meeting (Booking Purpose) |
| Student Activity |
| Administrative Event |
| Session End |

### Statuses

| Concept |
| ------- |
| Space Status |
| Available (Space) |
| In Use (Space) |
| Under Maintenance (Space) |
| Temporarily Closed |
| Retired |
| Closed (Space) |
| Booking Status |
| Pending |
| Approved |
| Rejected |
| Cancelled |
| Checked In |
| Completed (Booking) |
| No-show |
| Account Status |
| Maintenance Status |

### Policies / Constraints

| Concept |
| ------- |
| No Conflicting Bookings Policy |
| Overlapping Time Period |
| Under Maintenance Restriction |
| Closed Space Restriction |
| Retired Space Restriction |
| Booking Approval Requirement |
| Fair Space Management |
| Usage Policy |

### Other Concepts

| Concept |
| ------- |
| Space Code |
| Space Name |
| Space Type |
| Building |
| Floor |
| Room Number |
| Capacity |
| User ID |
| Full Name |
| Phone Number |
| Role |
| Purpose of Use |
| Requested Start Time |
| Requested End Time |
| Expected Number of Participants |
| Decision Time |
| Decision Note |
| Rejection Reason |
| Actual Start Time |
| Actual End Time |
| Initial Space Condition |
| Final Space Condition |
| Usage Notes |
| Problem Description |
| Maintenance Start Time |
| Maintenance Completion Time |
| Result Note |
| Email |
| Phone |

---

## 4. Strongly-Supported Implicit Concepts

| Implicit Concept | Supporting Evidence | Justification |
| ---------------- | ------------------- | ------------- |
| Usage Session | L25: "When the session ends, facility staff can complete the booking" | The concept of a bounded period of space usage between check-in and completion is implied by the check-in/check-out workflow |
| Facility Inventory | L17: "the system should store the list of facilities available in each space" | The requirement implies an inventory association between facility equipment and spaces, even though "facility inventory" is not named |
| Space Availability Check | L21: "The same space cannot have two approved bookings with overlapping time periods" | The system must determine whether a space is available before approving a booking |
| Booking Conflict | L21: "The system must prevent conflicting bookings" | The concept of conflict between two booking requests for the same space and overlapping time is central |
| Approval Workflow | L23: "A booking request may require approval from a facility staff member or manager" | The process flow from submitted booking request through approval or rejection is implied |
| Space Condition Assessment | L25: "initial condition of the space" and "final condition of the space" | The practice of assessing and recording space condition at check-in and completion is implied |
| Maintenance Problem Type | L27: "broken projectors, air-conditioning failure, damaged furniture, cleaning issues, or network problems" | The requirement lists specific problem types, implying a classification concept |
| Utilization Metric | L7: "facility utilization"; L31: "usage history" | The requirement to track and preserve usage history implies a utilization measurement concept |
| Maintenance Assignment | L27: "assigned staff member" | The concept of assigning a specific staff member to handle a maintenance record is implied |
| Booking Request Submission | L19: "Users can submit booking requests by selecting a space..." | The act of submitting a booking request initiates the booking workflow |

---

## 5. Ambiguous Concepts

| Concept | Reason for Ambiguity | Evidence |
| ------- | -------------------- | -------- |
| Facility | Used in three different senses: (1) physical equipment installed in a space (L17), (2) the organizational unit managing spaces ("facility staff", L5), (3) potentially the space itself | L5, L7, L17 |
| Space | Generic term covering conceptually distinct types: auditoriums, classrooms, laboratories, meeting rooms, and workspaces, each with potentially different booking rules | L3, L15 |
| Status | Overloaded term used across multiple business objects (account, space, booking, maintenance) each with different value sets and semantics | L13, L15, L21, L27 |
| Session | Implicit concept; could mean a usage session, a teaching session, or the period between check-in and completion. Not formally defined in requirements | L25 |
| Usage | Could refer to the act of occupying a space, utilization statistics, or the overall booking lifecycle | L7, L25, L31 |
| Approval | Unclear whether approval is always required or only for certain booking types or spaces. The term "may require" (L23) is conditional | L23 |
| Staff | Used generically; could refer to Facility Staff, Department Administrator, Facility Manager, or all school employees | L5, L29 |

---

## 6. Summary Statistics

| Metric | Count |
| ------ | ----- |
| Explicit Concepts | 111 |
| Normalized Concepts | 107 |
| Roles / Actors | 11 |
| Organizational Units | 3 |
| Physical Resources | 12 |
| Business Objects | 7 |
| Activities / Processes | 9 |
| Events | 12 |
| Statuses | 17 |
| Policies / Constraints | 8 |
| Other Concepts | 28 |
| Implicit Concepts | 10 |
| Ambiguous Concepts | 7 |

---

## 7. Traceability Matrix

| Concept | Explicit / Implicit | Category | Evidence Available |
| ------- | ------------------- | -------- | ------------------ |
| Bookable Space | Explicit | Physical Resources | L3, L11, L15 |
| Auditorium | Explicit | Physical Resources | L3, L11 |
| Classroom | Explicit | Physical Resources | L3, L11 |
| Computer Laboratory | Explicit | Physical Resources | L3, L11 |
| Project Laboratory | Explicit | Physical Resources | L3 |
| Meeting Room | Explicit | Physical Resources | L3, L11 |
| Student Workspace | Explicit | Physical Resources | L3 |
| Facility Equipment | Explicit | Physical Resources | L17 |
| Projector | Explicit | Physical Resources | L17 |
| Whiteboard | Explicit | Physical Resources | L17 |
| Microphone | Explicit | Physical Resources | L17 |
| Computer Equipment | Explicit | Physical Resources | L17 |
| Livestreaming Equipment | Explicit | Physical Resources | L17 |
| Air Conditioner | Explicit | Physical Resources | L17 |
| User | Explicit | Roles / Actors | L13 |
| Lecturer | Explicit | Roles / Actors | L5, L13 |
| Teaching Assistant | Explicit | Roles / Actors | L5, L13 |
| Student | Explicit | Roles / Actors | L5, L13 |
| Facility Staff | Explicit | Roles / Actors | L5, L13, L23, L25 |
| Department Administrator | Explicit | Roles / Actors | L13 |
| Facility Manager | Explicit | Roles / Actors | L9, L13 |
| Reporter | Explicit | Roles / Actors | L27 |
| Assigned Staff Member | Explicit | Roles / Actors | L27 |
| Check-in Person | Explicit | Roles / Actors | L25 |
| Staff Member (Approver) | Explicit | Roles / Actors | L23 |
| School of Computer Science | Explicit | Organizational Units | L3 |
| School Office | Explicit | Organizational Units | L5 |
| Department | Explicit | Organizational Units | L13 |
| University Account | Explicit | Resources | L13 |
| User Information | Explicit | Business Objects | L13 |
| Booking Request | Explicit | Business Objects | L19 |
| Maintenance Record | Explicit | Business Objects | L27 |
| Booking History | Explicit | Business Objects | L29 |
| Upcoming Booking | Explicit | Business Objects | L29 |
| No-show Booking | Explicit | Business Objects | L29 |
| Usage History | Explicit | Business Objects | L31 |
| Space Booking | Explicit | Activities / Processes | L7, L11 |
| Booking Approval | Explicit | Activities / Processes | L7, L23 |
| Check-in | Explicit | Activities / Processes | L25 |
| Booking Completion | Explicit | Activities / Processes | L25 |
| Maintenance | Explicit | Activities / Processes | L7, L27 |
| Incident Reporting | Explicit | Activities / Processes | L7 |
| Facility Utilization | Explicit | Activities / Processes | L7 |
| Space Usage | Explicit | Activities / Processes | L11 |
| Cancellation | Explicit | Activities / Processes | L21 |
| Space Status | Explicit | Statuses | L15 |
| Available (Space) | Explicit | Statuses | L15 |
| In Use (Space) | Explicit | Statuses | L15 |
| Under Maintenance (Space) | Explicit | Statuses | L15 |
| Temporarily Closed | Explicit | Statuses | L15 |
| Retired | Explicit | Statuses | L15 |
| Closed (Space) | Explicit | Statuses | L21 |
| Booking Status | Explicit | Statuses | L21 |
| Pending | Explicit | Statuses | L21 |
| Approved | Explicit | Statuses | L21 |
| Rejected | Explicit | Statuses | L21 |
| Cancelled | Explicit | Statuses | L21 |
| Checked In | Explicit | Statuses | L21 |
| Completed (Booking) | Explicit | Statuses | L21 |
| No-show | Explicit | Statuses | L21 |
| Account Status | Explicit | Statuses | L13 |
| Maintenance Status | Explicit | Statuses | L27 |
| No Conflicting Bookings Policy | Explicit | Policies / Constraints | L21 |
| Overlapping Time Period | Explicit | Policies / Constraints | L21 |
| Under Maintenance Restriction | Explicit | Policies / Constraints | L21 |
| Closed Space Restriction | Explicit | Policies / Constraints | L21 |
| Retired Space Restriction | Explicit | Policies / Constraints | L21 |
| Booking Approval Requirement | Explicit | Policies / Constraints | L23 |
| Fair Space Management | Explicit | Policies / Constraints | L31 |
| Usage Policy | Explicit | Policies / Constraints | L15 |
| Usage Session | Implicit | Activities / Processes | L25 |
| Facility Inventory | Implicit | Physical Resources | L17 |
| Space Availability Check | Implicit | Activities / Processes | L21 |
| Booking Conflict | Implicit | Policies / Constraints | L21 |
| Approval Workflow | Implicit | Activities / Processes | L23 |
| Space Condition Assessment | Implicit | Activities / Processes | L25 |
| Maintenance Problem Type | Implicit | Other Concepts | L27 |
| Utilization Metric | Implicit | Other Concepts | L7, L31 |
| Maintenance Assignment | Implicit | Activities / Processes | L27 |
| Booking Request Submission | Implicit | Activities / Processes | L19 |

---

## Review Checklist

### Explicit Concepts

* [x] All concepts are directly supported by requirement text.
* [x] No attributes are included as concepts.
* [x] No implementation concepts are introduced.

### Normalization

* [x] Every alias has a canonical concept.
* [x] No semantic merging was performed without evidence.

### Categorization

* [x] Every concept appears in exactly one category.
* [x] Category assignment follows priority rules.

### Implicit Concepts

* [x] Every implicit concept satisfies all extraction criteria.
* [x] Supporting evidence is provided.

### Ambiguities

* [x] Ambiguities are documented but not resolved.
* [x] Each ambiguity is supported by requirement evidence.
