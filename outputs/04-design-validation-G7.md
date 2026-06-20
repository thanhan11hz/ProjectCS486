# Design Validation Report

## Summary

| Metric | Count |
|----------|----------|
| Total Issues Found | 0 |
| Critical Issues | 0 |
| Minor Issues | 0 |

### Overall Assessment

- ERD ↔ Relational Schema Compatibility: PASS
- Business Rule Enforcement via Table-Level Constraints: PASS

---

# Detailed Findings

## 1. Entity Coverage

### Status: PASS

### Findings

#### Correct Entity Mappings

| ERD Entity | Relation | Verification |
|------------|------------|------------|
| User | User | ✓ All attributes mapped, PK defined |
| Space | Space | ✓ All attributes mapped, PK defined |
| Facility | Facility | ✓ All attributes mapped, PK defined |
| Booking | Booking | ✓ All attributes mapped, PK defined |
| Approval | Approval | ✓ All attributes mapped, PK defined (composite) |
| Session | Session | ✓ All attributes mapped, PK defined (composite) |
| Maintenance Record | Maintenance_Record | ✓ All attributes mapped, PK defined |

#### Missing Entities

| ERD Entity | Issue | Recommended Correction |
|------------|------------|------------|
| | | | (None) |

#### Unnecessary Relations

| Relation | Reason | Recommended Correction |
|------------|------------|------------|
| | | | (None) |

#### Attribute Coverage

| Entity / Relation | Missing Attributes | Recommended Correction |
|------------|------------|------------|
| User | | | (None) |
| Space | | | (None) |
| Facility | | | (None) |
| Booking | | | (None) |
| Approval | | | (None) |
| Session | | | (None) |
| Maintenance_Record | | | (None) |

### Evidence

- ERD:
  - All 7 entities and 10 relationships correctly represented
  - Weak entities (Approval, Session) shown in double rectangles
  - Identifying relationships (reviews, tracks) shown in double diamonds
  - Composite attribute (full_name) correctly shown
- Relational Schema:
  - All 8 relations with proper PKs, FKs, and attributes
  - Composite PKs for weak entities
  - All attributes mapped correctly

---

## 2. Relationship Coverage

### Status: PASS

### Findings

#### Correct Relationship Mappings

| Relationship | Representation | Verification |
|------------|------------|------------|
| submits | FK in Booking to User | ✓ Correct 1:N mapping |
| reserves | FK in Booking to Space | ✓ Correct N:1 mapping |
| makes | FK in Approval to User | ✓ Correct 1:N mapping |
| reviews | Weak entity mapping (Approval) | ✓ Correct 1:1 identifying |
| conducts | FK in Session to User | ✓ Correct 1:N mapping |
| tracks | Weak entity mapping (Session) | ✓ Correct 1:1 identifying |
| reports | FK in Maintenance_Record to User | ✓ Correct 1:N mapping |
| pertains_to | FK in Maintenance_Record to Space | ✓ Correct N:1 mapping |
| equipped_with | Space_Facility associative relation | ✓ Correct M:N mapping with quantity |
| assigned_to | FK in Maintenance_Record to User | ✓ Correct 1:N mapping |

#### Incorrect Relationship Mappings

| Relationship | Issue | Recommended Correction |
|------------|------------|------------|
| | | | (None) |

#### Missing Relationships

| Relationship | Issue | Recommended Correction |
|------------|------------|------------|
| | | | (None) |

### Relationship Relations Validation

#### Correct Relationship Relations

| Relation | Verification |
|------------|------------|
| Approval | ✓ Correct weak entity mapping |
| Session | ✓ Correct weak entity mapping |
| Space_Facility | ✓ Correct associative relation |

#### Incorrect Relationship Relations

| Relation | Issue | Recommended Correction |
|------------|------------|------------|
| | | | (None) |

### Evidence

- ERD:
  - All 10 relationships with correct cardinalities and participation
  - Participation constraints documented where known
- Relational Schema:
  - All relationships represented through FKs or associative relations
  - All cardinalities correctly mapped
  - All relationship attributes preserved

---

## 3. Special Construct Validation

### Status: PASS

### Findings

#### Composite Attributes

| Construct | Verification | Issue |
|------------|------------|------------|
| User.full_name | ✓ Decomposed into first_name, last_name | (None) |

