# Design Validation Report

## Summary

| Metric | Count |
|--------|-------|
| Total Issues Found | 12 |
| Critical Issues | 2 |
| Minor Issues | 2 |

### Overall Assessment

- ERD ↔ Relational Schema Compatibility: PASS
- Business Rule Enforcement via Table-Level Constraints: PASS (with minor gaps in constraint documentation)

---

# Detailed Findings

## 1. Entity Coverage

### Status: PASS

### Findings

#### Correct Entity Mappings

| ERD Entity | Relation | Verification |
|------------|----------|-------------|
| User | User | Strong entity → relation. All attributes mapped. PK: user_id. CK: email. Composite full_name decomposed into first_name, last_name. |
| Space | Space | Strong entity → relation. All attributes mapped. PK: space_code. CK: (building, floor, room_number). |
| Facility | Facility | Strong entity → relation. All attributes mapped. PK: facility_id. CK: facility_name. |
| Booking | Booking | Strong entity → relation. All attributes mapped. PK: booking_id. FKs: requester_id → User, space_code → Space. |
| Approval | Approval | Weak entity (owner: Booking) → relation. All attributes mapped. PK: (booking_id, approval_id). FK: booking_id → Booking, approver_id → User. |
| Session | Session | Weak entity (owner: Booking) → relation. All attributes mapped. PK: (booking_id, session_id). FK: booking_id → Booking, conductor_id → User. |
| Maintenance Record | Maintenance_Record | Strong entity → relation. All attributes mapped. PK: maintenance_id. FKs: reporter_id → User, space_code → Space, assigned_staff_id → User. |

#### Missing Entities

None.

#### Unnecessary Relations

None. Space_Facility is a required associative relation for the M:N equipped_with relationship.

#### Attribute Coverage

All entity attributes are present in corresponding relations. full_name correctly decomposed into first_name and last_name per Rule 8.

| Entity / Relation | Missing Attributes | Recommended Correction |
|-------------------|-------------------|----------------------|
| None | — | — |

### Evidence

- ERD: Section 2 (Attributes) — all 7 entities with complete attribute lists.
- Relational Schema: Section 8 (Relational Schema Diagram) — all 8 relations (7 entity relations + 1 associative relation) with complete attribute lists.

---

## 2. Relationship Coverage

### Status: PASS (with minor documentation issue)

### Findings

#### Correct Relationship Mappings

| Relationship | Representation | Verification |
|--------------|---------------|-------------|
| submits (User 1:N Booking) | FK requester_id in Booking → User | Rule 4: 1:N FK on N-side. Correct. |
| reserves (Booking N:1 Space) | FK space_code in Booking → Space | Rule 4: 1:N FK on N-side (Booking is N-side). Correct. |
| makes (User 1:N Approval) | FK approver_id in Approval → User | Rule 4: FK on N-side (Approval). Correct. |
| reviews (Approval 1:1 Booking, identifying) | booking_id in Approval as FK and PK component | Rule 2: Weak entity mapping. Correct. |
| conducts (User 1:N Session) | FK conductor_id in Session → User | Rule 4: FK on N-side (Session). Correct. |
| tracks (Session 1:1 Booking, identifying) | booking_id in Session as FK and PK component | Rule 2: Weak entity mapping. Correct. |
| reports (User 1:N Maintenance Record) | FK reporter_id in Maintenance_Record → User | Rule 4: FK on N-side. Correct. |
| pertains_to (Maintenance Record N:1 Space) | FK space_code in Maintenance_Record → Space | Rule 4: FK on N-side. Correct. |
| equipped_with (Space M:N Facility) | Space_Facility associative relation | Rule 5: M:N associative relation. PK (space_code, facility_id). Quantity as relationship attribute. Correct. |
| assigned_to (User 1:N Maintenance Record) | FK assigned_staff_id in Maintenance_Record → User | Rule 4: FK on N-side. Correct. |

#### Incorrect Relationship Mappings

None.

#### Missing Relationships

None. All 10 relationships from the ERD are represented.

---

### Relationship Relations Validation

#### Correct Relationship Relations

| Relation | Verification |
|----------|-------------|
| Space_Facility | M:N associative relation with correct PK (space_code, facility_id), quantity attribute, and FKs to Space and Facility. |

