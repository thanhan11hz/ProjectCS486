# Updated ERD and Logical Database Design (Phase 2)

Baseline: `outputs/02-erd-design-G7.md`, `outputs/03-logical-design-G7.md` (Phase 1)
Changes source: `outputs/08-req-change-analysis-G7.md` (RC-01 .. RC-08)
Status: incremental design update — the Phase 1 design is preserved and extended, not redesigned.

---

## 1. Requirement Changes Applied

| ID | Requirement Change | Design Impact |
| -- | ------------------ | ------------- |
| RC-01 | Maintenance impact levels (out-of-service / advisory). | New attribute `Maintenance_Record.impact_level`; booking availability now governed by impact level (BR-42, BR-44). |
| RC-02 | Advisory maintenance does not block booking; requester notified and acknowledgement recorded with the booking. | New attribute `Booking.advisory_acknowledgement` (BR-45, BR-46). |
| RC-03 | Several active maintenance records per space allowed, with different impact levels. | `pertains_to` semantics change; BR-19 removed, BR-43 introduced. No structural change. |
| RC-04 | Impact level may be escalated or downgraded while the record is open. | `impact_level` is mutable while the record is open (BR-47). No history entity introduced (see Assumption UERD-02). |
| RC-05 | Identify already-approved bookings overlapping a period escalated to out-of-service. | Derived query (BR-48). No schema change. |
| RC-06 | Instant booking: auto-approval at submission for selected space types satisfying the usage policy. | Approval lifecycle extension (BR-49). No new entity; automatic Approval record (Design Decision ULD-01). |
| RC-07 | No-overlap rule must hold under concurrent operations for both booking paths. | BR-14 extended by BR-50. Enforcement delegated to the concurrency implementation stage. |
| RC-08 | New reporting needs (hours per space, by weekday/hour, availability matching, escalation impact). | Derived reports only (Assumption A-05 from 08). No schema change. |

---

## 2. Design Change Summary

| Change | Element | Requirement Changes |
| ------ | ------- | ------------------- |
| Attribute added | `Maintenance_Record.impact_level` (enumeration: advisory, out_of_service) | RC-01, RC-04 |
| Attribute added | `Booking.advisory_acknowledgement` (boolean, conditional) | RC-02 |
| Relationship semantics modified | `pertains_to` — multiple simultaneous active records per space | RC-01, RC-03 |
| Relationship semantics modified | `reserves` — advisory-permitted booking with recorded acknowledgement; extended no-overlap rule | RC-02, RC-07 |
| Business rule removed | BR-19 (no overlapping active maintenance) | RC-03 |
| Business rules added / modified | BR-14 (modified), BR-32 (modified), BR-33 (modified), BR-42 .. BR-50 (new) | RC-01 .. RC-07 |
| Entities added / removed | None | 08 §3 note |
| Relationships added / removed | None | 08 §5 |
| Candidate keys changed | None | — |

---

# Part A — Updated Conceptual ERD

## 3.1 Entity Definitions

| Entity | Type | Change | Description |
| ------ | ---- | ------ | ----------- |
| User | Strong | Unchanged | A person who interacts with the system. Users have university accounts and can act in various roles (student, lecturer, teaching assistant, facility staff, department administrator, facility manager). |
| Space | Strong | Unchanged | A bookable physical location on campus managed by the School of Computer Science. Booking availability of a space is now determined by the impact level of its active maintenance records (RC-01). |
| Facility | Strong | Unchanged | Equipment or amenities available in a space (projector, whiteboard, microphone, computer, livestreaming equipment, air conditioner, etc.). |
| Booking | Strong | Modified | A request submitted by a user to reserve a space for a specific time period and purpose. Now additionally records the requester's acknowledgement of active advisories (RC-02) and may be approved automatically at submission for selected space types (RC-06). |
| Approval | Strong | Unchanged (semantics extended) | A decision made by facility staff or manager to approve or reject a booking request. Instant bookings (RC-06) are represented by an automatic approval decision (Design Decision ULD-01). |
| Session | Strong | Unchanged | The actual usage of a space corresponding to a booking. Captures what happened in reality versus what was requested. |
| Maintenance Record | Strong | Modified | A record of a maintenance issue reported for a space, tracking the problem through resolution. Now carries an impact level (out-of-service or advisory) (RC-01); several records may be active for the same space simultaneously (RC-03); the impact level may change while the record is open (RC-04). |

No entity is added or removed (08 §3: "no new business entity is explicitly required").

---

## 3.2 Attributes

### Entity: User (unchanged)

| Attribute | Classification | Subattributes | Justification |
| --------- | -------------- | ------------- | ------------- |
| user_id | Key | — | Uniquely identifies each user |
| full_name | Composite | first_name, last_name | Can be meaningfully decomposed into first and last name components |
| email | Simple | — | Atomic value |
| phone_number | Simple | — | Atomic value |
| role | Simple | — | Atomic enumeration value |
| department | Simple | — | Atomic value |
| account_status | Simple | — | Atomic enumeration value |

### Entity: Space (unchanged)

| Attribute | Classification | Subattributes | Justification |
| --------- | -------------- | ------------- | ------------- |
| space_code | Key | — | Uniquely identifies each space |
| space_name | Simple | — | Atomic value |
| space_type | Simple | — | Atomic enumeration value |
| building | Simple | — | Atomic value |
| floor | Simple | — | Atomic value |
| room_number | Simple | — | Atomic value |
| capacity | Simple | — | Atomic numeric value |
| status | Simple | — | Atomic enumeration value |
| usage_policy | Simple | — | Atomic text value |

### Entity: Facility (unchanged)

| Attribute | Classification | Subattributes | Justification |
| --------- | -------------- | ------------- | ------------- |
| facility_id | Key | — | Uniquely identifies each facility type |
| facility_name | Simple | — | Atomic value |
| description | Simple | — | Atomic text value |

### Entity: Booking (modified)

