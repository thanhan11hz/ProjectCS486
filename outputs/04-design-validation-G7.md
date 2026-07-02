# Design Validation Report

## Summary

| Metric | Count |
|--------|-------|
| Total Issues Found | 4 |
| Critical Issues | 0 |
| Minor Issues | 4 |

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
|------------|----------|--------------|
| User | User | All attributes present; PK user_id; CK email |
| Space | Space | All attributes present; PK space_code; CK (building, floor, room_number) |
| Facility | Facility | All attributes present; PK facility_id; CK facility_name |
| Booking | Booking | All attributes present; PK booking_id |
| Approval | Approval | All attributes present; PK approval_id |
| Session | Session | All attributes present; PK session_id |
| Maintenance Record | Maintenance_Record | All attributes present; PK maintenance_id |

#### Missing Entities

None.

#### Unnecessary Relations

None — Space_Facility is a required associative relation for M:N equipped_with.

#### Attribute Coverage

| Entity / Relation | Missing Attributes | Recommended Correction |
|-------------------|-------------------|-----------------------|
| None | — | — |

### Evidence

- ERD: 7 entities defined (User, Space, Facility, Booking, Approval, Session, Maintenance Record).
- Relational Schema: 8 relations (User, Space, Facility, Booking, Approval, Session, Maintenance_Record, Space_Facility).
- All entity attributes present in corresponding relations; full_name decomposed into first_name, last_name.

---

## 2. Relationship Coverage

### Status: PASS

### Findings

#### Correct Relationship Mappings

| Relationship | Representation | Verification |
|--------------|----------------|--------------|
| submits (User 1:N Booking) | FK requester_id in Booking → User | Rule 4 — FK on N-side (Booking), NOT NULL (total participation) |
| reserves (Booking N:1 Space) | FK space_code in Booking → Space | Rule 4 — FK on N-side (Booking), NOT NULL (total participation) |
| makes (User 1:N Approval) | FK approver_id in Approval → User | Rule 4 — FK on N-side (Approval), NOT NULL (total participation) |
| reviews (Approval 1:1 Booking) | FK booking_id (UNIQUE) in Approval → Booking | Rule 3 — FK in total participation side (Approval), UNIQUE enforces 1:1 |
| conducts (User 1:N Session) | FK conductor_id in Session → User | Rule 4 — FK on N-side (Session), NOT NULL (total participation) |
| tracks (Session 1:1 Booking) | FK booking_id (UNIQUE) in Session → Booking | Rule 3 — FK in total participation side (Session), UNIQUE enforces 1:1 |
| reports (User 1:N Maintenance_Record) | FK reporter_id in Maintenance_Record → User | Rule 4 — FK on N-side (Maintenance_Record), NOT NULL (total participation) |
| pertains_to (Maintenance_Record N:1 Space) | FK space_code in Maintenance_Record → Space | Rule 4 — FK on N-side (Maintenance_Record), NOT NULL (total participation) |
| equipped_with (Space M:N Facility) | Space_Facility associative relation | Rule 5 — Associative relation with composite PK (space_code, facility_id); quantity preserved |
| assigned_to (User 1:N Maintenance_Record) | FK assigned_staff_id in Maintenance_Record → User | Rule 4 — FK on N-side (Maintenance_Record), NOT NULL (total participation) |

#### Incorrect Relationship Mappings

None.

#### Missing Relationships

None.

---

### Relationship Relations Validation

#### Correct Relationship Relations

| Relation | Verification |
|----------|--------------|
| Space_Facility | Composite PK (space_code, facility_id); FKs reference Space and Facility; quantity attribute preserved |

#### Incorrect Relationship Relations

None.

### Evidence

- ERD: 10 relationships defined with documented cardinality and participation constraints.
- Relational Schema: All 10 relationships represented via FK references or associative relation.
- Mapping rules correctly applied (Rule 3 for 1:1, Rule 4 for 1:N, Rule 5 for M:N).

---

## 3. Special Construct Validation

### Status: PASS

### Findings

#### Composite Attributes

| Construct | Verification | Issue |
|-----------|--------------|-------|
| User.full_name (first_name, last_name) | PASS — Decomposed into first_name and last_name per Rule 8 | None |

#### Multivalued Attributes

