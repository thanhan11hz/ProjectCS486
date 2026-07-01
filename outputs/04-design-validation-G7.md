# Design Validation Report

## Summary

| Metric | Count |
|----------|----------|
| Total Issues Found | 2 |
| Critical Issues | 0 |
| Minor Issues | 2 |

### Overall Assessment

- ERD ↔ Relational Schema Compatibility: PASS
- Business Rule Enforcement via Logical-Schema-Level Constraints: PASS

---

# Detailed Findings

## 1. Entity Coverage

### Status: PASS

### Findings

#### Correct Entity Mappings

| ERD Entity | Relation | Verification |
|------------|------------|------------|
| User | User | Correct — strong entity mapped per Rule 1; PK = user_id; candidate key email preserved |
| Space | Space | Correct — strong entity mapped per Rule 1; PK = space_code; candidate key (building, floor, room_number) preserved |
| Facility | Facility | Correct — strong entity mapped per Rule 1; PK = facility_id; candidate key facility_name preserved |
| Booking | Booking | Correct — strong entity mapped per Rule 1; PK = booking_id |
| Approval | Approval | Correct — strong entity mapped per Rule 1; PK = approval_id |
| Session | Session | Correct — strong entity mapped per Rule 1; PK = session_id |
| Maintenance Record | Maintenance_Record | Correct — strong entity mapped per Rule 1; PK = maintenance_id |

#### Missing Entities

| ERD Entity | Issue | Recommended Correction |
|------------|------------|------------|
| None | — | — |

#### Unnecessary Relations

| Relation | Reason | Recommended Correction |
|------------|------------|------------|
| None | — | — |

#### Attribute Coverage

| Entity / Relation | Missing Attributes | Recommended Correction |
|------------|------------|------------|
| None | — | — |

### Evidence

- ERD:
  - 7 strong entities defined: User, Space, Facility, Booking, Approval, Session, Maintenance Record
  - All entities have unique identifiers (user_id, space_code, facility_id, booking_id, approval_id, session_id, maintenance_id)
  - Full_name decomposed into first_name and last_name as composite attribute
- Relational Schema:
  - 7 base relations: User, Space, Facility, Booking, Approval, Session, Maintenance_Record
  - 1 associative relation: Space_Facility (from M:N equipped_with relationship)
  - All ERD entities mapped to a corresponding relation
  - All attributes preserved; full_name correctly decomposed into first_name and last_name
  - All primary keys correctly identified
  - All candidate keys preserved: User.email, Space.(building, floor, room_number), Facility.facility_name

---

## 2. Relationship Coverage

### Status: PASS

### Findings

#### Correct Relationship Mappings

| Relationship | Representation | Verification |
|------------|------------|------------|
| submits (User → Booking) 1:N | FK requester_id in Booking → User(user_id) | Correct — Rule 4, PK of 1-side (User) in N-side (Booking) |
| reserves (Booking → Space) N:1 | FK space_code in Booking → Space(space_code) | Correct — Rule 4, PK of 1-side (Space) in N-side (Booking) |
| makes (User → Approval) 1:N | FK approver_id in Approval → User(user_id) | Correct — Rule 4 |
| reviews (Approval ↔ Booking) 1:1 | FK booking_id (UNIQUE) in Approval → Booking(booking_id) | Correct — Rule 3, FK in total participation side (Approval) |
| conducts (User → Session) 1:N | FK conductor_id in Session → User(user_id) | Correct — Rule 4 |
| tracks (Session ↔ Booking) 1:1 | FK booking_id (UNIQUE) in Session → Booking(booking_id) | Correct — Rule 3, FK in total participation side (Session) |
| reports (User → Maintenance Record) 1:N | FK reporter_id in Maintenance_Record → User(user_id) | Correct — Rule 4 |
| pertains_to (Maintenance Record → Space) N:1 | FK space_code in Maintenance_Record → Space(space_code) | Correct — Rule 4 |
| equipped_with (Space ↔ Facility) M:N | Space_Facility associative relation with FKs to Space and Facility, quantity attribute | Correct — Rule 5 |
| assigned_to (User → Maintenance Record) 1:N | FK assigned_staff_id in Maintenance_Record → User(user_id) | Correct — Rule 4 |

#### Incorrect Relationship Mappings

| Relationship | Issue | Recommended Correction |
|------------|------------|------------|
| None | — | — |

#### Missing Relationships

| Relationship | Issue | Recommended Correction |
|------------|------------|------------|
| None | — | — |

---

### Relationship Relations Validation

#### Correct Relationship Relations

| Relation | Verification |
|------------|------------|
| Space_Facility | Correct — associative relation for M:N equipped_with; PK = (space_code, facility_id); quantity attribute preserved |

#### Incorrect Relationship Relations

| Relation | Issue | Recommended Correction |
|------------|------------|------------|
| None | — | — |

### Evidence

- ERD:
  - 10 binary relationships documented with cardinalities and participation constraints
  - reviews (1:1), tracks (1:1), submits (1:N), reserves (N:1), makes (1:N), conducts (1:N), reports (1:N), pertains_to (N:1), equipped_with (M:N), assigned_to (1:N)
  - quantity is the only relationship attribute (on equipped_with)
- Relational Schema:
  - All 10 relationships represented via FK references or associative relation
  - 1:1 relationships use FK + UNIQUE constraint (Rule 3 preferred approach — FK in total participation side)
  - 1:N relationships use FK in N-side relation (Rule 4)
  - M:N relationship resolved via Space_Facility associative relation (Rule 5)
  - No relationship is unrepresented

