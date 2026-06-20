# Design Validation Report

## Project Information

| Item                  | Value                                    |
| --------------------- | ---------------------------------------- |
| Business Requirements | `outputs/01-business-req-analysis-G7.md` |
| ERD Design            | `outputs/02-erd-design-G7.md`            |
| Relational Schema     | `outputs/03-logical-design-G7.md`        |
| Validation Report     | `outputs/04-design-validation-G7.md`     |

---

# Summary

## Overall Statistics

| Metric             | Count |
| ------------------ | ----- |
| Total Issues Found | 11    |
| Critical Issues    | 0     |
| Minor Issues       | 11    |

## Validation Results Overview

| Criterion                           | Status      |
| ----------------------------------- | ----------- |
| Entity Coverage                     | PASS        |
| Attribute Coverage                  | PASS        |
| Key Validation                      | PASS        |
| Relationship Coverage               | PASS        |
| Weak Entity Validation              | PASS        |
| Cardinality Validation              | PASS        |
| Participation Constraint Validation | PASS        |
| Constraint Validation               | FAIL        |
| Functional Dependency Validation    | PASS        |
| Business Rule Enforcement           | FAIL        |

---

# Detailed Findings

## 1. Entity Coverage

### Status

PASS

### Findings

| Entity | Present in Schema | Notes |
| ------ | ----------------- | ----- |
| User   | Yes               | Strong entity correctly mapped |
| Space  | Yes               | Strong entity correctly mapped |
| Facility | Yes            | Strong entity correctly mapped |
| Booking | Yes               | Strong entity correctly mapped |
| Approval | Yes              | Weak entity correctly mapped |
| Session | Yes               | Weak entity correctly mapped |
| Maintenance Record | Yes     | Strong entity correctly mapped |

### Evidence

#### ERD

```text
User, Space, Facility, Booking, Approval (weak), Session (weak), Maintenance Record
```

#### Relational Schema

```text
User, Space, Facility, Booking, Approval, Session, Maintenance_Record
```

### Issues Identified

* None

### Recommended Correction

* None

---

## 2. Attribute Coverage

### Status

PASS

### Findings

| Entity | Attribute | Present  | Notes |
| ------ | --------- | -------- | ----- |
| User   | user_id   | Yes      | Key attribute |
| User   | first_name | Yes     | Decomposed from full_name |
| User   | last_name | Yes      | Decomposed from full_name |
| User   | email     | Yes      | Candidate key |
| User   | phone_number | Yes   | |
| User   | role      | Yes      | |
| User   | department | Yes    | |
| User   | account_status | Yes | |
| Space  | space_code | Yes     | Key attribute |
| Space  | space_name | Yes     | |
| Space  | space_type | Yes      | |
| Space  | building | Yes        | |
| Space  | floor     | Yes        | |
| Space  | room_number | Yes    | |
| Space  | capacity | Yes         | |
| Space  | status    | Yes        | |
| Space  | usage_policy | Yes   | |
| Facility | facility_id | Yes  | Key attribute |
| Facility | facility_name | Yes | Candidate key |
| Facility | description | Yes | |
| Booking | booking_id | Yes     | Key attribute |
| Booking | requested_start_time | Yes | |
| Booking | requested_end_time | Yes | |
| Booking | purpose | Yes         | |
| Booking | expected_participants | Yes | |
| Booking | status | Yes           | |
| Approval | approval_id | Yes     | Partial key |
| Approval | decision | Yes          | |
| Approval | decision_time | Yes | |
| Approval | decision_note | Yes | |
| Approval | rejection_reason | Yes | |
| Session | session_id | Yes       | Partial key |
| Session | actual_start_time | Yes | |
| Session | actual_end_time | Yes | |
| Session | initial_condition | Yes | |
| Session | final_condition | Yes | |
| Session | usage_notes | Yes     | |
| Maintenance Record | maintenance_id | Yes | Key attribute |
| Maintenance Record | problem_description | Yes | |
| Maintenance Record | start_time | Yes          | |
| Maintenance Record | completion_time | Yes | |
| Maintenance Record | status | Yes            | |
| Maintenance Record | result_note | Yes     | |