| Construct | Verification | Issue |
|-----------|--------------|-------|
| None identified | PASS — No multivalued attributes present | None |

#### Weak Entities

| Construct | Verification | Issue |
|-----------|--------------|-------|
| None identified | PASS — All entities classified as strong | None |

#### N-ary Relationships

| Construct | Verification | Issue |
|-----------|--------------|-------|
| None identified | PASS — All relationships are binary | None |

#### Recursive Relationships

| Construct | Verification | Issue |
|-----------|--------------|-------|
| None identified | PASS — No recursive relationships | None |

#### Derived Attributes

| Construct | Verification | Issue |
|-----------|--------------|-------|
| None stored | PASS — No derived attributes per Rule 13 | None |

#### Mapping Rule Validation

| Mapping Rule | Verification | Issue |
|--------------|--------------|-------|
| Rule 1 — Strong Entity Mapping | PASS — All 7 strong entities mapped to relations | None |
| Rule 2 — Weak Entity Mapping | N/A — No weak entities | — |
| Rule 3 — Binary 1:1 Mapping | PASS — reviews and tracks mapped with FK + UNIQUE on total participation side | None |
| Rule 4 — Binary 1:N Mapping | PASS — All 7 1:N relationships mapped with FK on N-side | None |
| Rule 5 — Binary M:N Mapping | PASS — equipped_with mapped via Space_Facility associative relation | None |
| Rule 6 — N-ary Relationship Mapping | N/A — No N-ary relationships | — |
| Rule 7 — Multivalued Attribute Mapping | N/A — No multivalued attributes | — |
| Rule 8 — Composite Attribute Mapping | PASS — full_name decomposed into first_name, last_name | None |
| Rule 9 — Relationship Attribute Mapping | PASS — quantity preserved in Space_Facility | None |
| Rule 10 — Recursive Relationship Mapping | N/A — No recursive relationships | — |
| Rule 11 — Candidate Key Preservation | PASS — email, (building, floor, room_number), facility_name preserved | None |
| Rule 12 — Foreign Key Representation | PASS — All 11 FK references documented | None |
| Rule 13 — Derived Attributes | N/A — No derived attributes stored | — |

### Evidence

- ERD: full_name classified as composite; no weak entities, multivalued attributes, recursive relationships, N-ary relationships, or derived attributes.
- Relational Schema: full_name decomposed; no additional relations needed for special constructs.
- Mapping Rules: All applicable rules correctly applied.

---

## 4. Constraint Validation

### Status: PASS

---

## 4.1 Domain Constraints

### Findings

| Relation | Attribute | Constraint Type | Expected Constraint | Status | Issue |
|----------|-----------|-----------------|---------------------|--------|-------|
| User | role | Domain / CHECK | One of: student, lecturer, teaching_assistant, facility_staff, department_administrator, facility_manager | PASS | Not explicitly enumerated but documented as enumeration |
| User | account_status | Domain / CHECK | One of: active, suspended | PASS | Not explicitly enumerated but documented as enumeration |
| User | email | UNIQUE | Unique email per BR-01 | PASS | CK email documented with UNIQUE |
| Space | space_type | Domain / CHECK | One of: auditorium, classroom, computer_laboratory, project_laboratory, meeting_room, student_workspace | PASS | Not explicitly enumerated but documented as enumeration |
| Space | status | Domain / CHECK | One of: available, in_use, under_maintenance, temporarily_closed, retired | PASS | Not explicitly enumerated but documented as enumeration |
| Space | capacity | Domain | Integer > 0 | PASS | Logical schema documents as int |
| Booking | purpose | Domain / CHECK | One of: lecture, examination, seminar, workshop, meeting, student_activity, administrative_event | PASS | Not explicitly enumerated but documented as enumeration |
| Booking | status | Domain / CHECK | One of: pending, approved, rejected, cancelled, checked_in, completed, no_show | PASS | Not explicitly enumerated but documented as enumeration |
| Approval | decision | Domain / CHECK | One of: approved, rejected | PASS | Not explicitly enumerated but documented as enumeration |
| Maintenance_Record | status | Domain / CHECK | One of: reported, in_progress, completed | PASS | Not explicitly enumerated but documented as enumeration |

### Domain Constraint Violations

None.

### Evidence