| Attribute | Classification | Change | Subattributes | Justification |
| --------- | -------------- | ------ | ------------- | ------------- |
| booking_id | Key | Unchanged | — | Uniquely identifies each booking request |
| requested_start_time | Simple | Unchanged | — | Atomic datetime value |
| requested_end_time | Simple | Unchanged | — | Atomic datetime value |
| purpose | Simple | Unchanged | — | Atomic enumeration value |
| expected_participants | Simple | Unchanged | — | Atomic numeric value |
| status | Simple | Unchanged | — | Atomic enumeration value; lifecycle now also includes automatic approval at submission (RC-06, BR-49) |
| advisory_acknowledgement | Simple | **New (RC-02)** | — | Boolean value recording that the requester was informed of all active advisories on the space at booking time and acknowledged them (BR-46). NULL when no advisory was active at booking time; must be TRUE when advisories were active (BR-45). |

### Entity: Approval (unchanged)

| Attribute | Classification | Subattributes | Justification |
| --------- | -------------- | ------------- | ------------- |
| approval_id | Key | — | Uniquely identifies each approval decision |
| decision | Simple | — | Atomic enumeration value |
| decision_time | Simple | — | Atomic datetime value |
| decision_note | Simple | — | Atomic text value |
| rejection_reason | Simple | — | Atomic text value |

### Entity: Session (unchanged)

| Attribute | Classification | Subattributes | Justification |
| --------- | -------------- | ------------- | ------------- |
| session_id | Key | — | Uniquely identifies each session |
| actual_start_time | Simple | — | Atomic datetime value |
| actual_end_time | Simple | — | Atomic datetime value |
| initial_condition | Simple | — | Atomic text value |
| final_condition | Simple | — | Atomic text value |
| usage_notes | Simple | — | Atomic text value |

### Entity: Maintenance Record (modified)

| Attribute | Classification | Change | Subattributes | Justification |
| --------- | -------------- | ------ | ------------- | ------------- |
| maintenance_id | Key | Unchanged | — | Uniquely identifies each maintenance record |
| problem_description | Simple | Unchanged | — | Atomic text value |
| start_time | Simple | Unchanged | — | Atomic datetime value |
| completion_time | Simple | Unchanged | — | Atomic datetime value |
| status | Simple | Unchanged | — | Atomic enumeration value |
| result_note | Simple | Unchanged | — | Atomic text value |
| impact_level | Simple | **New (RC-01)** | — | The severity of the maintenance with respect to space usability (BR-42): `out_of_service` (space unusable; booking blocked for overlapping periods, BR-44) or `advisory` (space usable; requester notified, BR-45). Single-valued current level; may be escalated or downgraded while the record is open (RC-04, BR-47). |

---

## 3.3 Relationships

| Relationship | Degree | Change | Relationship Attributes | Source Entity | Target Entity | Description |
| ------------ | ------ | ------ | ---------------------- | ------------- | ------------- | ----------- |
| submits | Binary | Unchanged | — | User | Booking | A user (requester) creates a booking request to reserve a space |
| reserves | Binary | Modified (RC-02, RC-07) | — | Booking | Space | A booking request reserves a specific space for a defined time period. A booking for a space with active advisory maintenance is permitted when the requester is notified and acknowledges (BR-45, BR-46); the no-overlap rule applies to both instant and staff-approved bookings under concurrent operations (BR-50). |
| makes | Binary | Unchanged | — | User | Approval | A facility staff member or manager makes an approval decision on a booking request; instant bookings receive an automatic approval decision (RC-06) |
| reviews | Binary | Unchanged | — | Approval | Booking | An approval decision reviews and determines the outcome of a specific booking request |
| conducts | Binary | Unchanged | — | User | Session | Facility staff conduct a usage session by performing check-in and completion operations |
| tracks | Binary | Unchanged | — | Session | Booking | A session records the actual usage that corresponds to an approved booking |
| reports | Binary | Unchanged | — | User | Maintenance Record | A user reports a maintenance issue, creating a maintenance record for a space |
| pertains_to | Binary | Modified (RC-01, RC-03) | — | Maintenance Record | Space | A maintenance record describes an issue with a specific space. A space may now have several active maintenance records simultaneously with different impact levels (BR-43), replacing the former restriction against overlapping active records (BR-19 removed). Each record still describes a single space. |
| equipped_with | Binary | Unchanged | quantity | Space | Facility | A space is equipped with various facilities; a facility may be available in multiple spaces |
| assigned_to | Binary | Unchanged | — | User | Maintenance Record | A facility staff member is assigned to handle a specific maintenance record |

### Relationship Classification

| Relationship | Classification | Justification |
| ------------ | -------------- | ------------- |
| submits | Non-identifying | Both User and Booking possess independent identity. |
| reserves | Non-identifying | Both Booking and Space possess independent identity. |
| makes | Non-identifying | Both User and Approval possess independent identity. |
| reviews | Non-identifying | Both Approval and Booking possess independent identity. |
| conducts | Non-identifying | Both User and Session possess independent identity. |
| tracks | Non-identifying | Both Session and Booking possess independent identity. |
| reports | Non-identifying | Both User and Maintenance Record possess independent identity. |
| pertains_to | Non-identifying | Both Maintenance Record and Space possess independent identity. |
| equipped_with | Non-identifying | Both Space and Facility possess independent identity. |
| assigned_to | Non-identifying | Both User and Maintenance Record possess independent identity. |

---

## 3.4 Cardinality and Participation Summary

| Relationship | Source Cardinality | Source Participation | Target Cardinality | Target Participation |
| ------------ | ----------------- | ------------------- | ----------------- | -------------------- |
| submits | 1 | Partial | N | Total |
| reserves | N | Total | 1 | Partial |
| makes | 1 | Partial | N | Total |
| reviews | 1 | Total | 1 | Partial |
| conducts | 1 | Partial | N | Total |
| tracks | 1 | Total | 1 | Partial |
| reports | 1 | Partial | N | Total |
| pertains_to | N | Total | 1 | Partial |
| equipped_with | M | Partial | N | Partial |
| assigned_to | 1 | Partial | N | Total |

Cardinalities and participation constraints are unchanged from Phase 1. The semantic changes introduced by RC-01, RC-02, RC-03, and RC-07 concern the *meaning and validity conditions* of `reserves` and `pertains_to` (Section 3.3), not their cardinalities.

---

## 3.5 Updated Conceptual ERD Diagram