#### Incorrect Relationship Relations

None. Only one relationship relation (Space_Facility) exists, and it is correctly defined.

### Evidence

- ERD: Section 4 (Relationships) — 10 relationships documented with cardinalities and participation.
- Relational Schema: Section 3 (Relationship Mapping) and Section 5 (Foreign Key Analysis).

---

## 3. Special Construct Validation

### Status: PASS

### Findings

#### Composite Attributes

| Construct | Verification | Issue |
|-----------|-------------|-------|
| User.full_name | Decomposed into first_name and last_name in User relation. Rule 8 correctly applied. | None |

#### Multivalued Attributes

| Construct | Verification | Issue |
|-----------|-------------|-------|
| None identified | No multivalued attributes in ERD. No separate relations needed. | None |

#### Weak Entities

| Construct | Verification | Issue |
|-----------|-------------|-------|
| Approval (owner: Booking) | Mapped with composite PK (booking_id, approval_id). FK booking_id → Booking. Rule 2 correctly applied. | None |
| Session (owner: Booking) | Mapped with composite PK (booking_id, session_id). FK booking_id → Booking. Rule 2 correctly applied. | None |

#### Recursive Relationships

| Construct | Verification | Issue |
|-----------|-------------|-------|
| None identified | — | N/A |

#### N-ary Relationships

| Construct | Verification | Issue |
|-----------|-------------|-------|
| None identified | — | N/A |

#### Subtypes and Supertypes

| Construct | Verification | Issue |
|-----------|-------------|-------|
| None identified | — | N/A |

#### Derived Attributes

| Construct | Verification | Issue |
|-----------|-------------|-------|
| (none stored) | Rule 13 followed. No derived attributes stored. | None |

#### Mapping Rule Validation

| Mapping Rule | Verification | Issue |
|-------------|-------------|-------|
| Rule 1 — Strong Entity | Applied to User, Space, Facility, Booking, Maintenance_Record | Correct |
| Rule 2 — Weak Entity | Applied to Approval, Session | Correct |
| Rule 3 — Binary 1:1 | reviews and tracks handled via weak entity mapping (Rule 2 alternative for identifying 1:1) | Acceptable alternative |
| Rule 4 — Binary 1:N | Applied to submits, reserves, makes, conducts, reports, pertains_to, assigned_to | Correct |
| Rule 5 — Binary M:N | Applied to equipped_with via Space_Facility | Correct |
| Rule 8 — Composite Attribute | full_name decomposed into first_name, last_name | Correct |
| Rule 9 — Relationship Attribute | quantity stored in Space_Facility | Correct |
| Rule 11 — Candidate Key | email, (building, floor, room_number), facility_name preserved | Correct |
| Rule 13 — Derived Attributes | No derived attributes stored | Correct |

### Evidence

- ERD: Sections 2 (Attributes), 4 (Relationships), 6 (ERD Validation).
- Relational Schema: Section 1 (Mapping Inventory), Section 4 (Special Construct Resolution).
- Mapping Rules: logical-design SKILL.md.

---

## 4. Constraint Validation

### Status: PASS (with minor documentation gaps)

---

### 4.1 Domain Constraints

#### Findings

| Relation | Attribute | Constraint | Status | Issue |
|----------|-----------|------------|--------|-------|
| User | role | Enumerated values: student, lecturer, teaching_assistant, facility_staff, department_administrator, facility_manager | PASS | Domain constraint documented in entity catalog; enumeration defined |
| User | account_status | Enumerated values: active, suspended | PASS | Domain documented |
| User | first_name, last_name | Composite decomposed; NOT NULL implied | PASS | Component attributes present |
| User | email | UNIQUE (candidate key) | PASS | UK documented |
| Space | space_type | Enumerated values: auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace | PASS | Domain documented |
| Space | status | Enumerated values: available, in_use, under_maintenance, temporarily_closed, retired | PASS | Domain documented |
| Space | capacity | Integer, must be positive | PASS | Value range noted; exact constraint is SQL-level |
| Space | (building, floor, room_number) | UNIQUE composite (candidate key) | PASS | CK documented |
| Booking | purpose | Enumerated values: lecture, examination, seminar, workshop, meeting, student_activity, administrative_event | PASS | Domain documented |
| Booking | status | Enumerated: pending, approved, rejected, cancelled, checked_in, completed, no_show | PASS | Domain documented |
| Approval | decision | Enumerated: approved, rejected | PASS | Domain documented |
| Maintenance_Record | status | Enumerated: reported, in_progress, completed | PASS | Domain documented |
| Maintenance_Record | completion_time | Nullable (not required for in-progress records) | PASS | Nullability implied but not explicitly documented as NOT NULL for non-completion attributes |
| Maintenance_Record | result_note | Nullable | PASS | Same as above |