- Schema: All enumerated attributes use generic "string" type; domain value sets are defined in the business requirements and ERD but not specified as CHECK constraints in the logical schema. This is acceptable at the logical design stage; CHECK constraints will be specified during SQL implementation.

---

## 4.2 Key Constraints

### Findings

| Relation | Key Type | Attributes | Validation Item | Status | Issue |
|----------|----------|------------|-----------------|--------|-------|
| User | Primary Key | user_id | PK correctly identified | PASS | — |
| User | Candidate Key | email | CK preserved | PASS | — |
| User | UNIQUE | email | UNIQUE constraint documented | PASS | — |
| Space | Primary Key | space_code | PK correctly identified | PASS | — |
| Space | Candidate Key | (building, floor, room_number) | CK preserved | PASS | — |
| Space | UNIQUE | (building, floor, room_number) | UNIQUE constraint documented | PASS | — |
| Facility | Primary Key | facility_id | PK correctly identified | PASS | — |
| Facility | Candidate Key | facility_name | CK preserved | PASS | — |
| Facility | UNIQUE | facility_name | UNIQUE constraint documented | PASS | — |
| Booking | Primary Key | booking_id | PK correctly identified | PASS | — |
| Approval | Primary Key | approval_id | PK correctly identified | PASS | — |
| Approval | Foreign Key | booking_id | UNIQUE + FK correctly enforces 1:1 reviews | PASS | — |
| Session | Primary Key | session_id | PK correctly identified | PASS | — |
| Session | Foreign Key | booking_id | UNIQUE + FK correctly enforces 1:1 tracks | PASS | — |
| Maintenance_Record | Primary Key | maintenance_id | PK correctly identified | PASS | — |
| Space_Facility | Primary Key | (space_code, facility_id) | Composite PK correctly defined | PASS | — |

### Key Constraint Violations

None.

### Evidence

- Schema: All PKs clearly defined; CKs documented with UNIQUE constraints; composite PK for Space_Facility correctly uses both FKs.

---

## 4.3 Entity Integrity Constraints

### Findings

| Relation | Validation Item | Status | Issue |
|----------|-----------------|--------|-------|
| User | Primary key attributes are NOT NULL | PASS | user_id defined as NOT NULL |
| User | Primary key attributes are UNIQUE | PASS | user_id defined as UNIQUE |
| User | Primary key is clearly identified | PASS | user_id documented as PK |
| Space | Primary key attributes are NOT NULL | PASS | space_code defined as NOT NULL |
| Space | Primary key attributes are UNIQUE | PASS | space_code defined as UNIQUE |
| Space | Primary key is clearly identified | PASS | space_code documented as PK |
| Facility | Primary key attributes are NOT NULL | PASS | facility_id defined as NOT NULL |
| Facility | Primary key attributes are UNIQUE | PASS | facility_id defined as UNIQUE |
| Facility | Primary key is clearly identified | PASS | facility_id documented as PK |
| Booking | Primary key attributes are NOT NULL | PASS | booking_id defined as NOT NULL |
| Booking | Primary key attributes are UNIQUE | PASS | booking_id defined as UNIQUE |
| Booking | Primary key is clearly identified | PASS | booking_id documented as PK |
| Approval | Primary key attributes are NOT NULL | PASS | approval_id defined as NOT NULL |
| Approval | Primary key attributes are UNIQUE | PASS | approval_id defined as UNIQUE |
| Approval | Primary key is clearly identified | PASS | approval_id documented as PK |
| Session | Primary key attributes are NOT NULL | PASS | session_id defined as NOT NULL |
| Session | Primary key attributes are UNIQUE | PASS | session_id defined as UNIQUE |
| Session | Primary key is clearly identified | PASS | session_id documented as PK |
| Maintenance_Record | Primary key attributes are NOT NULL | PASS | maintenance_id defined as NOT NULL |
| Maintenance_Record | Primary key attributes are UNIQUE | PASS | maintenance_id defined as UNIQUE |
| Maintenance_Record | Primary key is clearly identified | PASS | maintenance_id documented as PK |
| Space_Facility | Composite PK components do not allow NULL | PASS | space_code, facility_code both NOT NULL |
| Space_Facility | Primary key is clearly identified | PASS | (space_code, facility_id) documented as PK |

### Entity Integrity Violations

None.

### Evidence