```mermaid
flowchart LR

%% =========================
%% Entities
%% =========================

E_User[User]
E_Space[Space]
E_Facility[Facility]
E_Booking[Booking]
E_Approval[Approval]
E_Session[Session]
E_MaintRec[Maintenance Record]

%% =========================
%% Attributes - User
%% =========================

A_U_id((<u>user_id</u>))
A_U_fullname((full_name))
A_U_fname((first_name))
A_U_lname((last_name))
A_U_email((email))
A_U_phone((phone_number))
A_U_role((role))
A_U_dept((department))
A_U_status((account_status))

%% =========================
%% Attributes - Space
%% =========================

A_S_code((<u>space_code</u>))
A_S_name((space_name))
A_S_type((space_type))
A_S_bldg((building))
A_S_floor((floor))
A_S_room((room_number))
A_S_cap((capacity))
A_S_stat((status))
A_S_policy((usage_policy))

%% =========================
%% Attributes - Facility
%% =========================

A_F_id((<u>facility_id</u>))
A_F_name((facility_name))
A_F_desc((description))

%% =========================
%% Attributes - Booking
%% =========================

A_B_id((<u>booking_id</u>))
A_B_start((requested_start_time))
A_B_end((requested_end_time))
A_B_purpose((purpose))
A_B_parts((expected_participants))
A_B_status((status))
A_B_ack((advisory_acknowledgement)) %% NEW - RC-02

%% =========================
%% Attributes - Approval
%% =========================

A_A_id((<u>approval_id</u>))
A_A_dec((decision))
A_A_time((decision_time))
A_A_note((decision_note))
A_A_reason((rejection_reason))

%% =========================
%% Attributes - Session
%% =========================

A_Sess_id((<u>session_id</u>))
A_Sess_start((actual_start_time))
A_Sess_end((actual_end_time))
A_Sess_init((initial_condition))
A_Sess_final((final_condition))
A_Sess_notes((usage_notes))

%% =========================
%% Attributes - Maintenance Record
%% =========================

A_M_id((<u>maintenance_id</u>))
A_M_problem((problem_description))
A_M_start((start_time))
A_M_comp((completion_time))
A_M_status((status))
A_M_note((result_note))
A_M_level((impact_level)) %% NEW - RC-01

%% =========================
%% Relationships
%% =========================

R_submits{submits}
R_reserves{reserves}
R_makes{makes}
R_reviews{reviews}
R_conducts{conducts}
R_tracks{tracks}
R_reports{reports}
R_pertains{pertains_to}
R_equipped{equipped_with}
RA_quantity((quantity))
R_assigned{assigned_to}

%% =========================
%% Entity-Attribute Links - User
%% =========================

E_User --- A_U_id
E_User --- A_U_fullname
A_U_fullname --- A_U_fname
A_U_fullname --- A_U_lname
E_User --- A_U_email
E_User --- A_U_phone
E_User --- A_U_role
E_User --- A_U_dept
E_User --- A_U_status

%% =========================
%% Entity-Attribute Links - Space
%% =========================

E_Space --- A_S_code
E_Space --- A_S_name
E_Space --- A_S_type
E_Space --- A_S_bldg
E_Space --- A_S_floor
E_Space --- A_S_room
E_Space --- A_S_cap
E_Space --- A_S_stat
E_Space --- A_S_policy

%% =========================
%% Entity-Attribute Links - Facility
%% =========================

E_Facility --- A_F_id
E_Facility --- A_F_name
E_Facility --- A_F_desc

%% =========================
%% Entity-Attribute Links - Booking
%% =========================

E_Booking --- A_B_id
E_Booking --- A_B_start
E_Booking --- A_B_end
E_Booking --- A_B_purpose
E_Booking --- A_B_parts
E_Booking --- A_B_status
E_Booking --- A_B_ack

%% =========================
%% Entity-Attribute Links - Approval
%% =========================

E_Approval --- A_A_id
E_Approval --- A_A_dec
E_Approval --- A_A_time
E_Approval --- A_A_note
E_Approval --- A_A_reason

%% =========================
%% Entity-Attribute Links - Session
%% =========================

E_Session --- A_Sess_id
E_Session --- A_Sess_start
E_Session --- A_Sess_end
E_Session --- A_Sess_init
E_Session --- A_Sess_final
E_Session --- A_Sess_notes

%% =========================
%% Entity-Attribute Links - Maintenance Record
%% =========================

E_MaintRec --- A_M_id
E_MaintRec --- A_M_problem
E_MaintRec --- A_M_start
E_MaintRec --- A_M_comp
E_MaintRec --- A_M_status
E_MaintRec --- A_M_note
E_MaintRec --- A_M_level

%% =========================
%% Relationship Links
%% =========================

E_User -- "1" --- R_submits
R_submits -- "N" --- E_Booking

E_Booking -- "N" --- R_reserves
R_reserves -- "1" --- E_Space

E_User -- "1" --- R_makes
R_makes -- "N" --- E_Approval

E_Approval -- "1" --- R_reviews
R_reviews -- "1" --- E_Booking

E_User -- "1" --- R_conducts
R_conducts -- "N" --- E_Session

E_Session -- "1" --- R_tracks
R_tracks -- "1" --- E_Booking

E_User -- "1" --- R_reports
R_reports -- "N" --- E_MaintRec

E_MaintRec -- "N" --- R_pertains
R_pertains -- "1" --- E_Space

E_Space -- "M" --- R_equipped
R_equipped -- "N" --- E_Facility
R_equipped --- RA_quantity

E_User -- "1" --- R_assigned
R_assigned -- "N" --- E_MaintRec
```

---

## 3.6 Updated ERD Validation

### Entity Coverage

* [X] Every accepted entity appears in the ERD.
* [X] No new entity was introduced beyond those justified by the requirement changes (08 §3: none required).
* [X] No rejected candidate appears as an entity.

### Attribute Coverage

* [X] Every major attribute appears in the ERD, including the two new attributes (`impact_level` RC-01, `advisory_acknowledgement` RC-02).
* [X] Subattributes of composite attribute are represented (full_name).
* [X] RC-05's "affected approved bookings" and RC-08's reports are derived concepts and correctly appear only as business rules (BR-48, RC-08), not as stored constructs (08 §4 note, A-05).