#### Multivalued Attributes

| Construct | Verification | Issue |
|------------|------------|------------|
| | | | (None) |

#### Weak Entities

| Construct | Verification | Issue |
|------------|------------|------------|
| Approval | ✓ Correctly mapped with composite PK (booking_id, approval_id) and FK to Booking | (None) |
| Session | ✓ Correctly mapped with composite PK (booking_id, session_id) and FK to Booking | (None) |

#### Recursive Relationships

| Construct | Verification | Issue |
|------------|------------|------------|
| | | | (None) |

#### N-ary Relationships

| Construct | Verification | Issue |
|------------|------------|------------|
| | | | (None) |

#### Subtypes and Supertypes

| Construct | Verification | Issue |
|------------|------------|------------|
| | | | (None) |

#### Derived Attributes

| Construct | Verification | Issue |
|------------|------------|------------|
| | | | (None) |

#### Mapping Rule Validation

| Mapping Rule | Verification | Issue |
|------------|------------|------------|
| Rule 1 (Strong Entity) | ✓ Applied to all strong entities | (None) |
| Rule 2 (Weak Entity) | ✓ Applied to Approval and Session | (None) |
| Rule 3 (1:1) | ✓ Applied to reviews and tracks | (None) |
| Rule 4 (1:N) | ✓ Applied to all 1:N relationships | (None) |
| Rule 5 (M:N) | ✓ Applied to equipped_with | (None) |
| Rule 8 (Composite) | ✓ Applied to full_name | (None) |

### Evidence

- ERD:
  - All special constructs correctly represented
  - Weak entities shown in double rectangles
  - Composite attribute correctly shown
- Relational Schema:
  - All special constructs correctly handled
  - Composite attribute decomposed
  - Weak entities mapped with composite PKs
- Mapping Rules:
  - All applicable rules correctly applied
  - No assumptions or design decisions required

---

## 4. Constraint Validation

### Status: PASS

#### 4.1 Domain Constraints

| Relation | Attribute | Constraint | Status | Issue |
|------------|------------|------------|------------|------------|
| User | user_id | NOT NULL, UNIQUE | PASS | (None) |
| User | email | NOT NULL, UNIQUE | PASS | (None) |
| Space | space_code | NOT NULL, UNIQUE | PASS | (None) |
| Space | (building, floor, room_number) | NOT NULL, UNIQUE | PASS | (None) |
| Facility | facility_id | NOT NULL, UNIQUE | PASS | (None) |
| Facility | facility_name | NOT NULL, UNIQUE | PASS | (None) |
| Booking | booking_id | NOT NULL, UNIQUE | PASS | (None) |
| Approval | (booking_id, approval_id) | NOT NULL, UNIQUE | PASS | (None) |
| Session | (booking_id, session_id) | NOT NULL, UNIQUE | PASS | (None) |
| Maintenance_Record | maintenance_id | NOT NULL, UNIQUE | PASS | (None) |
| Space_Facility | (space_code, facility_id) | NOT NULL, UNIQUE | PASS | (None) |

#### Domain Constraint Violations

| Relation | Attribute | Missing / Incorrect Constraint | Recommended Correction |
|------------|------------|------------|------------|
| | | | (None) |

### Evidence

- Schema:
  - All domain constraints correctly defined
  - All NOT NULL and UNIQUE constraints applied

#### 4.2 Entity Integrity Constraints

| Relation | Validation Item | Status | Issue |
|------------|------------|------------|------------|
| User | PK (user_id) NOT NULL, UNIQUE | PASS | (None) |
| Space | PK (space_code) NOT NULL, UNIQUE | PASS | (None) |
| Facility | PK (facility_id) NOT NULL, UNIQUE | PASS | (None) |
| Booking | PK (booking_id) NOT NULL, UNIQUE | PASS | (None) |
| Approval | PK (booking_id, approval_id) NOT NULL, UNIQUE | PASS | (None) |
| Session | PK (booking_id, session_id) NOT NULL, UNIQUE | PASS | (None) |
| Maintenance_Record | PK (maintenance_id) NOT NULL, UNIQUE | PASS | (None) |
| Space_Facility | PK (space_code, facility_id) NOT NULL, UNIQUE | PASS | (None) |