- Schema: Every relation has a clearly defined PK; all PK attributes are NOT NULL; Space_Facility composite PK correctly prevents NULL in any component.

---

## 4.4 Referential Integrity Constraints

### Findings

| Foreign Key | Referenced Relation | Validation Item | Status | Issue |
|-------------|---------------------|-----------------|--------|-------|
| Booking.requester_id | User(user_id) | Referenced key exists | PASS | user_id is PK of User |
| Booking.requester_id | User(user_id) | Referenced attribute is a key | PASS | user_id is PK |
| Booking.requester_id | User(user_id) | Compatible domain and data type | PASS | Both string |
| Booking.space_code | Space(space_code) | Referenced key exists | PASS | space_code is PK of Space |
| Booking.space_code | Space(space_code) | Referenced attribute is a key | PASS | space_code is PK |
| Booking.space_code | Space(space_code) | Compatible domain and data type | PASS | Both string |
| Approval.booking_id | Booking(booking_id) | Referenced key exists | PASS | booking_id is PK of Booking |
| Approval.booking_id | Booking(booking_id) | Referenced attribute is a key | PASS | booking_id is PK |
| Approval.booking_id | Booking(booking_id) | Compatible domain and data type | PASS | Both string |
| Approval.approver_id | User(user_id) | Referenced key exists | PASS | user_id is PK of User |
| Approval.approver_id | User(user_id) | Referenced attribute is a key | PASS | user_id is PK |
| Approval.approver_id | User(user_id) | Compatible domain and data type | PASS | Both string |
| Session.booking_id | Booking(booking_id) | Referenced key exists | PASS | booking_id is PK of Booking |
| Session.booking_id | Booking(booking_id) | Referenced attribute is a key | PASS | booking_id is PK |
| Session.booking_id | Booking(booking_id) | Compatible domain and data type | PASS | Both string |
| Session.conductor_id | User(user_id) | Referenced key exists | PASS | user_id is PK of User |
| Session.conductor_id | User(user_id) | Referenced attribute is a key | PASS | user_id is PK |
| Session.conductor_id | User(user_id) | Compatible domain and data type | PASS | Both string |
| Maintenance_Record.reporter_id | User(user_id) | Referenced key exists | PASS | user_id is PK of User |
| Maintenance_Record.reporter_id | User(user_id) | Referenced attribute is a key | PASS | user_id is PK |
| Maintenance_Record.reporter_id | User(user_id) | Compatible domain and data type | PASS | Both string |
| Maintenance_Record.space_code | Space(space_code) | Referenced key exists | PASS | space_code is PK of Space |
| Maintenance_Record.space_code | Space(space_code) | Referenced attribute is a key | PASS | space_code is PK |
| Maintenance_Record.space_code | Space(space_code) | Compatible domain and data type | PASS | Both string |
| Maintenance_Record.assigned_staff_id | User(user_id) | Referenced key exists | PASS | user_id is PK of User |
| Maintenance_Record.assigned_staff_id | User(user_id) | Referenced attribute is a key | PASS | user_id is PK |
| Maintenance_Record.assigned_staff_id | User(user_id) | Compatible domain and data type | PASS | Both string |
| Space_Facility.space_code | Space(space_code) | Referenced key exists | PASS | space_code is PK of Space |
| Space_Facility.space_code | Space(space_code) | Referenced attribute is a key | PASS | space_code is PK |
| Space_Facility.space_code | Space(space_code) | Compatible domain and data type | PASS | Both string |
| Space_Facility.facility_id | Facility(facility_id) | Referenced key exists | PASS | facility_id is PK of Facility |
| Space_Facility.facility_id | Facility(facility_id) | Referenced attribute is a key | PASS | facility_id is PK |
| Space_Facility.facility_id | Facility(facility_id) | Compatible domain and data type | PASS | Both string |

### Referential Integrity Violations

None.

### Evidence

- Schema: All 11 foreign keys reference valid PK attributes; domains are compatible (all string type); no FK references a non-key attribute.

---

## 4.5 NULL Constraint Validation

### Findings