### Evidence

#### ERD

```text
All attributes from ERD are present in the corresponding relations |
```

#### Relational Schema

```text
All attributes mapped correctly; full_name decomposed into first_name and last_name |
```

### Issues Identified

* None

### Recommended Correction

* None

---

## 3. Key Validation

### Status

PASS

### Findings

| Relation | Primary Key | Candidate Keys | Issues |
| -------- | ----------- | -------------- | ------ |
| User | user_id | email | None |
| Space | space_code | (building, floor, room_number) | None |
| Facility | facility_id | facility_name | None |
| Booking | booking_id | - | None |
| Approval | (booking_id, approval_id) | - | None |
| Session | (booking_id, session_id) | - | None |
| Maintenance_Record | maintenance_id | - | None |
| Space_Facility | (space_code, facility_id) | - | None |

### Verification

* Primary keys uniquely identify tuples. ✓
* Candidate keys preserved. ✓
* Alternate keys use UNIQUE constraints where required. ✓
* Composite keys correctly defined. ✓
* Weak entity keys correctly implemented. ✓

### Issues Identified

* None

### Recommended Correction

* None

---

## 4. Relationship Coverage

### Status

PASS

### Findings

| Relationship | Representation in Schema | Status      |
| ------------ | ------------------------ | ----------- |
| submits | user_id (requester_id) in Booking → User(user_id) | PASS |
| reserves | space_code in Booking → Space(space_code) | PASS |
| makes | user_id (approver_id) in Approval → User(user_id) | PASS |
| reviews | booking_id in Approval (FK+PK) → Booking(booking_id) | PASS |
| conducts | user_id (conductor_id) in Session → User(user_id) | PASS |
| tracks | booking_id in Session (FK+PK) → Booking(booking_id) | PASS |
| reports | user_id (reporter_id) in Maintenance_Record → User(user_id) | PASS |
| pertains_to | space_code in Maintenance_Record → Space(space_code) | PASS |
| equipped_with | Space_Facility associative relation | PASS |
| assigned_to | user_id (assigned_staff_id) in Maintenance_Record → User(user_id) | PASS |

### Evidence

#### ERD

```text
submits (User → Booking), reserves (Booking → Space), makes (User → Approval), reviews (Approval → Booking), conducts (User → Session), tracks (Session → Booking), reports (User → Maintenance Record), pertains_to (Maintenance Record → Space), equipped_with (Space ↔ Facility), assigned_to (User → Maintenance Record)
```

#### Relational Schema

```text
All 10 relationships represented with correct foreign key placement |
```

### Issues Identified

* None

### Recommended Correction

* None

---

## 5. Weak Entity Validation

### Status

PASS

### Findings

| Weak Entity | Owner Entity | Implementation Status |
| ----------- | ------------ | --------------------- |
| Approval | Booking | PASS |
| Session | Booking | PASS |

### Verification

* Weak entity relation exists. ✓
* Owner key included in primary key. ✓
* Identifying relationship preserved. ✓
* Foreign key correctly references owner. ✓

### Issues Identified

* None

### Recommended Correction

* None

---

## 6. Cardinality Validation

### Status

PASS

### Findings

| Relationship | ERD Cardinality | Schema Implementation | Status      |
| ------------ | --------------- | --------------------- | ----------- |
| submits | User 1 → Booking N | FK in Booking | PASS |
| reserves | Booking N → Space 1 | FK in Booking | PASS |
| makes | User 1 → Approval N | FK in Approval | PASS |
| reviews | Approval 1 → Booking 1 | FK in Approval (identifying) | PASS |
| conducts | User 1 → Session N | FK in Session | PASS |
| tracks | Session 1 → Booking 1 | FK in Session (identifying) | PASS |
| reports | User 1 → Maintenance Record N | FK in Maintenance_Record | PASS |
| pertains_to | Maintenance Record N → Space 1 | FK in Maintenance_Record | PASS |
| equipped_with | Space M ↔ Facility N | Space_Facility associative relation | PASS |
| assigned_to | User 1 → Maintenance Record N | FK in Maintenance_Record | PASS |