### Relationship Coverage

* [X] Every relationship appears in the ERD.
* [X] Every relationship includes cardinality information.
* [X] No relationship was added or removed; modified relationships (`reserves`, `pertains_to`) retain their cardinalities.

### Participation Coverage

* [X] Participation constraints are documented where known and unchanged from Phase 1.

### Conceptual Modeling Compliance

* [X] No primary keys shown.
* [X] No foreign keys shown.
* [X] No junction tables shown.
* [X] No SQL concepts shown.
* [X] Chen notation semantics preserved.

### Diagram Validation

* [X] Mermaid syntax is valid.
* [X] Mermaid Flowchart notation is used.
* [X] Mermaid ERD notation is not used.

---

# Part B — Updated Relational Schema

## 4.1 Mapping Inventory

### Entities

| Entity | Type | Identifier | Change |
| ------ | ---- | ---------- | ------ |
| User | Strong | user_id | Unchanged |
| Space | Strong | space_code | Unchanged |
| Facility | Strong | facility_id | Unchanged |
| Booking | Strong | booking_id | Modified (new attribute) |
| Approval | Strong | approval_id | Unchanged |
| Session | Strong | session_id | Unchanged |
| Maintenance Record | Strong | maintenance_id | Modified (new attribute) |

### Relationships

| Relationship | Cardinality | Attributes | Change |
| ------------ | ----------- | ---------- | ------ |
| submits | 1:N | — | Unchanged |
| reserves | N:1 | — | Semantics modified (RC-02, RC-07) |
| makes | 1:N | — | Unchanged |
| reviews | 1:1 | — | Unchanged |
| conducts | 1:N | — | Unchanged |
| tracks | 1:1 | — | Unchanged |
| reports | 1:N | — | Unchanged |
| pertains_to | N:1 | — | Semantics modified (RC-01, RC-03) |
| equipped_with | M:N | quantity | Unchanged |
| assigned_to | 1:N | — | Unchanged |

### Special Constructs

* Weak entities: none.
* Multivalued attributes: none.
* Composite attributes: User.full_name → (first_name, last_name) — unchanged.
* Recursive relationships: none.
* Specialization structures: none.

---

## 4.2 Entity Mapping

All 7 strong entities map to relations with their own simple primary keys, unchanged from Phase 1 (03 §2). The two design changes in this stage are attribute-level and are captured in Section 4.3. No new relation is introduced and no relation is removed.

---

## 4.3 Updated Attribute Catalog

Logical domains per Rule 14. "Conditional" nullability means the attribute is NULL until the lifecycle stage that requires it. The `Change` column marks attributes affected by RC-01..RC-08; all other attributes are unchanged from Phase 1.