| Relation | Attribute | Validation Item | Status | Issue |
|----------|-----------|-----------------|--------|-------|
| Booking | requester_id | NOT NULL (total participation in submits) | PASS | Correct |
| Booking | space_code | NOT NULL (total participation in reserves) | PASS | Correct |
| Approval | booking_id | NOT NULL (total participation in reviews) | PASS | Correct |
| Approval | approver_id | NOT NULL (total participation in makes) | PASS | Correct |
| Session | booking_id | NOT NULL (total participation in tracks) | PASS | Correct |
| Session | conductor_id | NOT NULL (total participation in conducts) | PASS | Correct |
| Maintenance_Record | reporter_id | NOT NULL (total participation in reports) | PASS | Correct |
| Maintenance_Record | space_code | NOT NULL (total participation in pertains_to) | PASS | Correct |
| Maintenance_Record | assigned_staff_id | NOT NULL (total participation in assigned_to) | PASS | Correct |
| Space_Facility | space_code | NOT NULL (part of composite PK) | PASS | Correct |
| Space_Facility | facility_id | NOT NULL (part of composite PK) | PASS | Correct |

### NULL Constraint Violations

None.

### Evidence

- Schema: All total participation constraints mapped to NOT NULL FKs; composite PK components correctly NOT NULL.

---

## 4.6 Constraint Consistency Validation

### Findings

| Relation | Validation Item | Status | Issue |
|----------|-----------------|--------|-------|
| All | Constraints do not conflict with each other | PASS | No conflicting constraints identified |
| All | Primary key, UNIQUE, and foreign key constraints are consistent | PASS | All PKs, UNIQUE, and FK constraints are compatible |
| All | Foreign keys reference valid keys without violating entity integrity | PASS | All FKs reference PKs of referenced relations |
| All | Domain constraints are consistent with attribute definitions | PASS | Attribute types are consistent across relations |
| All | Composite key and foreign key definitions are consistent | PASS | Space_Facility composite PK correctly matches FK pairs |

### Constraint Consistency Violations

None.

### Evidence

- Schema: All constraints are internally consistent; no conflicts between PK, FK, UNIQUE, and NOT NULL constraints.

---

# Business Rule Validation

## Status: PASS

For each business rule, verify whether it can be enforced using logical-schema-level constraints only.

### Rule Validation Results

---

#### BR-01

**Business Rule**

> Each user must have a university account.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL on email, UNIQUE on email

**Constraints Present In Schema**

- User.email is defined as candidate key with UNIQUE constraint

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

- CHECK constraint on User.role to restrict to enumerated values

**Constraints Present In Schema**

- Logical schema documents role as enumeration but does not specify explicit CHECK — acceptable at logical design stage

**Status**

- PASS

**Issue**

- Domain values should be enforced via CHECK during SQL implementation

---

#### BR-03

**Business Rule**

> A space may be available, in use, under maintenance, temporarily closed, or retired.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on Space.status to restrict to enumerated values

**Constraints Present In Schema**

- Logical schema documents status as enumeration

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

- CHECK constraint on Booking.purpose to restrict to enumerated values

**Constraints Present In Schema**

- Logical schema documents purpose as enumeration

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

- CHECK constraint on Booking.status to restrict to enumerated values

**Constraints Present In Schema**

- Logical schema documents status as enumeration

**Status**

- PASS

**Issue**

- None

---

#### BR-06

**Business Rule**

> The system must keep historical records of bookings and maintenance activities.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — This is a system architecture requirement, not a schema-level constraint

**Constraints Present In Schema**

- Booking and Maintenance_Record tables exist and store all required data; historical preservation is an application-level policy

**Status**

- PASS

**Issue**

- The rule is satisfied by the presence of tables that store booking and maintenance data; enforcement of "never delete" is application-level, not schema-level

**Recommended Correction**

- No schema correction needed; historical preservation must be enforced via application policy and deletion restrictions in SQL implementation

---

#### BR-07

**Business Rule**

> A booking must be submitted by exactly one user.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL + FK on Booking.requester_id referencing User(user_id)

**Constraints Present In Schema**

- Booking.requester_id is FK NOT NULL referencing User(user_id)

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

- NOT NULL + FK on Booking.space_code referencing Space(space_code)

**Constraints Present In Schema**

- Booking.space_code is FK NOT NULL referencing Space(space_code)

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

- Approval.booking_id is defined as FK with UNIQUE constraint

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

- Session.booking_id is defined as FK with UNIQUE constraint

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

- NOT NULL + FK on Approval.booking_id referencing Booking(booking_id)