### Verification

#### One-to-One (1:1)

* reviews (Approval → Booking, identifying): ✓ Verified via weak entity mapping
* tracks (Session → Booking, identifying): ✓ Verified via weak entity mapping

#### One-to-Many (1:N)

* All 1:N relationships correctly mapped with FK on N-side. ✓ Verified

#### Many-to-Many (M:N)

* equipped_with (Space ↔ Facility): ✓ Verified via Space_Facility associative relation

### Issues Identified

* None

### Recommended Correction

* None

---

## 7. Participation Constraint Validation

### Status

PASS

### Findings

| Relationship | Participation        | Enforcement     | Status      |
| ------------ | -------------------- | --------------- | ----------- |
| submits | User: Optional, Booking: Mandatory | user_id NOT NULL in Booking | PASS |
| reserves | Booking: Mandatory, Space: Optional | space_code NOT NULL in Booking | PASS |
| makes | User: Optional, Approval: Mandatory | user_id NOT NULL in Approval | PASS |
| reviews | Approval: Mandatory, Booking: Optional | booking_id NOT NULL in Approval | PASS |
| conducts | User: Optional, Session: Mandatory | user_id NOT NULL in Session | PASS |
| tracks | Session: Mandatory, Booking: Optional | booking_id NOT NULL in Session | PASS |
| reports | User: Optional, Maintenance Record: Mandatory | user_id NOT NULL in Maintenance_Record | PASS |
| pertains_to | Maintenance Record: Mandatory, Space: Optional | space_code NOT NULL in Maintenance_Record | PASS |
| equipped_with | Space: Optional, Facility: Optional | No NOT NULL constraints (correct) | PASS |
| assigned_to | User: Optional, Maintenance Record: Mandatory | user_id NOT NULL in Maintenance_Record | PASS |

### Issues Identified

* None

### Recommended Correction

* None

---

## 8. Constraint Validation

### Status

FAIL

### Domain Constraints

| Constraint | Status      | Notes |
| ---------- | ----------- | ----- |
| All domain values valid | PASS | All enumerations and data types enforced |

### Entity Integrity

| Relation | Primary Key Valid | Notes |
| -------- | ----------------- | ----- |
| User | Yes | user_id PK NOT NULL |
| Space | Yes | space_code PK NOT NULL |
| Facility | Yes | facility_id PK NOT NULL |
| Booking | Yes | booking_id PK NOT NULL |
| Approval | Yes | (booking_id, approval_id) PK NOT NULL |
| Session | Yes | (booking_id, session_id) PK NOT NULL |
| Maintenance_Record | Yes | maintenance_id PK NOT NULL |
| Space_Facility | Yes | (space_code, facility_id) PK NOT NULL |

### Referential Integrity

| Foreign Key | References | Status      |
| ----------- | ---------- | ----------- |
| Booking.user_id | User.user_id | PASS |
| Booking.space_code | Space.space_code | PASS |
| Approval.booking_id | Booking.booking_id | PASS |
| Approval.user_id | User.user_id | PASS |
| Session.booking_id | Booking.booking_id | PASS |
| Session.user_id | User.user_id | PASS |
| Maintenance_Record.reporter_id | User.user_id | PASS |
| Maintenance_Record.space_code | Space.space_code | PASS |
| Maintenance_Record.assigned_staff_id | User.user_id | PASS |
| Space_Facility.space_code | Space.space_code | PASS |
| Space_Facility.facility_id | Facility.facility_id | PASS |

### Issues Identified

* Missing CHECK constraints for the following business rules:
  * BR-13: Session only for approved booking
  * BR-20: Active account for bookings
  * BR-29: Rejected booking requires rejection reason
  * BR-32: Unavailable spaces cannot be booked
  * BR-33: Active maintenance prevents booking
  * BR-34: Completed maintenance requires completion time
  * BR-35: Requested start before end
  * BR-38: Actual start before end
  * BR-39: Completion after start
  * BR-40: Expected participants ≤ capacity
  * BR-41: Rejection reason when rejected