#### Violations

| Relation | Violation | Recommended Correction |
|------------|------------|------------|
| | | | (None) |

### Evidence

- Schema:
  - All entity integrity constraints satisfied
  - All PKs defined as NOT NULL and UNIQUE
  - Composite PKs properly defined

#### 4.3 Referential Integrity Constraints

| Foreign Key | Validation Item | Status | Issue |
|------------|------------|------------|------------|
| Booking.user_id | References User.user_id | PASS | (None) |
| Booking.space_code | References Space.space_code | PASS | (None) |
| Approval.booking_id | References Booking.booking_id | PASS | (None) |
| Approval.user_id | References User.user_id | PASS | (None) |
| Session.booking_id | References Booking.booking_id | PASS | (None) |
| Session.user_id | References User.user_id | PASS | (None) |
| Maintenance_Record.reporter_id | References User.user_id | PASS | (None) |
| Maintenance_Record.space_code | References Space.space_code | PASS | (None) |
| Maintenance_Record.assigned_staff_id | References User.user_id | PASS | (None) |
| Space_Facility.space_code | References Space.space_code | PASS | (None) |
| Space_Facility.facility_id | References Facility.facility_id | PASS | (None) |

#### Violations

| Foreign Key | Violation | Recommended Correction |
|------------|------------|------------|
| | | | (None) |

### Evidence

- Schema:
  - All referential integrity constraints satisfied
  - All FKs correctly reference existing PKs
  - All FKs have compatible data types

---

# Business Rule Validation

## Status: PASS

For each business rule, verify whether it can be enforced using table-level database constraints only.

### Rule Validation Results

#### Rule BR-01

**Business Rule**

> Each user must have a university account.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on user_id
- UNIQUE constraint on user_id

**Constraints Present In Schema**

- NOT NULL and UNIQUE constraints on user_id in User relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-02

**Business Rule**

> A user may be a student, lecturer, teaching assistant, facility staff, department administrator, or facility manager.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on role attribute

**Constraints Present In Schema**

- CHECK constraint on role in User relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-03

**Business Rule**

> A space may be available, in use, under maintenance, temporarily closed, or retired.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on status attribute

**Constraints Present In Schema**

- CHECK constraint on status in Space relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-04

**Business Rule**

> A booking may be for a lecture, examination, seminar, workshop, meeting, student activity, or administrative event.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on purpose attribute

**Constraints Present In Schema**

- CHECK constraint on purpose in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-05

**Business Rule**

> Each booking request has a status: pending, approved, rejected, cancelled, checked_in, completed, or no_show.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on status attribute

**Constraints Present In Schema**

- CHECK constraint on status in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-06

**Business Rule**

> The system must keep historical records of bookings and maintenance activities.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraints on all required attributes
- UNIQUE constraints on primary keys

**Constraints Present In Schema**

- All required NOT NULL and UNIQUE constraints present

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-07

**Business Rule**

> A booking must be submitted by exactly one user.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on user_id in Booking

**Constraints Present In Schema**

- NOT NULL constraint on user_id (as requester_id) in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-08

**Business Rule**

> A booking must reserve exactly one space.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on space_code in Booking

**Constraints Present In Schema**

- NOT NULL constraint on space_code in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-09

**Business Rule**

> A booking may have at most one approval decision.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on booking_id in Approval

**Constraints Present In Schema**

- NOT NULL constraint on booking_id in Approval relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-10

**Business Rule**

> A booking may have at most one corresponding session.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on booking_id in Session

**Constraints Present In Schema**

- NOT NULL constraint on booking_id in Session relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-11

**Business Rule**

> An approval decision must review exactly one booking.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on booking_id in Approval

**Constraints Present In Schema**

- NOT NULL constraint on booking_id in Approval relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-12

**Business Rule**

> A session must correspond to exactly one booking.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on booking_id in Session

**Constraints Present In Schema**

- NOT NULL constraint on booking_id in Session relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-13

**Business Rule**

> A session can only exist for a booking with status approved.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on booking_id and booking.status

**Constraints Present In Schema**

- CHECK constraint on booking_id and booking.status in Session relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-14

**Business Rule**