| Relation | Attribute | Logical Domain | Nullable | Allowed Values / Range | Default | Change | Notes |
| -------- | --------- | -------------- | -------- | ---------------------- | ------- | ------ | ----- |
| User | user_id | Identifier | No | — | — | Unchanged | Primary key |
| User | first_name | String(100) | No | — | — | Unchanged | Component of full_name (Rule 8) |
| User | last_name | String(100) | No | — | — | Unchanged | Component of full_name (Rule 8) |
| User | email | Email | No | University email pattern | — | Unchanged | Candidate key (BR-01) |
| User | phone_number | Phone | Yes | — | — | Unchanged | |
| User | role | Enumeration | No | student, lecturer, teaching_assistant, facility_staff, department_administrator, facility_manager | — | Unchanged | BR-02 |
| User | department | String(100) | Yes | — | — | Unchanged | |
| User | account_status | Enumeration | No | active, suspended | active | Unchanged | Inferred default per BR-20 |
| Space | space_code | Identifier | No | — | — | Unchanged | Primary key |
| Space | space_name | String(200) | No | — | — | Unchanged | |
| Space | space_type | Enumeration | No | auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace | — | Unchanged | Instant booking eligibility per usage policy (BR-49) is evaluated against this attribute; exact eligible set open (Q-01) |
| Space | building | String(100) | No | — | — | Unchanged | Part of candidate key |
| Space | floor | String(10) | No | — | — | Unchanged | Modeled as string (LD-05) |
| Space | room_number | String(50) | No | — | — | Unchanged | Part of candidate key |
| Space | capacity | Integer | No | >= 1 | — | Unchanged | Constrains expected_participants (BR-40) |
| Space | status | Enumeration | No | available, in_use, under_maintenance, temporarily_closed, retired | available | Unchanged | BR-03; unbookable statuses per BR-32; interplay with maintenance impact levels refined (RC-01) |
| Space | usage_policy | String(1000) | Yes | — | — | Unchanged | Conditions for instant booking (BR-49) |
| Facility | facility_id | Identifier | No | — | — | Unchanged | Primary key |
| Facility | facility_name | String(100) | No | — | — | Unchanged | Candidate key |
| Facility | description | String(500) | Yes | — | — | Unchanged | |
| Booking | booking_id | Identifier | No | — | — | Unchanged | Primary key |
| Booking | requester_id | Identifier | No | — | — | Unchanged | FK → User(user_id); role name (LD-01) |
| Booking | space_code | Identifier | No | — | — | Unchanged | FK → Space(space_code); availability check now impact-level aware (BR-44, BR-45) |
| Booking | requested_start_time | Timestamp | No | In the future (BR-36) | — | Unchanged | |
| Booking | requested_end_time | Timestamp | No | After requested_start_time (BR-35) | — | Unchanged | |
| Booking | purpose | Enumeration | No | lecture, examination, seminar, workshop, meeting, student_activity, administrative_event | — | Unchanged | BR-04 |
| Booking | expected_participants | Integer | No | >= 1 and <= space capacity | — | Unchanged | BR-40 |
| Booking | status | Enumeration | No | pending, approved, rejected, cancelled, checked_in, completed, no_show | pending | Unchanged | Lifecycle extended by instant approval path (BR-49) |
| Booking | advisory_acknowledgement | Boolean | Conditional | TRUE / FALSE | NULL | **New (RC-02)** | Records that the requester was informed of all active advisories on the space at booking time and acknowledged them (BR-45, BR-46). NULL when no advisory was active on the space at booking time; required (TRUE) when one or more advisories were active (ULD-02) |
| Approval | approval_id | Identifier | No | — | — | Unchanged | Primary key |
| Approval | booking_id | Identifier | No | — | — | Unchanged | FK → Booking(booking_id); UNIQUE enforces 1:1 reviews |
| Approval | approver_id | Identifier | No | — | — | Unchanged | FK → User(user_id); for instant bookings this is a designated system account (ULD-01) |
| Approval | decision | Enumeration | No | approved, rejected | — | Unchanged | Instant bookings produce decision = approved automatically (BR-49) |
| Approval | decision_time | Timestamp | No | Before booking requested_start_time (BR-37) | — | Unchanged | |
| Approval | decision_note | String(500) | Yes | — | — | Unchanged | |
| Approval | rejection_reason | String(500) | Conditional | — | — | Unchanged | Required when decision = rejected (BR-29, BR-41) |
| Session | session_id | Identifier | No | — | — | Unchanged | Primary key |
| Session | booking_id | Identifier | No | — | — | Unchanged | FK → Booking(booking_id); UNIQUE enforces 1:1 tracks |
| Session | conductor_id | Identifier | No | — | — | Unchanged | FK → User(user_id); facility staff only (BR-22) |
| Session | actual_start_time | Timestamp | Conditional | Before actual_end_time (BR-38) | — | Unchanged | Required at check-in (BR-30) |
| Session | actual_end_time | Timestamp | Conditional | After actual_start_time (BR-38) | — | Unchanged | Required at completion (BR-31) |
| Session | initial_condition | String(500) | Conditional | — | — | Unchanged | Required at check-in (BR-30) |
| Session | final_condition | String(500) | Conditional | — | — | Unchanged | Required at completion (BR-31) |
| Session | usage_notes | String(1000) | Conditional | — | — | Unchanged | Required at completion (BR-31) |
| Maintenance_Record | maintenance_id | Identifier | No | — | — | Unchanged | Primary key |
| Maintenance_Record | reporter_id | Identifier | No | — | — | Unchanged | FK → User(user_id); may differ from assigned_staff_id (BR-18) |
| Maintenance_Record | space_code | Identifier | No | — | — | Unchanged | FK → Space(space_code); multiple active records per space now allowed (BR-43) |
| Maintenance_Record | assigned_staff_id | Identifier | No | — | — | Unchanged | FK → User(user_id); facility staff only (BR-23) |
| Maintenance_Record | problem_description | String(1000) | No | — | — | Unchanged | |
| Maintenance_Record | start_time | Timestamp | No | — | — | Unchanged | When the issue is reported |
| Maintenance_Record | completion_time | Timestamp | Conditional | After start_time (BR-39) | — | Unchanged | Required when status = completed (BR-34) |
| Maintenance_Record | status | Enumeration | No | reported, in_progress, completed | reported | Unchanged | Level changes only while open (BR-47) |
| Maintenance_Record | result_note | String(1000) | Conditional | — | — | Unchanged | Required when status = completed (BR-34) |
| Maintenance_Record | impact_level | Enumeration | No | advisory, out_of_service | advisory | **New (RC-01)** | BR-42. Severity with respect to space usability: out_of_service blocks overlapping bookings (BR-44); advisory permits booking with notification/acknowledgement (BR-45, BR-46). Single-valued current level; may be escalated/downgraded while the record is open (BR-47). Default inferred (ULD-03) |
| Space_Facility | space_code | Identifier | No | — | — | Unchanged | PK part; FK → Space(space_code) |
| Space_Facility | facility_id | Identifier | No | — | — | Unchanged | PK part; FK → Facility(facility_id) |
| Space_Facility | quantity | Integer | No | >= 1 | — | Unchanged | Relationship attribute of equipped_with |

Total: 57 attributes across 8 relations (55 Phase 1 + 2 new). Candidate keys are unchanged (User.email, Space (building, floor, room_number), Facility.facility_name).

---

## 4.4 Relationship Mapping

All mapping strategies are unchanged from Phase 1 (03 §4); no relationship mapping changes because no relationship's cardinality or degree changed:

* 1:1 `reviews`, `tracks` — FK + UNIQUE in Approval / Session (Rule 3).
* 1:N `submits`, `reserves`, `makes`, `conducts`, `reports`, `pertains_to`, `assigned_to` — FK on N-side (Rule 4).
* M:N `equipped_with` — associative relation Space_Facility (Rule 5).

Semantic changes to `reserves` and `pertains_to` (Sections 3.3, 4.1) are enforced through business rules (Section 4.6) rather than through FK structure.

---

## 4.5 Foreign Key Analysis

All 11 FK references are unchanged from Phase 1 (03 §6):

| Relation | Foreign Key | References |
| -------- | ----------- | ---------- |
| Booking | requester_id | User(user_id) |
| Booking | space_code | Space(space_code) |
| Approval | booking_id (UNIQUE) | Booking(booking_id) |
| Approval | approver_id | User(user_id) |
| Session | booking_id (UNIQUE) | Booking(booking_id) |
| Session | conductor_id | User(user_id) |
| Maintenance_Record | reporter_id | User(user_id) |
| Maintenance_Record | space_code | Space(space_code) |
| Maintenance_Record | assigned_staff_id | User(user_id) |
| Space_Facility | space_code | Space(space_code) |
| Space_Facility | facility_id | Facility(facility_id) |

---

## 4.6 Integrity Constraints

### Entity Integrity

Primary keys are unchanged for all 8 relations (03 §8). No key structure changes in this stage.

### Referential Integrity

All FK constraints are unchanged (03 §8). Nullability of the two new attributes is captured in Section 4.3.

### Business Key Constraints

Unchanged: User.email, Space (building, floor, room_number), Facility.facility_name.

### Cross-Relation Business Constraints

Logical constraints that span multiple relations (or involve temporal conditions within one relation) are documented here as application-level constraints to be enforced by the implementation layer.