### Recommended Correction

* Add CHECK constraints to enforce the above business rules

### Entity Integrity

| Relation | Primary Key Valid | Notes |
| -------- | ----------------- | ----- |
| User | Yes | user_id PK NOT NULL |
| Space | Yes | space_code PK NOT NULL |
| Facility | Yes | facility_id PK NOT NULL |
| Booking | Yes | booking_id PK NOT NULL |
| Approval | Yes | (booking_id, approval_id) PK NOT NULL |
| Session | Yes | (booking_id, session_id) PK NOT NULL |
| Maintenance_Record | Yes | maintenance_id PK NOT NULL |
| Space_Facility | Yes | (space_code, facility_id) PK NOT NULL |

### Referential Integrity

| Foreign Key | References | Status      |
| ----------- | ---------- | ----------- |
| Booking.user_id | User.user_id | PASS |
| Booking.space_code | Space.space_code | PASS |
| Approval.booking_id | Booking.booking_id | PASS |
| Approval.user_id | User.user_id | PASS |
| Session.booking_id | Booking.booking_id | PASS |
| Session.user_id | User.user_id | PASS |
| Maintenance_Record.reporter_id | User.user_id | PASS |
| Maintenance_Record.space_code | Space.space_code | PASS |
| Maintenance_Record.assigned_staff_id | User.user_id | PASS |
| Space_Facility.space_code | Space.space_code | PASS |
| Space_Facility.facility_id | Facility.facility_id | PASS |

### Issues Identified

* None

### Recommended Correction

* None

---

## 9. Functional Dependency Validation

### Status

PASS

### Findings

| Functional Dependency | Preserved | Notes |
| --------------------- | --------- | ----- |
| User.user_id → User attributes | Yes | Full key dependency |
| Space.space_code → Space attributes | Yes | Full key dependency |
| Facility.facility_id → Facility attributes | Yes | Full key dependency |
| Booking.booking_id → Booking attributes | Yes | Full key dependency |
| (Booking.booking_id, Approval.approval_id) → Approval attributes | Yes | Full key dependency |
| (Booking.booking_id, Session.session_id) → Session attributes | Yes | Full key dependency |
| Maintenance_Record.maintenance_id → Maintenance_Record attributes | Yes | Full key dependency |
| (Space_Facility.space_code, Space_Facility.facility_id) → quantity | Yes | Full key dependency |

### Verification

* Attributes depend on full key. ✓
* Partial dependencies avoided. ✓
* Transitive dependencies minimized. ✓
* Dependencies preserved after transformation. ✓

### Issues Identified

* None

### Recommended Correction

* None

---

## 10. Business Rule Enforcement

### Status

FAIL

### Rule Evaluation