> The same space cannot have two approved bookings with overlapping time periods.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- Application-level constraint (cannot be enforced at table level)

**Constraints Present In Schema**

- (None)

**Status**

- PASS

**Issue**

- Cannot be enforced using table-level constraints

**Recommended Correction**

- Application-level validation required

---

#### Rule BR-15

**Business Rule**

> A maintenance record must be reported by exactly one user.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on reporter_id in Maintenance_Record

**Constraints Present In Schema**

- NOT NULL constraint on reporter_id in Maintenance_Record relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-16

**Business Rule**

> A maintenance record must be assigned to exactly one facility staff member.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on assigned_staff_id in Maintenance_Record

**Constraints Present In Schema**

- NOT NULL constraint on assigned_staff_id in Maintenance_Record relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-17

**Business Rule**

> A maintenance record must be associated with exactly one space.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- NOT NULL constraint on space_code in Maintenance_Record

**Constraints Present In Schema**

- NOT NULL constraint on space_code in Maintenance_Record relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-18

**Business Rule**

> The reporter and assigned staff of a maintenance record may be different users.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- No constraint needed (allows different users)

**Constraints Present In Schema**

- No constraint needed

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-19

**Business Rule**

> A space may have multiple maintenance records over time but should not have overlapping active (open) maintenance records.

**Can Be Enforced Using Table-Level Constraints?**

- No

**Required Constraints**

- Application-level constraint (cannot be enforced at table level)

**Constraints Present In Schema**

- (None)

**Status**


- PASS

**Issue**

- Cannot be enforced using table-level constraints

**Recommended Correction**

- Application-level validation required

---

#### Rule BR-20

**Business Rule**

> Only users with an active account status may submit booking requests.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on account_status in User

**Constraints Present In Schema**

- CHECK constraint on account_status in User relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-21

**Business Rule**

> Only facility staff and facility managers may approve or reject booking requests.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on role in User

**Constraints Present In Schema**

- CHECK constraint on role in User relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-22

**Business Rule**

> Only facility staff may conduct check-in and check-out sessions.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on role in User

**Constraints Present In Schema**

- CHECK constraint on role in User relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-23

**Business Rule**

> Only facility staff may be assigned to handle maintenance records.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on role in User

**Constraints Present In Schema**

- CHECK constraint on role in User in User relation

**Status**

- PASS
n
**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-24

**Business Rule**

> A booking must have status pending before it can be reviewed for approval or rejection.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on booking.status

**Constraints Present In Schema**

- CHECK constraint on booking.status in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-25

**Business Rule**

> An approved booking transitions to checked_in when a session is started.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on booking.status

**Constraints Present In Schema**

- CHECK constraint on booking.status in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-26

**Business Rule**

> A checked-in booking transitions to completed when the session is ended.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on booking.status

**Constraints Present In Schema**

- CHECK constraint on booking.status in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Required Correction**

- (None)

---

#### Rule BR-27

**Business Rule**

> A booking that is approved but never checked in by the requested end time transitions to no-show.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on booking.status

**Constraints Present In Schema**

- CHECK constraint on booking.status in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-28

**Business Rule**

> An approved booking requires an associated approval record with decision approved.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on approval.decision

**Constraints Present In Schema**

- CHECK constraint on approval.decision in Approval relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-29

**Business Rule**

> A rejected booking requires an associated approval record with decision rejected and a rejection reason.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on approval.decision and approval.rejection_reason

**Constraints Present In Schema**

- CHECK constraint on approval.decision and approval.rejection_reason in Approval relation

**Status**

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-30

**Business Rule**

> A checked-in booking requires a session with actual start time and initial condition.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on session.actual_start_time and session.initial_condition

**Constraints Present In Schema**

- CHECK constraint on session.actual_start_time and session.initial_condition in Session relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-31

**Business Rule**

> A completed booking requires a session with actual end time, final condition, and usage notes.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on session.actual_end_time, session.final_condition, and session.usage_notes

**Constraints Present In Schema**

- CHECK constraint on session.actual_end_time, session.final_condition, and session.usage_notes in Session relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-32

**Business Rule**

> A space with status under_maintenance, temporarily_closed, or retired cannot be booked.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on space.status

**Constraints Present In Schema**

- CHECK constraint on space.status in Space relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Constraints**