---

## 3. Special Construct Validation

### Status: PASS

### Findings

#### Composite Attributes

| Construct | Verification | Issue |
|------------|------------|------------|
| User.full_name (first_name, last_name) | Correct — decomposed into first_name and last_name per Rule 8. Composite attribute not retained. | None |

#### Multivalued Attributes

| Construct | Verification | Issue |
|------------|------------|------------|
| None identified | Correct — no multivalued attributes present. Facilities per space modeled as M:N relationship. | None |

#### Weak Entities

| Construct | Verification | Issue |
|------------|------------|------------|
| None identified | Correct — all entities classified as strong. | None |

#### N-ary Relationships

| Construct | Verification | Issue |
|------------|------------|------------|
| None identified | Correct — all relationships are binary. | None |

#### Recursive Relationships

| Construct | Verification | Issue |
|------------|------------|------------|
| None identified | Correct — no recursive relationships exist in the model. | None |

#### Derived Attributes

| Construct | Verification | Issue |
|------------|------------|------------|
| None stored | Correct — per Rule 13, no derived attributes are stored. All required summary information is computable. | None |

#### Mapping Rule Validation

| Mapping Rule | Verification | Issue |
|------------|------------|------------|
| Rule 1 — Strong Entity Mapping | Correct — applied to all 7 entities | None |
| Rule 3 — Binary 1:1 Mapping | Correct — reviews (FK + UNIQUE in Approval), tracks (FK + UNIQUE in Session) | None |
| Rule 4 — Binary 1:N Mapping | Correct — applied to all 7 1:N relationships | None |
| Rule 5 — Binary M:N Mapping | Correct — Space_Facility associative relation created | None |
| Rule 8 — Composite Attribute Mapping | Correct — full_name decomposed | None |
| Rule 9 — Relationship Attribute Mapping | Correct — quantity stored in Space_Facility | None |
| Rule 11 — Candidate Key Preservation | Correct — 3 candidate keys preserved | None |
| Rule 12 — Foreign Key Representation | Correct — all 11 FK references documented | None |
| Rule 13 — Derived Attributes | Correct — no derived attributes stored | None |

### Evidence

- ERD:
  - full_name classified as composite with first_name, last_name subattributes
  - No weak entities, multivalued attributes, recursive relationships, or n-ary relationships
  - quantity is the only relationship attribute
- Relational Schema:
  - full_name correctly decomposed into first_name and last_name (LD-02)
  - No separate relation needed for multivalued attributes (none exist)
  - No weak entity mapping needed
  - No associative relation for recursive relationships
  - quantity preserved in Space_Facility associative relation
- Mapping Rules:
  - All applicable mapping rules correctly applied
  - No mapping rule misapplied or omitted

---

## 4. Constraint Validation

### Status: PASS

---

## 4.1 Domain Constraints

### Findings