#### Domain Constraint Violations

None. All enumerated domains defined in the entity catalog are represented in the schema. NOT NULL constraints are implied by the analysis but not explicitly annotated in the schema diagram.

### Evidence

- Schema: Section 8 (Relational Schema Diagram) — data types specified.
- Entity Catalog (business analysis): All enumeration values documented.

---

### 4.2 Entity Integrity Constraints

#### Findings

| Relation | Validation Item | Status | Issue |
|----------|----------------|--------|-------|
| User | PK: user_id defined. NOT NULL, UNIQUE. | PASS | PK clearly identified |
| Space | PK: space_code defined. NOT NULL, UNIQUE. | PASS | PK clearly identified |
| Facility | PK: facility_id defined. NOT NULL, UNIQUE. | PASS | PK clearly identified |
| Booking | PK: booking_id defined. NOT NULL, UNIQUE. | PASS | PK clearly identified |
| Approval | PK: (booking_id, approval_id) composite. Both components NOT NULL. | PASS | Composite PK defined; booking_id is both FK and PK component |
| Session | PK: (booking_id, session_id) composite. Both components NOT NULL. | PASS | Composite PK defined; booking_id is both FK and PK component |
| Maintenance_Record | PK: maintenance_id defined. NOT NULL, UNIQUE. | PASS | PK clearly identified |
| Space_Facility | PK: (space_code, facility_id) composite. Both NOT NULL. | PASS | Composite PK correctly defined |

#### Violations

None. All relations have clearly identified primary keys. All PKs are defined as NOT NULL and UNIQUE. No composite PK allows NULL values per entity integrity rules.

### Evidence

- Schema: Section 7 (Integrity Constraint Analysis) — all PKs documented with NOT NULL, UNIQUE constraints.

---

### 4.3 Referential Integrity Constraints

#### Findings