| ID | Status | Constraint | Enforcement Note |
| -- | ------ | ---------- | ---------------- |
| BR-13 | Unchanged | A session may only exist for a booking with status approved. | Cross-relation (Session ↔ Booking.status); verified when a session is created. |
| BR-14 | Modified (RC-07) | The same space cannot have two approved bookings with overlapping time periods. | Temporal constraint within Booking; extended by BR-50 to hold under simultaneous operations for both booking paths. |
| BR-19 | Removed (RC-03) | ~~A space should not have overlapping active maintenance records.~~ | Superseded by BR-43; no overlap restriction applies to active maintenance records anymore. |
| BR-28 | Unchanged | An approved booking requires an associated approval record with decision approved. | Cross-relation (Booking ↔ Approval); preserved for instant bookings via an automatic Approval record (ULD-01). |
| BR-29 | Unchanged | A rejected booking requires an associated approval record with decision rejected and a rejection reason. | Cross-relation (Booking ↔ Approval). |
| BR-32 | Modified (RC-01, RC-02) | A space with status under_maintenance, temporarily_closed, or retired cannot be booked. | Cross-relation (Booking ↔ Space.status); the maintenance-related blocking behavior is refined by BR-33/BR-44 based on impact level. |
| BR-33 | Modified (RC-01, RC-02) | A maintenance record prevents booking only when it is active (reported/in_progress) with impact level out_of_service, for overlapping periods. | Cross-relation (Booking ↔ Maintenance_Record), temporal; replaces the Phase 1 blanket "any open maintenance blocks" behavior; precisely restated as BR-44. |
| BR-40 | Unchanged | Expected participants must not exceed the reserved space capacity. | Cross-relation (Booking.expected_participants ↔ Space.capacity); verified at booking submission. |
| BR-42 | New (RC-01) | Each maintenance record has an impact level: out_of_service or advisory. | Declarative: NOT NULL + CHECK on Maintenance_Record.impact_level (Section 4.3). |
| BR-43 | New (RC-03) | A space may have several active maintenance records at the same time, with different impact levels. | Negative constraint: removal of the former overlap restriction (BR-19). No constraint is created. |
| BR-44 | New (RC-01) | A space with an active out_of_service maintenance record cannot be booked for any time period overlapping the maintenance period. | Cross-relation (Booking ↔ Maintenance_Record), temporal; checked at booking submission (booking availability). |
| BR-45 | New (RC-02) | A space with only active advisory maintenance records may be booked; the requester must be notified of all active advisories at booking time. | Booking-time behavior (Space ↔ Maintenance_Record); notification obligation enforced by the application layer (Assumption A-06 from 08). |
| BR-46 | New (RC-02) | The booking must record the requester's acknowledgement that they were informed of the active advisories. | Declarative + application: conditional nullability of Booking.advisory_acknowledgement (TRUE required when advisories active at booking time, BR-45). |
| BR-47 | New (RC-04) | The impact level of an open maintenance record may be escalated (advisory → out_of_service) or downgraded; level changes apply only while the record is open. | Lifecycle rule on Maintenance_Record.status / impact_level; application-enforced. |
| BR-48 | New (RC-05) | When advisory maintenance is escalated to out_of_service, all approved bookings overlapping the maintenance period must be identifiable so staff can contact the requesters. | Derived/reporting query over Booking and Maintenance_Record; no stored construct (UERD-04). |
| BR-49 | New (RC-06) | For selected space types, booking requests satisfying the usage policy are approved automatically at submission time. | Approval lifecycle rule; realized as an automatic Approval record with decision = approved (ULD-01); eligibility depends on Space.space_type and Space.usage_policy (Q-01). |
| BR-50 | New (RC-07) | The no-overlapping-approved-bookings rule (BR-14) must hold regardless of whether bookings are created through instant booking or staff approval, and even when multiple users and staff operate concurrently. | Concurrency invariant; enforcement delegated to the concurrency implementation stage (`outputs/11-concurrency-design-G7.md`, `outputs/12-concurrency-implementation-G7.sql`). No additional schema structure required. |

---

## 4.7 Updated Relational Schema Diagram

```mermaid
erDiagram

    User ||--o{ Booking : submits
    Space ||--o{ Booking : reserves
    User ||--o{ Approval : makes
    Booking ||--o{ Approval : reviews
    User ||--o{ Session : conducts
    Booking ||--o{ Session : tracks
    User ||--o{ Maintenance_Record : reports
    Space ||--o{ Maintenance_Record : pertains_to
    Space ||--o{ Space_Facility : equipped_with
    Facility ||--o{ Space_Facility : equipped_with
    User ||--o{ Maintenance_Record : assigned_to

    User {
        identifier user_id PK
        string first_name
        string last_name
        email email
        phone phone_number
        enumeration role
        string department
        enumeration account_status
    }

    Space {
        identifier space_code PK
        string space_name
        enumeration space_type
        string building
        string floor
        string room_number
        integer capacity
        enumeration status
        string usage_policy
    }

    Facility {
        identifier facility_id PK
        string facility_name
        string description
    }

    Booking {
        identifier booking_id PK
        identifier requester_id FK
        identifier space_code FK
        timestamp requested_start_time
        timestamp requested_end_time
        enumeration purpose
        integer expected_participants
        enumeration status
        boolean advisory_acknowledgement %% NEW - RC-02
    }

    Approval {
        identifier approval_id PK
        identifier booking_id FK
        identifier approver_id FK
        enumeration decision
        timestamp decision_time
        string decision_note
        string rejection_reason
    }

    Session {
        identifier session_id PK
        identifier booking_id FK
        identifier conductor_id FK
        timestamp actual_start_time
        timestamp actual_end_time
        string initial_condition
        string final_condition
        string usage_notes
    }

    Maintenance_Record {
        identifier maintenance_id PK
        identifier reporter_id FK
        identifier space_code FK
        identifier assigned_staff_id FK
        string problem_description
        timestamp start_time
        timestamp completion_time
        enumeration status
        string result_note
        enumeration impact_level %% NEW - RC-01
    }

    Space_Facility {
        identifier space_code PK, FK
        identifier facility_id FK
        integer quantity
    }
```

The diagram is the Phase 1 schema plus the two new attributes. All 11 FK references appear as relationships; `reviews` and `tracks` are 1:N with UNIQUE semantics on the FK (unchanged from Phase 1).