| Relation | Attribute | Constraint Type | Expected Constraint | Status | Issue |
|------------|------------|------------|------------|------------|------------|
| User | user_id | NOT NULL, UNIQUE | Primary key — must be unique and not null | PASS | — |
| User | first_name | NOT NULL | Mandatory name component | PASS | — |
| User | last_name | NOT NULL | Mandatory name component | PASS | — |
| User | email | NOT NULL, UNIQUE | University email must be unique | PASS | — |
| User | phone_number | NULL allowed | Contact information is optional | PASS | Minor: Optionality not explicitly documented |
| User | role | NOT NULL, CHECK | Enumerated: student, lecturer, teaching_assistant, facility_staff, department_administrator, facility_manager | PASS | — |
| User | department | NOT NULL | Organizational affiliation is required | PASS | — |
| User | account_status | NOT NULL, CHECK | Enumerated: active, suspended | PASS | — |
| Space | space_code | NOT NULL, UNIQUE | Primary key | PASS | — |
| Space | space_name | NOT NULL | Space must have a name | PASS | — |
| Space | space_type | NOT NULL, CHECK | Enumerated: auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace | PASS | — |
| Space | building | NOT NULL | Physical location required | PASS | — |
| Space | floor | NOT NULL | Physical location required | PASS | — |
| Space | room_number | NOT NULL | Physical location required | PASS | — |
| Space | capacity | NOT NULL, CHECK > 0 | Maximum occupancy must be positive | PASS | — |
| Space | status | NOT NULL, CHECK | Enumerated: available, in_use, under_maintenance, temporarily_closed, retired | PASS | — |
| Space | usage_policy | NULL allowed | Text description, may be absent | PASS | — |
| Facility | facility_id | NOT NULL, UNIQUE | Primary key | PASS | — |
| Facility | facility_name | NOT NULL, UNIQUE | Facility names are unique descriptors | PASS | — |
| Facility | description | NULL allowed | Optional details | PASS | — |
| Booking | booking_id | NOT NULL, UNIQUE | Primary key | PASS | — |
| Booking | requester_id | NOT NULL | FK to User — total participation | PASS | — |
| Booking | space_code | NOT NULL | FK to Space — total participation | PASS | — |
| Booking | requested_start_time | NOT NULL | Required for all bookings | PASS | — |
| Booking | requested_end_time | NOT NULL | Required for all bookings | PASS | — |
| Booking | purpose | NOT NULL, CHECK | Enumerated values | PASS | — |
| Booking | expected_participants | NOT NULL, CHECK > 0 | Must be positive | PASS | — |
| Booking | status | NOT NULL, CHECK | Enumerated booking lifecycle states | PASS | — |
| Approval | approval_id | NOT NULL, UNIQUE | Primary key | PASS | — |
| Approval | booking_id | NOT NULL, UNIQUE | FK to Booking — 1:1 enforcement | PASS | — |
| Approval | approver_id | NOT NULL | FK to User — total participation | PASS | — |
| Approval | decision | NOT NULL, CHECK | Enumerated: approved, rejected | PASS | — |
| Approval | decision_time | NOT NULL | Required for all decisions | PASS | — |
| Approval | decision_note | NULL allowed | Optional note | PASS | — |
| Approval | rejection_reason | NULL allowed | Conditional — required only when rejected | PASS | Minor: Conditional requirement not enforceable at schema level |
| Session | session_id | NOT NULL, UNIQUE | Primary key | PASS | — |
| Session | booking_id | NOT NULL, UNIQUE | FK to Booking — 1:1 enforcement | PASS | — |
| Session | conductor_id | NOT NULL | FK to User — total participation | PASS | — |
| Session | actual_start_time | NOT NULL | Required when session is created (BR-30) | PASS | — |
| Session | actual_end_time | NULL allowed | Populated on completion (BR-31) | PASS | — |
| Session | initial_condition | NOT NULL | Required at check-in (BR-30) | PASS | — |
| Session | final_condition | NULL allowed | Populated on completion (BR-31) | PASS | — |
| Session | usage_notes | NULL allowed | Optional notes | PASS | — |
| Maintenance_Record | maintenance_id | NOT NULL, UNIQUE | Primary key | PASS | — |
| Maintenance_Record | reporter_id | NOT NULL | FK to User | PASS | — |
| Maintenance_Record | space_code | NOT NULL | FK to Space | PASS | — |
| Maintenance_Record | assigned_staff_id | NOT NULL | FK to User | PASS | — |
| Maintenance_Record | problem_description | NOT NULL | Required | PASS | — |
| Maintenance_Record | start_time | NOT NULL | Required | PASS | — |
| Maintenance_Record | completion_time | NULL allowed | Populated on completion (BR-34) | PASS | — |
| Maintenance_Record | status | NOT NULL, CHECK | Enumerated: reported, in_progress, completed | PASS | — |
| Maintenance_Record | result_note | NULL allowed | Populated on completion (BR-34) | PASS | — |
| Space_Facility | space_code | NOT NULL | PK component, FK | PASS | — |
| Space_Facility | facility_id | NOT NULL | PK component, FK | PASS | — |
| Space_Facility | quantity | NOT NULL, CHECK > 0 | Quantity must be positive | PASS | — |

### Domain Constraint Violations

| Relation | Attribute | Violation | Recommended Correction |
|------------|------------|------------|------------|
| None | — | — | — |

### Evidence

- Schema:
  - All primary key attributes are NOT NULL
  - All foreign key attributes on the total participation side are NOT NULL
  - Candidate key attributes marked as UNIQUE
  - Conditional attributes (rejection_reason, actual_end_time, final_condition, completion_time, result_note) correctly allow NULL
  - Enumerated attributes identified with CHECK constraints

---

## 4.2 Key Constraints

### Findings

| Relation | Key Type | Attributes | Validation Item | Status | Issue |
|------------|------------|------------|------------|------------|------------|
| User | Primary Key | user_id | PK is correctly identified | PASS | — |
| User | Candidate Key | email | email is a natural business key | PASS | — |
| Space | Primary Key | space_code | PK is correctly identified | PASS | — |
| Space | Candidate Key | (building, floor, room_number) | Physical location is a natural business key | PASS | — |
| Facility | Primary Key | facility_id | PK is correctly identified | PASS | — |
| Facility | Candidate Key | facility_name | Facility names are unique identifiers | PASS | — |
| Booking | Primary Key | booking_id | PK is correctly identified | PASS | — |
| Approval | Primary Key | approval_id | PK is correctly identified | PASS | — |
| Approval | UNIQUE | booking_id | UNIQUE enforces 1:1 reviews relationship | PASS | — |
| Session | Primary Key | session_id | PK is correctly identified | PASS | — |
| Session | UNIQUE | booking_id | UNIQUE enforces 1:1 tracks relationship | PASS | — |
| Maintenance_Record | Primary Key | maintenance_id | PK is correctly identified | PASS | — |
| Space_Facility | Primary Key | (space_code, facility_id) | Composite PK prevents duplicate entries | PASS | — |

### Key Constraint Violations

| Relation | Violation | Recommended Correction |
|------------|------------|------------|
| None | — | — |

### Evidence

- Schema:
  - All relations have clearly defined primary keys
  - 3 business-defined candidate keys preserved: User.email, Space.(building, floor, room_number), Facility.facility_name
  - UNIQUE constraints on booking_id in Approval and Session correctly enforce 1:1 cardinality
  - No non-key attributes incorrectly defined as keys
  - Composite key of Space_Facility contains the correct set of attributes

---

## 4.3 Entity Integrity Constraints

### Findings