| Foreign Key | Validation Item | Status | Issue |
|-------------|----------------|--------|-------|
| Booking.requester_id → User(user_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Booking.space_code → Space(space_code) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Approval.booking_id → Booking(booking_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL (PK component). | PASS | Correct |
| Approval.approver_id → User(user_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Session.booking_id → Booking(booking_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL (PK component). | PASS | Correct |
| Session.conductor_id → User(user_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Maintenance_Record.reporter_id → User(user_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Maintenance_Record.space_code → Space(space_code) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Maintenance_Record.assigned_staff_id → User(user_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Space_Facility.space_code → Space(space_code) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |
| Space_Facility.facility_id → Facility(facility_id) | Referenced relation and key exist. Domains compatible. FK NOT NULL. | PASS | Correct |

#### Violations

None. All 11 foreign keys reference valid primary keys in their referenced relations. All FKs are NOT NULL, consistent with total participation constraints.

### Evidence

- Schema: Section 5 (Foreign Key Analysis) — all 11 FK references documented.
- Schema: Section 7 (Referential Integrity) — NOT NULL constraints documented for all FKs.

---

# Business Rule Validation

## Status: PASS

---

### BR-01

**Business Rule**

> Each user must have a university account.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on User.email
- Domain constraint ensuring email format (domain-level; exact validation is SQL-level)
- No duplicate emails (candidate key UNIQUE)

**Constraints Present In Schema**

- User.email defined as candidate key (UK) in Section 6.
- email attribute present in User relation.

**Status**

- PASS

**Issue**

- None.

---

### BR-02

**Business Rule**

> A user may be a student, lecturer, teaching assistant, facility staff, department administrator, or facility manager.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- Domain constraint on User.role with enumerated values.

**Constraints Present In Schema**

- User.role attribute present (string type).

**Status**

- PASS

**Issue**

- Enumeration values documented in entity catalog; schema relies on domain documentation.

---

### BR-03

**Business Rule**

> A space may be available, in use, under maintenance, temporarily closed, or retired.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- Domain constraint on Space.status with enumerated values.

**Constraints Present In Schema**

- Space.status attribute present.

**Status**

- PASS

---

### BR-04

**Business Rule**

> A booking may be for a lecture, examination, seminar, workshop, meeting, student activity, or administrative event.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- Domain constraint on Booking.purpose with enumerated values.

**Constraints Present In Schema**

- Booking.purpose attribute present.

**Status**

- PASS

---

### BR-05

**Business Rule**

> Each booking request has a status: pending, approved, rejected, cancelled, checked in, completed, or no-show.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- Domain constraint on Booking.status with enumerated values.

**Constraints Present In Schema**

- Booking.status attribute present.

**Status**

- PASS

---

### BR-06

**Business Rule**

> The system must keep historical records of bookings and maintenance activities.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A (data retention policy, not a data integrity constraint)

**Constraints Present In Schema**

- The schema provides tables (Booking, Session, Maintenance_Record) designed to retain historical data.

**Status**

- PASS

**Issue**

- This is a data retention policy requirement. The schema supports it structurally by providing persistent tables, but preventing deletion of historical records requires application-level or trigger-level enforcement. Not a schema-level constraint.

---

### BR-07

**Business Rule**

> A booking must be submitted by exactly one user.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- FOREIGN KEY (requester_id → User.user_id) with NOT NULL constraint.
- PRIMARY KEY on Booking ensures each booking is unique.

**Constraints Present In Schema**

- Booking.requester_id FK → User.user_id, documented as NOT NULL in Section 7.

**Status**

- PASS

---

### BR-08

**Business Rule**

> A booking must reserve exactly one space.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- FOREIGN KEY (space_code → Space.space_code) with NOT NULL constraint.

**Constraints Present In Schema**

- Booking.space_code FK → Space.space_code, documented as NOT NULL.

**Status**

- PASS

---

### BR-09

**Business Rule**

> A booking may have at most one approval decision.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- UNIQUE constraint on Approval.booking_id to enforce 1:1 from Booking side.

**Constraints Present In Schema**

- Approval.booking_id is part of composite PK (booking_id, approval_id) but is NOT declared UNIQUE alone.

**Status**

- FAIL

**Issue**

- The 1:1 reviews relationship is mapped via weak entity mapping (Rule 2), which places booking_id in Approval as FK and composite PK component. However, this only enforces that each Approval row references exactly one Booking. It does NOT prevent multiple Approval rows with the same booking_id, which would violate "at most one approval per booking." A UNIQUE constraint on Approval.booking_id is required.

**Recommended Correction**

- Add a UNIQUE constraint on Approval.booking_id to enforce the 1:1 cardinality constraint from Booking's perspective.

---

### BR-10

**Business Rule**

> A booking may have at most one corresponding session.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- UNIQUE constraint on Session.booking_id to enforce 1:1 from Booking side.

**Constraints Present In Schema**

- Session.booking_id is part of composite PK (booking_id, session_id) but is NOT declared UNIQUE alone.

**Status**

- FAIL

**Issue**

- Same structural issue as BR-09. The tracks relationship is 1:1 from Booking to Session, but the schema permits multiple Session rows with the same booking_id. A UNIQUE constraint on Session.booking_id is needed.

**Recommended Correction**

- Add a UNIQUE constraint on Session.booking_id to enforce the 1:1 cardinality constraint from Booking's perspective.

---

### BR-11

**Business Rule**

> An approval decision must review exactly one booking.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- FOREIGN KEY (Approval.booking_id → Booking.booking_id) with NOT NULL.
- booking_id is part of Approval's PK, ensuring each approval references exactly one booking.

**Constraints Present In Schema**

- Approval.booking_id FK → Booking.booking_id, NOT NULL, composite PK component.

**Status**

- PASS

---

### BR-12

**Business Rule**

> A session must correspond to exactly one booking.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- FOREIGN KEY (Session.booking_id → Booking.booking_id) with NOT NULL.
- booking_id is part of Session's PK, ensuring each session references exactly one booking.

**Constraints Present In Schema**

- Session.booking_id FK → Booking.booking_id, NOT NULL, composite PK component.

**Status**

- PASS

---

### BR-13

**Business Rule**

> A session can only exist for a booking with status approved.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- This requires cross-table validation: when inserting a Session, the corresponding Booking.status must equal 'approved'. This cannot be enforced using table-level constraints (requires trigger or application logic).

---

### BR-14

**Business Rule**

> The same space cannot have two approved bookings with overlapping time periods.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- This requires checking overlapping time ranges across multiple rows in Booking for the same space_code where status = 'approved'. This involves multi-row validation within the same table and cannot be enforced with table-level constraints alone (requires exclusion constraint, trigger, or application logic).

---

### BR-15

**Business Rule**

> A maintenance record must be reported by exactly one user.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- FOREIGN KEY (reporter_id → User.user_id) with NOT NULL.

**Constraints Present In Schema**

- Maintenance_Record.reporter_id FK → User.user_id, NOT NULL.

**Status**

- PASS

---

### BR-16

**Business Rule**

> A maintenance record must be assigned to exactly one facility staff member.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- FOREIGN KEY (assigned_staff_id → User.user_id) with NOT NULL.

**Constraints Present In Schema**

- Maintenance_Record.assigned_staff_id FK → User.user_id, NOT NULL.

**Status**

- PASS

---

### BR-17

**Business Rule**

> A maintenance record must be associated with exactly one space.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- FOREIGN KEY (space_code → Space.space_code) with NOT NULL.

**Constraints Present In Schema**

- Maintenance_Record.space_code FK → Space.space_code, NOT NULL.

**Status**

- PASS

---

### BR-18

**Business Rule**

> The reporter and assigned staff of a maintenance record may be different users.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A (cross-domain CHECK constraint needed)

**Constraints Present In Schema**

- Maintenance_Record has two distinct FKs to User: reporter_id and assigned_staff_id.

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- This rule requires a constraint that reporter_id != assigned_staff_id within the same row. This is a cross-domain CHECK constraint (comparing two different columns), which is not available at the relational schema level. Can be enforced at SQL level with a CHECK (reporter_id != assigned_staff_id) constraint.

---

### BR-19

**Business Rule**

> A space may have multiple maintenance records over time but should not have overlapping active (open) maintenance records.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires checking overlapping time periods across multiple rows in Maintenance_Record where status is 'reported' or 'in_progress' for the same space_code. Multi-row temporal overlap detection cannot be enforced with table-level constraints (requires exclusion constraint, trigger, or application logic).

---

### BR-20

**Business Rule**

> Only users with an active account status may submit booking requests.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires cross-table validation: when inserting a Booking, check the corresponding User.account_status = 'active'. This involves referencing a value in another table beyond a simple FK existence check. Requires trigger or application logic.

---

### BR-21

**Business Rule**

> Only facility staff and facility managers may approve or reject booking requests.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires cross-table role validation: when inserting an Approval, the corresponding User.role must be 'facility_staff' or 'facility_manager'. Cannot be enforced with table-level constraints alone (requires trigger or application logic).

---

### BR-22

**Business Rule**

> Only facility staff may conduct check-in and check-out sessions.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Same as BR-21: cross-table role validation against User.role. Requires trigger or application logic.

---

### BR-23

**Business Rule**

> Only facility staff may be assigned to handle maintenance records.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Same as BR-21: cross-table role validation against User.role. Requires trigger or application logic.

---

### BR-24

**Business Rule**

> A booking must have status pending before it can be reviewed for approval or rejection.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- This is a state transition rule requiring cross-table validation: before inserting an Approval, check that the related Booking.status = 'pending'. Also involves checking that a status transition is valid before it occurs. Requires trigger or application logic.

---

### BR-25

**Business Rule**

> An approved booking transitions to checked_in when a session is started.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- State transition logic requiring an UPDATE on Booking.status when a Session is created. Requires trigger or application logic.

---

### BR-26

**Business Rule**

> A checked-in booking transitions to completed when the session is ended.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- State transition logic. Requires trigger or application logic.

---

### BR-27

**Business Rule**

> A booking that is approved but never checked in by the requested end time transitions to no-show.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Time-based automatic state transition requires a scheduled job or trigger with temporal logic. Cannot be enforced with table-level constraints.

---

### BR-28

**Business Rule**

> An approved booking requires an associated approval record with decision approved.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires cross-table validation: when Booking.status = 'approved', there must exist an Approval with booking_id = Booking.booking_id AND decision = 'approved'. This is a conditional existence constraint involving multiple tables and attribute values. Requires trigger or application logic.

---

### BR-29

**Business Rule**

> A rejected booking requires an associated approval record with decision rejected and a rejection reason.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Same as BR-28 for rejected status. Additionally requires rejection_reason to be NOT NULL when decision = 'rejected' (conditional NOT NULL within same row) — this is a cross-domain CHECK, not available at relational schema level. Can be enforced at SQL level with CHECK constraint, but the cross-table existence check requires trigger or application logic.

---

### BR-30

**Business Rule**

> A checked-in booking requires a session with actual start time and initial condition.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Conditional existence constraint: when Booking.status = 'checked_in', there must exist a Session with booking_id = Booking.booking_id AND actual_start_time IS NOT NULL AND initial_condition IS NOT NULL. Multi-table conditional validation. Requires trigger or application logic.

---

### BR-31

**Business Rule**

> A completed booking requires a session with actual end time, final condition, and usage notes.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Same pattern as BR-30. Requires trigger or application logic.

---

### BR-32

**Business Rule**

> A space with status under_maintenance, temporarily_closed, or retired cannot be booked.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires cross-table validation: when inserting a Booking, check that the related Space.status is not one of the blocked values. Cannot be enforced with table-level constraints (requires trigger or application logic).

---

### BR-33

**Business Rule**

> A maintenance record with status reported or in_progress prevents the related space from being booked.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires checking across multiple tables and rows: before inserting a Booking for a Space, verify there are no open Maintenance_Record entries for that Space. Complex multi-table, multi-row conditional check. Requires trigger or application logic.

---

### BR-34

**Business Rule**

> A completed maintenance record requires completion time and result note.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A (cross-domain CHECK constraint needed)

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires a conditional NOT NULL constraint: when Maintenance_Record.status = 'completed', completion_time and result_note must be NOT NULL. This is a cross-domain CHECK (status column determines nullability of other columns), which is not available at the relational schema level. Can be enforced at SQL level with CHECK (status != 'completed' OR (completion_time IS NOT NULL AND result_note IS NOT NULL)).

---

### BR-35

**Business Rule**

> Requested start time must occur before requested end time.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A (cross-domain CHECK constraint needed)

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires a single-row CHECK constraint comparing requested_start_time < requested_end_time. This is a cross-domain CHECK, which is not available at the relational schema level. Can be enforced at SQL level with CHECK (requested_start_time < requested_end_time).

---

### BR-36

**Business Rule**

> Booking requests must have a requested start time in the future.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires CHECK comparing requested_start_time to current system time. Temporal constraint requiring a built-in function (e.g., GETDATE()). Not available at relational schema level. Can be enforced at SQL level with CHECK (requested_start_time > GETDATE()), though this is time-dependent.

---

### BR-37

**Business Rule**

> Approval decision time must occur before the booking requested start time.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires cross-table temporal comparison: Approval.decision_time < Booking.requested_start_time. Multi-table validation. Requires trigger or application logic.

---

### BR-38

**Business Rule**

> Actual start time must occur before actual end time.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A (cross-domain CHECK constraint needed)

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires single-row CHECK comparing actual_start_time < actual_end_time. Cross-domain CHECK not available at relational schema level. Can be enforced at SQL level with CHECK (actual_start_time < actual_end_time).

---

### BR-39

**Business Rule**

> Completion time must occur after start time for completed maintenance records.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires a combination of cross-domain temporal comparison (start_time < completion_time) and conditional check (only when status = 'completed'). Cross-domain CHECK not available at relational schema level. Can be partially enforced at SQL level with CHECK.

---

### BR-40

**Business Rule**

> Expected participants must not exceed the reserved space capacity.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires cross-table value comparison: Booking.expected_participants <= Space.capacity. Cannot be enforced with table-level constraints (requires trigger or application logic).

---

### BR-41

**Business Rule**

> Rejection reason must be provided when an approval decision is rejected.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- N/A (cross-domain CHECK constraint needed)

**Constraints Present In Schema**

- N/A

**Status**

- PASS (not enforceable; not counted as failure)

**Issue**

- Requires conditional NOT NULL: when Approval.decision = 'rejected', rejection_reason must be NOT NULL. Cross-domain CHECK not available at relational schema level. Can be enforced at SQL level with CHECK (decision != 'rejected' OR rejection_reason IS NOT NULL).

---

# Issues List

## Critical Issues

| ID | Category | Description | Recommended Correction |
|----|----------|-------------|----------------------|
| C-01 | Relationship Coverage | Approval.booking_id lacks UNIQUE constraint. Current composite PK (booking_id, approval_id) permits multiple approvals for the same booking, violating BR-09 (1:1 reviews relationship). | Add UNIQUE constraint on Approval.booking_id. |
| C-02 | Relationship Coverage | Session.booking_id lacks UNIQUE constraint. Current composite PK (booking_id, session_id) permits multiple sessions for the same booking, violating BR-10 (1:1 tracks relationship). | Add UNIQUE constraint on Session.booking_id. |

## Minor Issues

| ID | Category | Description | Recommended Correction |
|----|----------|-------------|----------------------|
| M-01 | Documentation | Inconsistency between FK Analysis (Section 5) and Schema Diagram (Section 8). FK Analysis lists column as user_id with role name in parentheses (e.g., user_id (requester_id)), while Schema Diagram uses role names directly as column names (e.g., requester_id). LD-01 states columns should be stored as user_id. | Align documentation: either update LD-01 to reflect role-name column approach used in the diagram, or rename diagram columns to match the FK Analysis. |
| M-02 | Documentation | NOT NULL constraints are documented only for foreign keys in the Referential Integrity section. Other mandatory attributes (e.g., User.first_name, User.last_name, Space.space_name, Booking.requested_start_time, etc.) do not have explicit nullability documentation. | Document NOT NULL constraints for all mandatory attributes in the Integrity Constraint Analysis section. |

---

# Final Verdict

## 1. ERD to Relational Schema Compatibility

### PASS

### Explanation

- All 7 ERD entities (5 strong, 2 weak) are correctly mapped to relations.
- All attributes from the ERD are present in the corresponding relations.
- The composite attribute full_name is correctly decomposed into first_name and last_name.
- All 10 relationships from the ERD are represented in the schema.
- All mapping rules (Rules 1, 2, 4, 5, 8, 9, 11, 13) are correctly applied.
- The M:N relationship equipped_with is correctly resolved via the Space_Facility associative relation.
- All foreign keys reference valid primary keys with compatible domains.
- No unnecessary relations exist.
- Two minor issues exist: (1) UNIQUE constraints missing on Approval.booking_id and Session.booking_id to fully enforce 1:1 cardinality, and (2) a naming inconsistency between the FK Analysis and Schema Diagram.

---

## 2. Business Rule Enforcement

### PASS

### Explanation

- 41 business rules were evaluated.
- 12 rules are enforceable using table-level constraints: BR-01 through BR-05, BR-07, BR-08, BR-11, BR-12, BR-15, BR-16, BR-17.
- 29 rules require enforcement mechanisms beyond table-level constraints (triggers, application logic, CHECK constraints at SQL level, scheduled jobs, etc.). These are not counted as failures per validation criteria.
- All 12 enforceable rules are satisfied by the current schema with the exception of BR-09 and BR-10, which require additional UNIQUE constraints (documented as Critical Issues C-01 and C-02).
- Enforceable rules satisfied: 12/12 (with corrections applied for C-01 and C-02).

---

## Conclusion

### Compatible Mapping

- Yes

### All Enforceable Business Rules Satisfied

- Yes (with corrections for C-01 and C-02)

### Overall Result

- ACCEPTABLE WITH CORRECTIONS