| Business Rule | Enforceable by Table Constraints | Required Constraint(s) | Implemented | Notes |
| ------------- | -------------------------------- | ---------------------- | ----------- | ----- |
| BR-01 (User must have university account) | Yes | PRIMARY KEY on user_id | Yes | |
| BR-02 (User role enumeration) | Yes | ENUMERATION | Yes | |
| BR-03 (Space status enumeration) | Yes | ENUMERATION | Yes | |
| BR-04 (Booking purpose enumeration) | Yes | ENUMERATION | Yes | |
| BR-05 (Booking status enumeration) | Yes | ENUMERATION | Yes | |
| BR-06 (Historical records) | Yes | NOT NULL constraints | Yes | |
| BR-07 (Booking submitted by exactly one user) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-08 (Booking reserves exactly one space) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-09 (Booking has at most one approval) | Yes | UNIQUE constraint | Yes | |
| BR-10 (Booking has at most one session) | Yes | UNIQUE constraint | Yes | |
| BR-11 (Approval reviews exactly one booking) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-12 (Session corresponds to exactly one booking) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-13 (Session only for approved booking) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-14 (No overlapping bookings) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-15 (Maintenance record reported by exactly one user) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-16 (Maintenance record assigned to exactly one staff) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-17 (Maintenance record associated with exactly one space) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-18 (Reporter and assigned staff may differ) | Yes | No constraint needed | N/A | Allowed by schema |
| BR-19 (No overlapping active maintenance) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-20 (Active account for bookings) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-21 (Staff/manager for approvals) | Yes | ENUMERATION validation | Yes | |
| BR-22 (Staff for sessions) | Yes | ENUMERATION validation | Yes | |
| BR-23 (Staff for maintenance assignments) | Yes | ENUMERATION validation | Yes | |
| BR-24 (Booking must be pending before review) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-25 (Approved booking transitions to checked_in) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-26 (Checked-in transitions to completed) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-27 (Approved booking becomes no-show) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-28 (Approved booking requires approval record) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-29 (Rejected booking requires rejection reason) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-30 (Checked-in requires session) | Yes | FOREIGN KEY NOT NULL | Yes | |
| BR-31 (Completed requires session details) | Yes | NOT NULL constraints | Yes | |
| BR-32 (Unavailable spaces cannot be booked) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-33 (Active maintenance prevents booking) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-34 (Completed maintenance requires completion time) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-35 (Requested start before end) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-36 (Future booking requests) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-37 (Approval before booking start) | No | Application logic required | N/A | Cannot be enforced via table constraints |
| BR-38 (Actual start before end) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-39 (Completion after start) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-40 (Expected participants ≤ capacity) | Yes | CHECK constraint | No | Missing CHECK constraint |
| BR-41 (Rejection reason when rejected) | Yes | CHECK constraint | No | Missing CHECK constraint |

### Business Rules Requiring External Enforcement

| Rule | Reason                                                 |
| ---- | ------------------------------------------------------ |
| BR-14 | Overlapping booking detection requires complex temporal validation across multiple rows |
| BR-19 | Overlapping maintenance detection requires complex temporal validation across multiple rows |
| BR-24 | Booking status transition validation requires application logic |
| BR-25 | Booking status transition validation requires application logic |
| BR-26 | Booking status transition validation requires application logic |
| BR-27 | Booking status transition validation requires application logic |
| BR-36 | Future booking validation requires application logic |
| BR-37 | Approval timing validation requires application logic |

### Notes

Some business rules cannot be enforced solely through standard table constraints. Such limitations are not considered validation failures and should be documented separately.

### Recommended Correction

* Add missing CHECK constraints for BR-13, BR-20, BR-29, BR-32, BR-33, BR-34, BR-35, BR-38, BR-39, BR-40, BR-41
* Implement application logic for BR-14, BR-19, BR-24, BR-25, BR-26, BR-27, BR-36, BR-37

---

# Final Verdict

## Overall Assessment

### 1. Does the relational schema correctly represent the ERD?

PASS

Explanation:
The relational schema perfectly represents the ERD with all 7 entities (5 strong, 2 weak) and all 10 relationships correctly implemented. Weak entities (Approval and Session) are properly mapped with composite primary keys including their owner keys. The schema maintains all cardinalities and participation constraints from the ERD.

### 2. Are relationships and cardinalities preserved?

PASS

Explanation:
All 10 relationships from the ERD are correctly represented in the relational schema. One-to-one relationships (reviews, tracks) are implemented through weak entity mapping. One-to-many relationships are correctly implemented with foreign keys on the many side. The many-to-many relationship (equipped_with) is properly implemented using the Space_Facility associative relation with quantity attribute.

### 3. Are keys appropriately implemented?

PASS

Explanation:
All primary keys are correctly defined and uniquely identify tuples. Candidate keys are preserved where appropriate (User.email, Space (building, floor, room_number), Facility.facility_name). Weak entities are correctly implemented with composite primary keys that include both the owner key and their partial key.

### 4. Are constraints correctly defined?

FAIL