| Relation | Validation Item | Status | Issue |
|------------|------------|------------|------------|
| User | Primary key attributes are NOT NULL | PASS | — |
| User | Primary key attributes are UNIQUE | PASS | — |
| User | Primary key is clearly identified | PASS | — |
| Space | Primary key attributes are NOT NULL | PASS | — |
| Space | Primary key attributes are UNIQUE | PASS | — |
| Space | Primary key is clearly identified | PASS | — |
| Facility | Primary key attributes are NOT NULL | PASS | — |
| Facility | Primary key attributes are UNIQUE | PASS | — |
| Facility | Primary key is clearly identified | PASS | — |
| Booking | Primary key attributes are NOT NULL | PASS | — |
| Booking | Primary key attributes are UNIQUE | PASS | — |
| Booking | Primary key is clearly identified | PASS | — |
| Approval | Primary key attributes are NOT NULL | PASS | — |
| Approval | Primary key attributes are UNIQUE | PASS | — |
| Approval | Primary key is clearly identified | PASS | — |
| Session | Primary key attributes are NOT NULL | PASS | — |
| Session | Primary key attributes are UNIQUE | PASS | — |
| Session | Primary key is clearly identified | PASS | — |
| Maintenance_Record | Primary key attributes are NOT NULL | PASS | — |
| Maintenance_Record | Primary key attributes are UNIQUE | PASS | — |
| Maintenance_Record | Primary key is clearly identified | PASS | — |
| Space_Facility | All composite PK components are NOT NULL | PASS | — |
| Space_Facility | Composite PK is UNIQUE | PASS | — |
| Space_Facility | Primary key is clearly identified | PASS | — |

### Entity Integrity Violations

| Relation | Violation | Recommended Correction |
|------------|------------|------------|
| None | — | — |

### Evidence

- Schema:
  - Every relation has a clearly defined primary key
  - All primary key attributes are defined as NOT NULL and UNIQUE
  - Composite primary key of Space_Facility has both components defined as NOT NULL
  - No component of any primary key allows NULL values

---

## 4.4 Referential Integrity Constraints

### Findings

| Foreign Key | Referenced Relation | Validation Item | Status | Issue |
|------------|------------|------------|------------|------------|
| Booking.requester_id | User(user_id) | Referenced key exists | PASS | — |
| Booking.requester_id | User(user_id) | Referenced attribute is a key | PASS | — |
| Booking.requester_id | User(user_id) | Compatible domain and data type | PASS | — |
| Booking.space_code | Space(space_code) | Referenced key exists | PASS | — |
| Booking.space_code | Space(space_code) | Referenced attribute is a key | PASS | — |
| Booking.space_code | Space(space_code) | Compatible domain and data type | PASS | — |
| Approval.booking_id | Booking(booking_id) | Referenced key exists | PASS | — |
| Approval.booking_id | Booking(booking_id) | Referenced attribute is a key | PASS | — |
| Approval.booking_id | Booking(booking_id) | Compatible domain and data type | PASS | — |
| Approval.approver_id | User(user_id) | Referenced key exists | PASS | — |
| Approval.approver_id | User(user_id) | Referenced attribute is a key | PASS | — |
| Approval.approver_id | User(user_id) | Compatible domain and data type | PASS | — |
| Session.booking_id | Booking(booking_id) | Referenced key exists | PASS | — |
| Session.booking_id | Booking(booking_id) | Referenced attribute is a key | PASS | — |
| Session.booking_id | Booking(booking_id) | Compatible domain and data type | PASS | — |
| Session.conductor_id | User(user_id) | Referenced key exists | PASS | — |
| Session.conductor_id | User(user_id) | Referenced attribute is a key | PASS | — |
| Session.conductor_id | User(user_id) | Compatible domain and data type | PASS | — |
| Maintenance_Record.reporter_id | User(user_id) | Referenced key exists | PASS | — |
| Maintenance_Record.reporter_id | User(user_id) | Referenced attribute is a key | PASS | — |
| Maintenance_Record.reporter_id | User(user_id) | Compatible domain and data type | PASS | — |
| Maintenance_Record.space_code | Space(space_code) | Referenced key exists | PASS | — |
| Maintenance_Record.space_code | Space(space_code) | Referenced attribute is a key | PASS | — |
| Maintenance_Record.space_code | Space(space_code) | Compatible domain and data type | PASS | — |
| Maintenance_Record.assigned_staff_id | User(user_id) | Referenced key exists | PASS | — |
| Maintenance_Record.assigned_staff_id | User(user_id) | Referenced attribute is a key | PASS | — |
| Maintenance_Record.assigned_staff_id | User(user_id) | Compatible domain and data type | PASS | — |
| Space_Facility.space_code | Space(space_code) | Referenced key exists | PASS | — |
| Space_Facility.space_code | Space(space_code) | Referenced attribute is a key | PASS | — |
| Space_Facility.space_code | Space(space_code) | Compatible domain and data type | PASS | — |
| Space_Facility.facility_id | Facility(facility_id) | Referenced key exists | PASS | — |
| Space_Facility.facility_id | Facility(facility_id) | Referenced attribute is a key | PASS | — |
| Space_Facility.facility_id | Facility(facility_id) | Compatible domain and data type | PASS | — |

### Referential Integrity Violations

| Foreign Key | Violation | Recommended Correction |
|------------|------------|------------|
| None | — | — |

### Evidence

- Schema:
  - All 11 foreign keys reference existing relations
  - All referenced attributes are primary keys of their respective relations
  - Domain and data types are compatible (same type between FK and referenced PK)
  - No foreign key references a non-key attribute
  - All FK attributes on the total participation side are NOT NULL

---

## 4.5 NULL Constraint Validation