---

## 4.8 Mapping Completeness Verification

| Criterion | Status |
| --------- | ------ |
| Every entity mapped to a relation | ✓ All 7 entities mapped; no entities added or removed |
| Every attribute mapped | ✓ All 57 attributes mapped across 8 relations; 2 new attributes added |
| Every attribute has an identified logical domain | ✓ Attribute Catalog (Section 4.3) |
| Enumerated domains documented | ✓ All enumeration value sets recorded, including the new `impact_level` domain (BR-42) |
| Value ranges documented | ✓ Unchanged from Phase 1; new boolean domain documented |
| Nullable attributes identified | ✓ Conditional nullability of `advisory_acknowledgement` documented (BR-45, BR-46) |
| Every identifier preserved | ✓ All PKs unchanged |
| Every relationship represented | ✓ All 10 relationships represented; none added or removed |
| 1:1 relationships mapped correctly | ✓ reviews and tracks unchanged (FK + UNIQUE) |
| 1:N relationships mapped correctly | ✓ All 1:N mappings unchanged |
| M:N relationships mapped correctly | ✓ equipped_with unchanged via Space_Facility |
| N-ary relationships mapped correctly | ✓ None identified |
| Composite attributes decomposed | ✓ full_name unchanged |
| Multivalued attributes resolved | ✓ None identified |
| Weak entities mapped correctly | ✓ None identified |
| Recursive relationships mapped | ✓ None identified |
| Relationship attributes preserved | ✓ quantity preserved in Space_Facility |
| Foreign keys identified | ✓ All 11 FK references unchanged |
| Candidate keys documented | ✓ 3 candidate keys unchanged |
| Referential integrity represented | ✓ All FK constraints unchanged |
| Cross-relation business constraints documented | ✓ 16 constraints recorded: 5 unchanged (BR-13, BR-28, BR-29, BR-40, BR-32/BR-33 as modified), 1 removed (BR-19), 9 new (BR-42 .. BR-50), 3 modified (BR-14, BR-32, BR-33) |
| All requirement changes represented | ✓ RC-01 .. RC-08 traced to design elements (Section 7) |
| No implementation-specific details | ✓ No SQL, no DBMS-specific syntax |
| Logical schema internally consistent | ✓ All references verified; bidirectional traceability maintained with Phase 1 artifacts |

---

# Part C — Design Change Log

| Change ID | Design Element | Change | Rationale | Requirement |
| --------- | -------------- | ------ | --------- | ----------- |
| CD-01 | `Maintenance_Record.impact_level` (enumeration: advisory, out_of_service) | New attribute, NOT NULL, default advisory | The impact level is the business concept at the center of RC-01: it must be stored per record because it drives booking availability (BR-44) and notification obligations (BR-45). Modeled as a simple single-valued attribute (BR-42), consistent with the requirement-change analysis that introduced no new entity. | RC-01, RC-04 |
| CD-02 | `Booking.advisory_acknowledgement` (boolean, conditional) | New attribute | RC-02 requires the acknowledgement to be "stored with the booking" (Assumption A-03 from 08). A boolean attribute on Booking is the minimal faithful representation: it records whether the requester was informed and acknowledged at booking time (BR-46). It is conditional — NULL when no advisories were active — because no acknowledgement is required when there is nothing to notify (BR-45). | RC-02 |
| CD-03 | `pertains_to` semantics | Modified: multiple simultaneous active records per space | RC-03 supersedes BR-19; the relationship's cardinality (N:1) is unchanged, only the validity condition changes. No schema structure change is needed — the previous overlap restriction was an application rule, not a structural constraint. | RC-01, RC-03 |
| CD-04 | `reserves` semantics | Modified: advisory-permitted booking; no-overlap rule extended | RC-02 makes booking possible over advisory maintenance when notified/acknowledged; RC-07 extends BR-14 to both booking paths under concurrency. Both are validity conditions on existing relationships, expressed via business rules (BR-45, BR-46, BR-50), not new structure. | RC-02, RC-07 |
| CD-05 | Approval lifecycle for instant booking | No schema change; automatic Approval record (ULD-01) | RC-06 (BR-49) adds an auto-approval path. Representing it as an automatic Approval record with decision = approved preserves the Phase 1 invariant that every approved booking has an approval record (BR-28) and requires no new entity, attribute, or FK change. The exact eligibility rule remains open (Q-01). | RC-06 |
| CD-06 | BR-32 / BR-33 refinement | Booking blocked only by active out_of_service maintenance for overlapping periods | The blanket "any active maintenance blocks booking" behavior (BR-33 Phase 1) is replaced by the impact-level-aware rule (BR-44). This is a rule change; the schema needs only the new `impact_level` attribute to support it. | RC-01, RC-02 |
| CD-07 | Impact-level changes (escalation/downgrade) | Lifecycle rule on the current attribute value | RC-04 (BR-47) permits level changes while the record is open. The requirements do not require retaining change history, so the schema stores only the current value (UERD-02); escalation/downgrade updates it. | RC-04 |
| CD-08 | Affected-bookings identification | Derived query, no schema change | RC-05 (BR-48) is a reporting-style query over already-stored Booking and Maintenance_Record data; per A-05 (08) reporting adds no new captured information. | RC-05 |
| CD-09 | Concurrency invariants | No schema change; deferred to concurrency stage | RC-07 (BR-50) and the conflict analysis (08 §7, CC-01..CC-05) are enforcement concerns of the concurrency implementation stage; the logical schema provides the necessary structures (Booking status, impact_level, advisory_acknowledgement) but no further modeling constructs. | RC-07 |

---

# Part D — Traceability Matrix