**Constraints Present In Schema**

- Approval.booking_id is FK NOT NULL referencing Booking(booking_id)

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

- NOT NULL + FK on Session.booking_id referencing Booking(booking_id)

**Constraints Present In Schema**

- Session.booking_id is FK NOT NULL referencing Booking(booking_id)

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

- N/A — Requires cross-table validation (Session references Booking.status), which is not supported by logical-schema-level constraints

**Constraints Present In Schema**

- Session.booking_id FK references Booking; but no constraint prevents creating a session for a non-approved booking

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign key checks

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-14

**Business Rule**

> The same space cannot have two approved bookings with overlapping time periods.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires multi-row validation (overlapping time ranges for the same space), which is not supported by logical-schema-level constraints

**Constraints Present In Schema**

- No constraint prevents overlapping booking time periods for the same space

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple rows

**Recommended Correction**

- Enforce via exclusion constraint, trigger, or application logic during SQL implementation

---

#### BR-15

**Business Rule**

> A maintenance record must be reported by exactly one user.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL + FK on Maintenance_Record.reporter_id referencing User(user_id)

**Constraints Present In Schema**

- Maintenance_Record.reporter_id is FK NOT NULL referencing User(user_id)

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

- NOT NULL + FK on Maintenance_Record.assigned_staff_id referencing User(user_id)

**Constraints Present In Schema**

- Maintenance_Record.assigned_staff_id is FK NOT NULL referencing User(user_id)

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

- NOT NULL + FK on Maintenance_Record.space_code referencing Space(space_code)

**Constraints Present In Schema**

- Maintenance_Record.space_code is FK NOT NULL referencing Space(space_code)

**Status**

- PASS

**Issue**

- None

---

#### BR-18

**Business Rule**

> The reporter and assigned staff of a maintenance record may be different users.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires tuple-based CHECK constraint (reporter_id != assigned_staff_id)

**Constraints Present In Schema**

- reporter_id and assigned_staff_id are separate FKs; no constraint enforces they are different

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple attributes of a tuple

**Recommended Correction**

- Enforce via tuple-based CHECK constraint (reporter_id <> assigned_staff_id) during SQL implementation, or via application logic

---

#### BR-19

**Business Rule**

> A space may have multiple maintenance records over time but should not have overlapping active (open) maintenance records.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires multi-row validation (overlapping active maintenance records for the same space)

**Constraints Present In Schema**

- No constraint prevents overlapping active maintenance records for the same space

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple rows

**Recommended Correction**

- Enforce via exclusion constraint, trigger, or application logic during SQL implementation

---

#### BR-20

**Business Rule**

> Only users with an active account status may submit booking requests.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Booking.requester_id → User.account_status = 'active')

**Constraints Present In Schema**

- No constraint prevents a user with suspended account from being referenced as requester

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-21

**Business Rule**

> Only facility staff and facility managers may approve or reject booking requests.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Approval.approver_id → User.role IN ('facility_staff', 'facility_manager'))

**Constraints Present In Schema**

- No constraint restricts which user roles can be approvers

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-22

**Business Rule**

> Only facility staff may conduct check-in and check-out sessions.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Session.conductor_id → User.role = 'facility_staff')

**Constraints Present In Schema**

- No constraint restricts which user roles can be conductors

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-23

**Business Rule**

> Only facility staff may be assigned to handle maintenance records.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Maintenance_Record.assigned_staff_id → User.role = 'facility_staff')

**Constraints Present In Schema**

- No constraint restricts which user roles can be assigned staff

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-24

**Business Rule**

> A booking must have status pending before it can be reviewed for approval or rejection.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Approval.booking_id → Booking.status = 'pending')

**Constraints Present In Schema**

- No constraint prevents creating an approval for a booking that is not in pending status

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-25

**Business Rule**

> An approved booking transitions to checked_in when a session is started.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires workflow/state transition logic and cross-table validation

**Constraints Present In Schema**

- No constraint enforces the status transition or synchronizes Booking.status with Session existence

**Status**

- PASS

**Issue**

- This rule requires workflow or state transition logic

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-26

**Business Rule**

> A checked-in booking transitions to completed when the session is ended.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires workflow/state transition logic

**Constraints Present In Schema**

- No constraint enforces this transition

**Status**