### Findings

| Relation | Attribute | Validation Item | Status | Issue |
|------------|------------|------------|------------|------------|
| User | user_id | NOT NULL — PK | PASS | — |
| User | first_name | NOT NULL — mandatory name component | PASS | — |
| User | last_name | NOT NULL — mandatory name component | PASS | — |
| User | email | NOT NULL — mandatory contact | PASS | — |
| User | phone_number | NULL allowed — optional contact | PASS | — |
| User | role | NOT NULL — mandatory | PASS | — |
| User | department | NOT NULL — mandatory | PASS | — |
| User | account_status | NOT NULL — mandatory | PASS | — |
| Space | space_code | NOT NULL — PK | PASS | — |
| Space | usage_policy | NULL allowed — optional policy text | PASS | — |
| Booking | requester_id | NOT NULL — FK, total participation | PASS | — |
| Booking | space_code | NOT NULL — FK, total participation | PASS | — |
| Booking | requested_start_time | NOT NULL — required | PASS | — |
| Booking | requested_end_time | NOT NULL — required | PASS | — |
| Approval | rejection_reason | NULL allowed — conditional requirement | PASS | Minor: Conditional NOT NULL not enforceable |
| Session | actual_start_time | NOT NULL — required when session created | PASS | — |
| Session | actual_end_time | NULL allowed — populated on completion | PASS | — |
| Session | initial_condition | NOT NULL — required at check-in | PASS | — |
| Session | final_condition | NULL allowed — populated on completion | PASS | — |
| Maintenance_Record | completion_time | NULL allowed — populated on completion | PASS | — |
| Maintenance_Record | result_note | NULL allowed — populated on completion | PASS | — |

### NULL Constraint Violations

| Relation | Attribute | Violation | Recommended Correction |
|------------|------------|------------|------------|
| None | — | — | — |

### Evidence

- Schema:
  - All primary key attributes defined as NOT NULL
  - All foreign keys on total participation side defined as NOT NULL
  - Optional attributes (phone_number, usage_policy, decision_note, rejection_reason, actual_end_time, final_condition, usage_notes, completion_time, result_note, description) allow NULL
  - No conflict between NULL constraints and key constraints
  - No conflict between NULL constraints and foreign key behavior

---

## 4.6 Constraint Consistency Validation

### Findings

| Relation | Validation Item | Status | Issue |
|------------|------------|------------|------------|
| All | Constraints do not conflict with each other | PASS | — |
| All | Primary key, UNIQUE, and foreign key constraints are consistent | PASS | — |
| All | Foreign keys reference valid keys without violating entity integrity | PASS | — |
| All | Domain constraints are consistent with attribute definitions | PASS | — |
| All | Composite key and foreign key definitions are consistent | PASS | — |

### Constraint Consistency Violations

| Relation | Violation | Recommended Correction |
|------------|------------|------------|
| None | — | — |

### Evidence

- Schema:
  - No conflicting constraints identified
  - Primary key, UNIQUE, and FK constraints are defined consistently
  - All FKs reference primary keys of referenced relations
  - Domain constraints align with attribute definitions
  - Composite PK of Space_Facility is consistent with its FK definitions

---

# Business Rule Validation

## Status: PASS

For each business rule, verify whether it can be enforced using logical-schema-level constraints only.

### Rule Validation Results

#### BR-01

**Business Rule**

> Each user must have a university account.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL on User attributes; UNIQUE on email

**Constraints Present In Schema**

- User table with PK user_id, NOT NULL on all mandatory fields, UNIQUE on email

**Status**

- PASS

**Issue**

- None

---

#### BR-02

**Business Rule**

> A user may be a student, lecturer, teaching assistant, facility staff, department administrator, or facility manager.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- Attribute-based CHECK constraint on User.role

**Constraints Present In Schema**

- User.role identified as enumeration with CHECK constraint

**Status**

- PASS

**Issue**

- None

---

#### BR-03

**Business Rule**

> A space may be available, in use, under maintenance, temporarily closed, or retired.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- Attribute-based CHECK constraint on Space.status

**Constraints Present In Schema**

- Space.status identified as enumeration with CHECK constraint

**Status**

- PASS

**Issue**

- None

---

#### BR-04

**Business Rule**

> A booking may be for a lecture, examination, seminar, workshop, meeting, student activity, or administrative event.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- Attribute-based CHECK constraint on Booking.purpose

**Constraints Present In Schema**

- Booking.purpose identified as enumeration with CHECK constraint

**Status**

- PASS

**Issue**

- None

---

#### BR-05

**Business Rule**

> Each booking request has a status: pending, approved, rejected, cancelled, checked in, completed, or no-show.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- Attribute-based CHECK constraint on Booking.status

**Constraints Present In Schema**

- Booking.status identified as enumeration with CHECK constraint

**Status**

- PASS

**Issue**

- None

---

#### BR-06

**Business Rule**

> The system must keep historical records of bookings and maintenance activities.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- Schema stores all records; no DELETE operations are restricted at schema level (this is a data retention policy, not a constraint)

**Constraints Present In Schema**

- Booking, Maintenance_Record, and related tables store data permanently

**Status**

- PASS

**Issue**

- None

---

#### BR-07

**Business Rule**

> A booking must be submitted by exactly one user.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- FK requester_id in Booking with NOT NULL referencing User(user_id)

**Constraints Present In Schema**

- Booking.requester_id FK NOT NULL → User(user_id)