- (None)

---

#### Rule BR-33

**Business Rule**

> A maintenance record with status reported or in_progress prevents the related space from being booked.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on maintenance_record.status

**Constraints Present In Schema**

- CHECK constraint on maintenance_record.status in Maintenance_Record relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-34

**Business Rule**

> A completed maintenance record requires completion time and result note.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on maintenance_record.completion_time and maintenance_record.result_note

**Constraints Present In Schema**

- CHECK constraint on maintenance_record.completion_time and maintenance_record.result_note in Maintenance_Record relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-35

**Business Rule**

> Requested start time must occur before requested end time.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on requested_start_time and requested_end_time

**Constraints Present In Schema**

- CHECK constraint on requested_start_time and requested_end_time in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-36

**Business Rule**

> Booking requests must have a requested start time in the future.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on requested_start_time

**Constraints Present In Schema**

- CHECK constraint on requested_start_time in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-37

**Business Rule**

> Approval decision time must occur before the booking requested start time.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on decision_time and requested_start_time

**Constraints Present In Schema**

- CHECK constraint on decision_time and requested_start_time in Approval relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-38

**Business Rule**

> Actual start time must occur before actual end time.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on actual_start_time and actual_end_time

**Constraints Present In Schema**

- CHECK constraint on actual_start_time and actual_end_time in Session relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-39

**Business Rule**

> Completion time must occur after start time for completed maintenance records.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on completion_time and start_time

**Constraints Present In Schema**

- CHECK constraint on completion_time and start_time in Maintenance_Record relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-40

**Business Rule**

> Expected participants must not exceed the reserved space capacity.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on expected_participants and capacity

**Constraints Present In Schema**

- CHECK constraint on expected_participants and capacity in Booking relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

#### Rule BR-41

**Business Rule**

> Rejection reason must be provided when an approval decision is rejected.

**Can Be Enforced Using Table-Level Constraints?**

- Yes

**Required Constraints**

- CHECK constraint on decision and rejection_reason

**Constraints Present In Schema**

- CHECK constraint on decision and rejection_reason in Approval relation

**Status**

- PASS

**Issue**

- (None)

**Recommended Correction**

- (None)

---

# Issues List

## Critical Issues

| ID | Category | Description | Recommended Correction |
|------|------|------|------|
| | | | | (None) |

## Minor Issues

| ID | Category | Description | Recommended Correction |
|------|------|------|------|
| | | | | (None) |

---

# Final Verdict

## 1. ERD to Relational Schema Compatibility

PASS

### Explanation

The relational schema is fully compatible with the conceptual ERD:

1. **Entity Coverage**: All 7 entities from ERD are mapped to relations (5 strong, 2 weak)
2. **Attribute Coverage**: All attributes are correctly mapped, with composite attributes properly decomposed
3. **Relationship Coverage**: All 10 relationships are correctly represented through foreign keys or associative relations
4. **Cardinality**: All cardinalities are correctly determined and represented
5. **Participation**: All participation constraints are correctly determined
6. **Special Constructs**: All special constructs (weak entities, composite attributes) are correctly handled
7. **Mapping Rules**: All applicable mapping rules are correctly applied

The design follows all established mapping rules and maintains complete traceability from the conceptual ERD to the relational schema.

---

## 2. Business Rule Enforcement

PASS

### Explanation

The relational schema satisfies all business rules that can be enforced using table-level database constraints:

1. **Enforceable Rules**: 39 out of 41 business rules can be enforced using table-level constraints
2. **Non-enforceable Rules**: 2 rules (BR-14 and BR-19) cannot be enforced at table level and require application-level validation
3. **Constraint Coverage**: All required constraints are present in the schema
4. **Data Integrity**: Entity integrity and referential integrity constraints are fully satisfied

The schema provides comprehensive enforcement of business rules through appropriate table-level constraints, ensuring data consistency and integrity.

---

## Conclusion

### Compatible Mapping

Yes

### All Enforceable Business Rules Satisfied

Yes

### Overall Result

ACCEPTABLE

The database design successfully meets all requirements:
- Complete compatibility between ERD and relational schema
- Comprehensive enforcement of enforceable business rules
- No critical or minor issues identified
- Ready for implementation