- PASS

**Issue**

- This rule requires workflow or state transition logic

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-27

**Business Rule**

> A booking that is approved but never checked in by the requested end time transitions to no-show.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires temporal monitoring and automatic updates

**Constraints Present In Schema**

- No constraint can automatically detect time-expired bookings

**Status**

- PASS

**Issue**

- This rule requires automatic updates and temporal monitoring

**Recommended Correction**

- Enforce via scheduled job, trigger, or application logic during SQL implementation

---

#### BR-28

**Business Rule**

> An approved booking requires an associated approval record with decision approved.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Booking.status = 'approved' ↔ Approval.decision = 'approved')

**Constraints Present In Schema**

- No constraint synchronizes Booking.status with Approval.decision

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-29

**Business Rule**

> A rejected booking requires an associated approval record with decision rejected and a rejection reason.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation and conditional NOT NULL on rejection_reason

**Constraints Present In Schema**

- No constraint enforces that rejection requires a reason or synchronizes Booking.status with Approval.decision

**Status**

- PASS

**Issue**

- This rule requires validation involving another table and multiple attributes of a tuple

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-30

**Business Rule**

> A checked-in booking requires a session with actual start time and initial condition.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Booking.status ↔ Session.actual_start_time and Session.initial_condition)

**Constraints Present In Schema**

- No constraint enforces that checked-in bookings have corresponding session data

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-31

**Business Rule**

> A completed booking requires a session with actual end time, final condition, and usage notes.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation and conditional NOT NULL

**Constraints Present In Schema**

- No constraint enforces this semantic dependency

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-32

**Business Rule**

> A space with status under_maintenance, temporarily_closed, or retired cannot be booked.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Booking.space_code → Space.status NOT IN ('under_maintenance', 'temporarily_closed', 'retired'))

**Constraints Present In Schema**

- No constraint prevents booking spaces with disallowed statuses

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-33

**Business Rule**

> A maintenance record with status reported or in_progress prevents the related space from being booked.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires multi-table, multi-row validation (Booking.space_code referenced in Maintenance_Record with status in ('reported', 'in_progress'))

**Constraints Present In Schema**

- No constraint prevents booking spaces with active maintenance records

**Status**

- PASS

**Issue**

- This rule requires validation involving another table and multiple rows

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-34

**Business Rule**

> A completed maintenance record requires completion time and result note.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires tuple-based CHECK constraint (IF status = 'completed' THEN completion_time IS NOT NULL AND result_note IS NOT NULL)

**Constraints Present In Schema**

- completion_time and result_note are nullable; no constraint enforces conditional NOT NULL

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple attributes of a tuple

**Recommended Correction**

- Enforce via tuple-based CHECK constraint or trigger during SQL implementation

---

#### BR-35

**Business Rule**

> Requested start time must occur before requested end time.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires tuple-based CHECK constraint (requested_start_time < requested_end_time)

**Constraints Present In Schema**

- No constraint enforces temporal ordering

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple attributes of a tuple

**Recommended Correction**

- Enforce via tuple-based CHECK constraint during SQL implementation

---

#### BR-36

**Business Rule**

> Booking requests must have a requested start time in the future.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires CHECK constraint referencing current time (system function), which is not supported by logical-schema-level constraints

**Constraints Present In Schema**

- No constraint enforces future start time

**Status**

- PASS

**Issue**

- This rule requires a CHECK constraint with system function (GETDATE()), which goes beyond attribute-based CHECK

**Recommended Correction**

- Enforce via CHECK constraint with GETDATE() in SQL implementation or via application logic

---

#### BR-37

**Business Rule**

> Approval decision time must occur before the booking requested start time.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Approval.decision_time < Booking.requested_start_time)

**Constraints Present In Schema**

- No constraint enforces this temporal relationship across tables

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-38

**Business Rule**

> Actual start time must occur before actual end time.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires tuple-based CHECK constraint (actual_start_time < actual_end_time)

**Constraints Present In Schema**

- No constraint enforces temporal ordering

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple attributes of a tuple

**Recommended Correction**

- Enforce via tuple-based CHECK constraint during SQL implementation

---

#### BR-39

**Business Rule**

> Completion time must occur after start time for completed maintenance records.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires tuple-based CHECK constraint (IF status = 'completed' THEN completion_time > start_time)