**Status**

- PASS

**Issue**

- None

---

#### BR-08

**Business Rule**

> A booking must reserve exactly one space.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- FK space_code in Booking with NOT NULL referencing Space(space_code)

**Constraints Present In Schema**

- Booking.space_code FK NOT NULL → Space(space_code)

**Status**

- PASS

**Issue**

- None

---

#### BR-09

**Business Rule**

> A booking may have at most one approval decision.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- UNIQUE constraint on Approval.booking_id

**Constraints Present In Schema**

- Approval.booking_id defined as FK, UNIQUE

**Status**

- PASS

**Issue**

- None

---

#### BR-10

**Business Rule**

> A booking may have at most one corresponding session.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- UNIQUE constraint on Session.booking_id

**Constraints Present In Schema**

- Session.booking_id defined as FK, UNIQUE

**Status**

- PASS

**Issue**

- None

---

#### BR-11

**Business Rule**

> An approval decision must review exactly one booking.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- FK booking_id in Approval with NOT NULL referencing Booking(booking_id)

**Constraints Present In Schema**

- Approval.booking_id FK NOT NULL → Booking(booking_id)

**Status**

- PASS

**Issue**

- None

---

#### BR-12

**Business Rule**

> A session must correspond to exactly one booking.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- FK booking_id in Session with NOT NULL referencing Booking(booking_id)

**Constraints Present In Schema**

- Session.booking_id FK NOT NULL → Booking(booking_id)

**Status**

- PASS

**Issue**

- None

---

#### BR-13

**Business Rule**

> A session can only exist for a booking with status approved.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify Booking.status = 'approved' when inserting into Session

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires cross-table validation beyond foreign keys

**Recommended Correction**

- Implement a trigger on Session INSERT that checks Booking.status = 'approved' for the referenced booking_id

---

#### BR-14

**Business Rule**

> The same space cannot have two approved bookings with overlapping time periods.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Exclusion constraint or trigger to detect overlapping time periods for same space_code where status = 'approved'

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires validation involving multiple rows and detection of overlapping time periods

**Recommended Correction**

- Implement a trigger or application logic that checks for time period overlap on INSERT/UPDATE of Booking with status = 'approved'

---

#### BR-15

**Business Rule**

> A maintenance record must be reported by exactly one user.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- FK reporter_id in Maintenance_Record with NOT NULL referencing User(user_id)

**Constraints Present In Schema**

- Maintenance_Record.reporter_id FK NOT NULL → User(user_id)

**Status**

- PASS

**Issue**

- None

---

#### BR-16

**Business Rule**

> A maintenance record must be assigned to exactly one facility staff member.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- FK assigned_staff_id in Maintenance_Record with NOT NULL referencing User(user_id)

**Constraints Present In Schema**

- Maintenance_Record.assigned_staff_id FK NOT NULL → User(user_id)

**Status**

- PASS

**Issue**

- None

---

#### BR-17

**Business Rule**

> A maintenance record must be associated with exactly one space.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- FK space_code in Maintenance_Record with NOT NULL referencing Space(space_code)

**Constraints Present In Schema**

- Maintenance_Record.space_code FK NOT NULL → Space(space_code)

**Status**

- PASS

**Issue**

- None

---

#### BR-18

**Business Rule**

> The reporter and assigned staff of a maintenance record may be different users.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- N/A — This is a permission statement, not an enforceable constraint

**Required Constraints**

- Not applicable (the schema allows different values for reporter_id and assigned_staff_id)

**Constraints Present In Schema**

- Maintenance_Record has separate reporter_id and assigned_staff_id columns, both referencing User

**Status**

- PASS

**Issue**

- None

---

#### BR-19

**Business Rule**

> A space should not have overlapping active (open) maintenance records.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to detect overlapping active maintenance records for the same space_code

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires validation involving multiple rows and detection of overlapping active maintenance periods

**Recommended Correction**

- Implement a trigger or application logic that checks for overlapping active maintenance records on INSERT/UPDATE of Maintenance_Record

---

#### BR-20

**Business Rule**

> Only users with an active account status may submit booking requests.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify User.account_status = 'active' when inserting Booking

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires validation involving another table beyond foreign keys and user role/permission validation

**Recommended Correction**

- Implement a trigger on Booking INSERT that checks User.account_status = 'active' for the referenced requester_id

---

#### BR-21

**Business Rule**

> Only facility staff and facility managers may approve or reject booking requests.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify User.role IN ('facility_staff', 'facility_manager') when inserting into Approval

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires user role or permission validation

**Recommended Correction**

- Implement a trigger on Approval INSERT that checks User.role for the referenced approver_id

---

#### BR-22

**Business Rule**

> Only facility staff may conduct check-in and check-out sessions.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify User.role = 'facility_staff' when inserting into Session

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires user role or permission validation

**Recommended Correction**

- Implement a trigger on Session INSERT that checks User.role = 'facility_staff' for the referenced conductor_id

---

#### BR-23

**Business Rule**

> Only facility staff may be assigned to handle maintenance records.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify User.role = 'facility_staff' when updating Maintenance_Record.assigned_staff_id

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires user role or permission validation

**Recommended Correction**

- Implement a trigger on Maintenance_Record INSERT/UPDATE that checks User.role = 'facility_staff' for the referenced assigned_staff_id

---

#### BR-24

**Business Rule**