| Requirement Change | ERD Element | Relational Schema Element | Business Rules |
| ------------------ | ----------- | ------------------------- | -------------- |
| RC-01 | Maintenance Record attribute `impact_level`; `pertains_to` semantics; Space booking availability | `Maintenance_Record.impact_level` (new) | BR-32 (M), BR-33 (M), BR-42 (N), BR-44 (N) |
| RC-02 | Booking attribute `advisory_acknowledgement`; `reserves` semantics | `Booking.advisory_acknowledgement` (new) | BR-32 (M), BR-33 (M), BR-45 (N), BR-46 (N) |
| RC-03 | `pertains_to` semantics | none (rule only) | BR-19 (R), BR-43 (N) |
| RC-04 | Maintenance Record `impact_level` (mutable) | `Maintenance_Record.impact_level` | BR-47 (N) |
| RC-05 | — (derived) | none | BR-48 (N) |
| RC-06 | Booking lifecycle; Approval semantics (automatic decision) | `Approval` (behavior only, ULD-01) | BR-49 (N) |
| RC-07 | `reserves` validity; no-overlap invariant | none (concurrency stage) | BR-14 (M), BR-50 (N) |
| RC-08 | — (derived reports) | none | — |

Legend: N = new, M = modified, R = removed.

---

# Part E — Assumptions

## Conceptual (ERD) Assumptions

| ID | Assumption | Justification |
| -- | ---------- | ------------- |
| UERD-01 | No new entity or relationship is introduced; all requirement changes are realized through attributes and business rules. | 08 §3 and §5 explicitly identify no required new entities or relationships. |
| UERD-02 | The impact level of a maintenance record is represented by a single-valued current attribute; the history of escalation/downgrade changes (RC-04) is not stored. | The requirements (BR-47) require that the current level govern behavior; they do not require retaining level-change history. |
| UERD-03 | `advisory_acknowledgement` is modeled as a boolean attribute of Booking. | RC-02 and 08 Assumption A-03: the acknowledgement is part of the booking's own business information. |
| UERD-04 | "Affected approved bookings" (RC-05) and the new reports (RC-08) are derived queries over stored history; they introduce no new captured business information. | 08 Assumption A-05. |
| UERD-05 | Instant booking (RC-06) does not alter the ERD structure: it is a property of the booking/approval lifecycle. | 08 §3/§4 introduce no entity or attribute for instant booking; eligibility is a policy condition (Q-01). |
| UERD-06 | The two impact levels (advisory, out_of_service) are exhaustive. | 08 Assumption A-01. |

## Logical (Relational) Assumptions

| ID | Assumption | Justification |
| -- | ---------- | ------------- |
| ULD-01 | An instant booking (BR-49) is recorded as an automatic Approval record with decision = approved, attributed to a designated system user account. | Preserves the Phase 1 invariant BR-28 (every approved booking has an approval record) without schema structural change. The exact identity of the system account is pending Q-01/Q-07 resolution. |
| ULD-02 | `Booking.advisory_acknowledgement` is conditionally nullable: NULL when no advisory maintenance was active on the space at booking time; TRUE required when one or more advisories were active. | Consistent with LD-07 conditional-nullability practice; BR-45/BR-46 require the acknowledgement only when advisories exist. |
| ULD-03 | `Maintenance_Record.impact_level` defaults to advisory. | A reported issue is initially treated as advisory; escalation to out_of_service is a deliberate staff decision (BR-47). Inferred default, consistent with LD-06 practice. |
| ULD-04 | BR-50 and the conflict invariants (08 §7, CC-01..CC-05) are enforced by the concurrency implementation stage; the logical schema contributes only the supporting structures (impact_level, advisory_acknowledgement). | 08 §7 explicitly defers mechanisms; this stage produces only the design foundation. |
| ULD-05 | No candidate keys are added or removed; the two new attributes do not introduce keys. | Neither impact_level nor advisory_acknowledgement uniquely identifies occurrences. |
| ULD-06 | Phase 1 logical assumptions LD-01 .. LD-08 continue to hold for all unchanged elements. | Preserve traceability to the Phase 1 design. |

---

# Part F — Open Questions

| ID | Question | Reason | From |
| -- | -------- | ------ | ---- |
| Q-01 | Which space types are eligible for instant booking, and what exactly does "satisfy the usage policy" require? | Required to scope BR-49 behavior precisely; affects whether Space.space_type / Space.usage_policy need further constraints. | 08 |
| Q-02 | When a booking is created while advisories are active, how is the requester's acknowledgement confirmed? | RC-02 requires the acknowledgement be recorded but does not define how it is obtained. | 08 |
| Q-03 | Can the impact level be downgraded below advisory, or is advisory the minimum? | The requirements only give the advisory → out_of_service escalation example. | 08 |
| Q-04 | When maintenance is escalated to out_of_service and affected approved bookings are found, may those bookings be cancelled, or must staff only contact the requesters? | RC-05/BR-48 only require identifying affected bookings. | 08 |
| Q-05 | How soon after an advisory is active must a booking-time notification capture it ("at booking time" boundary)? | Relevant for BR-45 enforcement and concurrency conflict CC-04. | 08 |
| Q-06 | Is there a maximum number of simultaneous active maintenance records per space, or is it unlimited? | RC-03 removes the previous restriction without specifying an upper bound. | 08 |
| Q-07 | What is the identity of the system user account that records automatic approvals for instant bookings (ULD-01)? | The schema requires approver_id NOT NULL; the designated account must be decided at implementation. | ULD-01 |
| Q-08 | Must the history of impact-level changes (RC-04) be retained for auditing/reporting, or is the current level sufficient? | UERD-02 assumes no history is stored; a future requirement may reverse this. | UERD-02 |

---

## Summary

The Phase 1 conceptual and logical designs are preserved and extended incrementally:

* **Conceptual:** two new attributes (`impact_level` on Maintenance Record, `advisory_acknowledgement` on Booking); semantic updates to `reserves` and `pertains_to`; no entity or relationship added or removed; business rules BR-19 removed, BR-32/BR-33/BR-14 modified, BR-42 .. BR-50 added.
* **Logical:** `Maintenance_Record.impact_level` (NOT NULL, default advisory, enumeration) and `Booking.advisory_acknowledgement` (boolean, conditional) are the only schema changes; all 11 FKs, 3 candidate keys, and 8 relations unchanged; total attribute count 55 → 57.
* **Deferred:** instant-booking eligibility (Q-01), acknowledgement capture (Q-02), and all concurrency enforcement (BR-50, CC-01..CC-05) belong to the migration and concurrency stages.

This document is the foundation for `outputs/10-schema-migration-G7.sql` and the Phase 2 implementation artifacts.