Explanation:
Entity integrity and referential integrity are correctly defined. However, there are 11 missing CHECK constraints that need to be added to enforce specific business rules. The schema has 15 business rules that can be enforced using table-level constraints (CHECK, PRIMARY KEY, FOREIGN KEY, NOT NULL, UNIQUE). 8 business rules require external enforcement due to complex logic involving temporal validation, status transitions, and cross-row comparisons. The schema provides a solid foundation for enforcing the majority of business rules, but 11 CHECK constraints are missing.

### 5. Are business rules adequately enforced?

FAIL

Explanation:
Only 15 business rules can be enforced using table-level constraints (CHECK, PRIMARY KEY, FOREIGN KEY, NOT NULL, UNIQUE). 26 business rules require external enforcement due to complex logic involving temporal validation, status transitions, and cross-row comparisons. The schema provides a solid foundation for enforcing the majority of business rules, but 11 CHECK constraints are missing that would increase the count to 26 enforceable business rules.

### 6. Is the schema suitable for implementation?

ACCEPTABLE WITH CORRECTIONS

Explanation:
The relational schema is well-designed and ready for implementation. It follows all normal forms, maintains referential integrity, and provides a clear structure for the campus space booking system. The design is scalable and can accommodate future enhancements while maintaining data integrity. However, 11 CHECK constraints need to be added to fully enforce all business rules that can be enforced using table-level constraints.

---

# Issues List

## Critical Issues

* None

## Minor Issues

| ID | Category | Description | Recommended Correction |
|------|------|------|------|
| M-01 | Constraint Validation | Missing CHECK constraint for BR-13 (Session only for approved booking) | Add CHECK constraint to ensure Session.booking_id only references Booking with status 'approved' |
| M-02 | Constraint Validation | Missing CHECK constraint for BR-20 (Active account for bookings) | Add CHECK constraint to ensure User.account_status = 'active' for booking submissions |
| M-03 | Constraint Validation | Missing CHECK constraint for BR-29 (Rejected booking requires rejection reason) | Add CHECK constraint to ensure Approval.rejection_reason is NOT NULL when decision = 'rejected' |
| M-04 | Constraint Validation | Missing CHECK constraint for BR-32 (Unavailable spaces cannot be booked) | Add CHECK constraint to ensure Booking.status is not 'under_maintenance', 'temporarily_closed', or 'retired' |
| M-05 | Constraint Validation | Missing CHECK constraint for BR-33 (Active maintenance prevents booking) | Add CHECK constraint to ensure Space.status is not 'under_maintenance' when Maintenance_Record.status in ('reported', 'in_progress') |
| M-06 | Constraint Validation | Missing CHECK constraint for BR-34 (Completed maintenance requires completion time) | Add CHECK constraint to ensure Maintenance_Record.completion_time is NOT NULL when status = 'completed' |
| M-07 | Constraint Validation | Missing CHECK constraint for BR-35 (Requested start before end) | Add CHECK constraint to ensure Booking.requested_start_time < Booking.requested_end_time |
| M-08 | Constraint Validation | Missing CHECK constraint for BR-38 (Actual start before end) | Add CHECK constraint to ensure Session.actual_start_time < Session.actual_end_time |
| M-09 | Constraint Validation | Missing CHECK constraint for BR-39 (Completion after start) | Add CHECK constraint to ensure Maintenance_Record.completion_time > Maintenance_Record.start_time |
| M-10 | Constraint Validation | Missing CHECK constraint for BR-40 (Expected participants ≤ capacity) | Add CHECK constraint to ensure Booking.expected_participants <= Space.capacity |
| M-11 | Constraint Validation | Missing CHECK constraint for BR-41 (Rejection reason when rejected) | Add CHECK constraint to ensure Approval.rejection_reason is NOT NULL when decision = 'rejected' |

---

# Conclusion

The design validation report confirms that the relational schema perfectly represents the ERD and meets most validation criteria. All entities, attributes, relationships, and constraints are correctly implemented. The schema is ready for implementation with only 8 business rules requiring external enforcement through application logic. However, 11 CHECK constraints need to be added to fully enforce all business rules that can be enforced using table-level constraints. The design provides a solid foundation for the campus space booking system, but requires minor corrections to achieve full compliance with business rule enforcement requirements.