> A booking must have status pending before it can be reviewed for approval or rejection.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify Booking.status = 'pending' when inserting into Approval

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires workflow or state transition logic and cross-table validation

**Recommended Correction**

- Implement a trigger on Approval INSERT that checks Booking.status = 'pending' for the referenced booking_id

---

#### BR-25

**Business Rule**

> An approved booking transitions to checked_in when a session is started.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to update Booking.status to 'checked_in' when a Session record is created; also requires checking current state

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires workflow or state transition logic and cross-table validation

**Recommended Correction**

- Implement a trigger on Session INSERT that updates Booking.status to 'checked_in' for the referenced booking_id

---

#### BR-26

**Business Rule**

> A checked-in booking transitions to completed when the session is ended.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to update Booking.status to 'completed' when Session.actual_end_time is set

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires workflow or state transition logic and cross-table validation

**Recommended Correction**

- Implement a trigger on Session UPDATE that checks when actual_end_time transitions from NULL to a value and updates Booking.status accordingly

---

#### BR-27

**Business Rule**

> A booking that is approved but never checked in by the requested end time transitions to no-show.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Scheduled job or time-based trigger to detect approved bookings past requested_end_time without a corresponding session

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires automatic time-based updates and knowledge of previous database states

**Recommended Correction**

- Implement a scheduled job or application logic that periodically checks for approved bookings past requested_end_time without a linked session and updates status to 'no-show'

---

#### BR-28

**Business Rule**

> An approved booking requires an associated approval record with decision approved.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify both that an Approval record exists for the booking and that its decision = 'approved'

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires conditional existence of related records and cross-table validation

**Recommended Correction**

- Implement application logic that enforces creation of an Approval record with decision='approved' before setting Booking.status='approved'

---

#### BR-29

**Business Rule**

> A rejected booking requires an associated approval record with decision rejected and a rejection reason.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify Approval record exists with decision='rejected' and rejection_reason IS NOT NULL

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires conditional existence and conditional NOT NULL across related records

**Recommended Correction**

- Implement a trigger on Approval INSERT that enforces rejection_reason IS NOT NULL when decision = 'rejected'; implement application logic for the booking status linkage

---

#### BR-30

**Business Rule**

> A checked-in booking requires a session with actual start time and initial condition.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No (for the cross-table linkage). Partial enforcement: actual_start_time and initial_condition are NOT NULL in Session.

**Required Constraints**

- NOT NULL on Session.actual_start_time and Session.initial_condition (to ensure data completeness when a session is created)
- Trigger or application logic to link Booking.status = 'checked_in' with session existence

**Constraints Present In Schema**

- Session.actual_start_time NOT NULL; Session.initial_condition NOT NULL

**Status**

- Not Enforceable (cross-table linkage); PASS (attribute-level completeness)

**Issue**

- The NOT NULL constraints ensure the attributes are always provided. The cross-table dependency on Booking.status requires application logic or a trigger.

**Recommended Correction**

- Implement a trigger that ensures the Booking status transitions appropriately when a Session is created with actual_start_time and initial_condition

---

#### BR-31

**Business Rule**

> A completed booking requires a session with actual end time, final condition, and usage notes.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Conditional NOT NULL — actual_end_time, final_condition, usage_notes required only when booking is completed
- Trigger or application logic needed for the conditional requirement

**Constraints Present In Schema**

- Session.actual_end_time NULL allowed; Session.final_condition NULL allowed; Session.usage_notes NULL allowed

**Status**

- Not Enforceable

**Issue**

- Requires conditional NOT NULL and cross-table state management

**Recommended Correction**

- Implement application logic or a trigger that enforces actual_end_time, final_condition, and usage_notes are provided when completing a session

---

#### BR-32

**Business Rule**

> A space with status under_maintenance, temporarily_closed, or retired cannot be booked.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to verify Space.status NOT IN ('under_maintenance', 'temporarily_closed', 'retired') when inserting Booking

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires cross-table validation beyond foreign keys

**Recommended Correction**

- Implement a trigger on Booking INSERT that checks Space.status for the referenced space_code

---

#### BR-33

**Business Rule**

> A maintenance record with status reported or in_progress prevents the related space from being booked.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Trigger or application logic to check that no open maintenance record exists for the space_code before allowing a new Booking

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires validation involving multiple rows in another table

**Recommended Correction**

- Implement a trigger on Booking INSERT that checks for existing Maintenance_Record entries with the same space_code and status IN ('reported', 'in_progress')

---

#### BR-34

**Business Rule**

> A completed maintenance record requires completion time and result note.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Conditional NOT NULL — completion_time and result_note required only when status = 'completed'
- Trigger or application logic needed

**Constraints Present In Schema**

- Maintenance_Record.completion_time NULL allowed; Maintenance_Record.result_note NULL allowed

**Status**

- Not Enforceable

**Issue**

- Requires conditional NOT NULL based on attribute value

**Recommended Correction**

- Implement a trigger on Maintenance_Record UPDATE that enforces completion_time IS NOT NULL and result_note IS NOT NULL when status is set to 'completed'

---

#### BR-35

**Business Rule**

> Requested start time must occur before requested end time.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Tuple-based CHECK constraint (requested_start_time < requested_end_time) — not allowed per constraint scope

**Constraints Present In Schema**

- None (not enforceable via attribute-level constraints only)

**Status**

- Not Enforceable

**Issue**

- Requires tuple-based CHECK constraint comparing two attributes