**Constraints Present In Schema**

- No constraint enforces this temporal ordering

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple attributes of a tuple

**Recommended Correction**

- Enforce via tuple-based CHECK constraint or trigger during SQL implementation

---

#### BR-40

**Business Rule**

> Expected participants must not exceed the reserved space capacity.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires cross-table validation (Booking.expected_participants <= Space.capacity)

**Constraints Present In Schema**

- No constraint enforces participant limit against space capacity

**Status**

- PASS

**Issue**

- This rule requires validation involving another table beyond foreign keys

**Recommended Correction**

- Enforce via trigger or application logic during SQL implementation

---

#### BR-41

**Business Rule**

> Rejection reason must be provided when an approval decision is rejected.

**Can Be Enforced Using Logical-Schema-Level Constraints?**

- No

**Required Constraints**

- N/A — Requires tuple-based CHECK constraint (IF decision = 'rejected' THEN rejection_reason IS NOT NULL)

**Constraints Present In Schema**

- rejection_reason is nullable; no constraint enforces conditional NOT NULL

**Status**

- PASS

**Issue**

- This rule requires validation involving multiple attributes of a tuple

**Recommended Correction**

- Enforce via tuple-based CHECK constraint during SQL implementation

---

### Business Rule Enforcement Summary

| Category | Count |
|----------|-------|
| Enforceable via logical-schema-level constraints | 12 (BR-01 to BR-05, BR-07 to BR-12, BR-15 to BR-17) |
| Not enforceable via logical-schema-level constraints | 29 (BR-06, BR-13, BR-14, BR-18 to BR-41) |

---

# Issues List

## Critical Issues

| ID | Category | Description | Recommended Correction |
|----|----------|-------------|-----------------------|
| — | — | None identified | — |

## Minor Issues

| ID | Category | Description | Recommended Correction |
|----|----------|-------------|-----------------------|
| M-01 | Domain Constraints | Enumeration value sets for role, space_type, status, purpose, decision attributes are documented conceptually but not explicitly defined as CHECK constraints in the logical schema | Define explicit CHECK constraints during SQL implementation to enforce valid value ranges |
| M-02 | Business Rules | 29 of 41 business rules (70.7%) are not enforceable using logical-schema-level constraints alone | These rules must be enforced via triggers, application logic, exclusion constraints, or scheduled jobs during implementation |
| M-03 | Temporal Rules | Temporal ordering rules (BR-35, BR-38, BR-39) cannot be enforced at logical-schema level | Implement tuple-based CHECK constraints during SQL implementation where supported |
| M-04 | Lifecycle Rules | Booking status lifecycle transitions (BR-24 to BR-31) cannot be enforced at logical-schema level | Implement triggers or state machine logic during SQL implementation |

---

# Final Verdict

## 1. ERD to Relational Schema Compatibility

PASS

### Explanation

- All 7 ERD entities are correctly mapped to 8 relations (including one associative relation).
- All attributes are present; the composite attribute full_name is decomposed per Rule 8.
- All 10 relationships are correctly represented using appropriate mapping rules (Rule 3 for 1:1, Rule 4 for 1:N, Rule 5 for M:N).
- All primary keys, candidate keys, and foreign keys are correctly identified.
- No unnecessary relations or missing entities/relationships.
- Entity integrity, referential integrity, and key constraints are correctly defined.
- Special constructs (composite attributes) are handled correctly.

## 2. Business Rule Enforcement

PASS

### Explanation

- 12 of 41 business rules are directly enforceable using logical-schema-level constraints (NOT NULL, UNIQUE, FK, PK).
- The remaining 29 rules involve cross-table validation, multi-row validation, tuple-based validation, workflow logic, temporal monitoring, or automatic updates — all of which are explicitly outside the scope of logical-schema-level constraints per the validation rules.
- No business rule is violated by the schema; all non-enforceable rules require implementation-stage mechanisms (triggers, application logic, exclusion constraints, scheduled jobs).
- The schema provides the correct foundational structure (tables, keys, FKs, NOT NULL constraints) to support enforcement of all business rules at the implementation stage.

---

## Conclusion

### Compatible Mapping

- Yes

### All Enforceable Business Rules Satisfied

- Yes

### Overall Result

- ACCEPTABLE