**Recommended Correction**

- Implement a table-level CHECK constraint (requested_start_time < requested_end_time) in the SQL DDL, which is supported by MS SQL Server

---

#### BR-36

**Business Rule**

> Booking requests must have a requested start time in the future.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Requires comparison with current system time (GETDATE())

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires knowledge of current time, which is not available in attribute-based CHECK constraints

**Recommended Correction**

- Implement application logic that validates requested_start_time > current time before insert

---

#### BR-37

**Business Rule**

> Approval decision time must occur before the booking requested start time.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Cross-table comparison (Approval.decision_time < Booking.requested_start_time) — requires trigger

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires cross-table validation

**Recommended Correction**

- Implement a trigger on Approval INSERT that compares decision_time with the referenced Booking.requested_start_time

---

#### BR-38

**Business Rule**

> Actual start time must occur before actual end time.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Tuple-based CHECK constraint (actual_start_time < actual_end_time) — not allowed per constraint scope

**Constraints Present In Schema**

- None (not enforceable via attribute-level constraints only)

**Status**

- Not Enforceable

**Issue**

- Requires tuple-based CHECK constraint comparing two attributes

**Recommended Correction**

- Implement a table-level CHECK constraint (actual_start_time < actual_end_time) in the SQL DDL, which is supported by MS SQL Server

---

#### BR-39

**Business Rule**

> Completion time must occur after start time for completed maintenance records.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Tuple-based CHECK constraint (completion_time > start_time) combined with conditional enforcement for status = 'completed' — requires trigger

**Constraints Present In Schema**

- None (not enforceable via attribute-level constraints only)

**Status**

- Not Enforceable

**Issue**

- Requires tuple-based CHECK and conditional enforcement

**Recommended Correction**

- Implement a trigger that validates completion_time > start_time when status is set to 'completed'

---

#### BR-40

**Business Rule**

> Expected participants must not exceed the reserved space capacity.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Cross-table validation (Booking.expected_participants <= Space.capacity) — requires trigger

**Constraints Present In Schema**

- None (not enforceable via table-level constraints)

**Status**

- Not Enforceable

**Issue**

- Requires cross-table validation beyond foreign keys

**Recommended Correction**

- Implement a trigger on Booking INSERT/UPDATE that compares expected_participants with Space.capacity for the referenced space_code

---

#### BR-41

**Business Rule**

> Rejection reason must be provided when an approval decision is rejected.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- Conditional NOT NULL — rejection_reason IS NOT NULL when decision = 'rejected'
- Attribute-based CHECK constraint cannot reference other attributes

**Constraints Present In Schema**

- Approval.rejection_reason NULL allowed (no conditional constraint)

**Status**

- Not Enforceable

**Issue**

- Requires conditional NOT NULL based on another attribute value in the same row (tuple-based CHECK)

**Recommended Correction**

- Implement a table-level CHECK constraint (decision <> 'rejected' OR rejection_reason IS NOT NULL) in the SQL DDL, which is supported by MS SQL Server

---

# Issues List

## Critical Issues

| ID | Category | Description | Recommended Correction |
|------|------|------|------|
| None | — | — | — |

## Minor Issues

| ID | Category | Description | Recommended Correction |
|------|------|------|------|
| M-01 | Documentation | User.phone_number optionality is not explicitly documented in the logical schema | Add documentation clarifying that phone_number is optional and allows NULL |
| M-02 | Documentation | Approval.rejection_reason conditional requirement is noted but not enforced | Document that rejection_reason is required only when decision = 'rejected'; enforce via CHECK constraint in SQL DDL |

---

# Final Verdict

## 1. ERD to Relational Schema Compatibility

PASS

### Explanation

- All 7 ERD entities are correctly mapped to relations with appropriate primary keys.
- All 10 relationships are correctly represented via foreign key references or the Space_Facility associative relation.
- 1:1 relationships (reviews, tracks) use the correct Rule 3 strategy — FK with UNIQUE in the total participation side.
- 1:N relationships correctly place FK in the N-side relation per Rule 4.
- M:N relationship (equipped_with) correctly resolved via associative relation with relationship attribute quantity.
- All special constructs are correctly handled: composite attribute full_name decomposed, no weak/multivalued/recursive/N-ary constructs present.
- All business-defined candidate keys are preserved.
- Foreign key placement correctly reflects cardinality and participation constraints.

---

## 2. Business Rule Enforcement

PASS

### Explanation

- 17 of 41 business rules (BR-01 to BR-12, BR-15 to BR-18) are directly enforceable using logical-schema-level constraints (FK, NOT NULL, UNIQUE, CHECK).
- 3 rules (BR-06, BR-18, BR-30) are partially supported or are permission statements rather than constraints — all are satisfied.
- 21 rules (BR-13, BR-14, BR-19 to BR-29, BR-31 to BR-41) are not enforceable using only attribute-based CHECK, NULL/NOT NULL, key, entity integrity, or referential integrity constraints. These rules require triggers, application logic, scheduled jobs, or tuple-based CHECK constraints.
- According to the validation rules, "Do not mark a rule as fail if it is not enforceable." All non-enforceable rules are correctly identified as such.
- All enforceable rules are satisfied by the relational schema.
- The logical schema correctly represents all business rules that can be enforced at the schema level.

---

## Conclusion

### Compatible Mapping

- Yes

### All Enforceable Business Rules Satisfied

- Yes

### Overall Result

- ACCEPTABLE
