# Business Rules Analysis

## 1. Explicit Business Rules

Business rules stated directly in the requirements.

| ID      | Rule |
| ------- | ---- |
| BR-E001 |      |
| BR-E002 |      |

---

# 2. Entity-Based Rule Analysis

## Entity: <Entity Name>

### 2.1 Entity Attributes

| Attribute | Type | Description |
| --------- | ---- | ----------- |
|           |      |             |

---

### 2.2 Related Relationships

| Relationship | Related Entity |
| ------------ | -------------- |
|              |                |

---

### 2.3 Relationship Attributes

| Relationship | Attribute | Description |
| ------------ | --------- | ----------- |
|              |           |             |

---

### 2.4 Related Entity Attributes

Attributes belonging to connected entities that may influence this entity.

| Related Entity | Attribute | Description |
| -------------- | --------- | ----------- |
|                |           |             |

Examples:

* Space.Capacity
* Space.Status
* User.Role
* Maintenance.Status

---

### 2.5 Cross-Entity Constraint Analysis

Analyze constraints involving:

* Entity attributes
* Relationship attributes
* Related entity attributes

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
|                   |             |                |

Examples:

| Involved Elements                             | Observation              | Candidate Rule                                     |
| --------------------------------------------- | ------------------------ | -------------------------------------------------- |
| Booking.ExpectedParticipants + Space.Capacity | Capacity restriction     | Expected participants cannot exceed space capacity |
| Booking.RequestedTime + Space.Status          | Availability restriction | Space under maintenance cannot be booked           |

---

### 2.6 Temporal Constraint Analysis

Analyze all attributes representing:

* Date
* Time
* Lifecycle events

Include:

* Entity attributes
* Relationship attributes
* Related entity attributes when relevant

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
|                   |             |                |

---

### 2.7 Status-Based Constraint Analysis

For every status attribute.

Status attributes may belong to:

* Current entity
* Relationship attributes
* Related entities

#### Status Attribute: <Attribute Name>

| Status Value | Required Data | Restricted Data | Candidate Rule |
| ------------ | ------------- | --------------- | -------------- |
|              |               |                 |                |

---

### 2.8 Enumeration Constraint Analysis

For every enumeration attribute.

Enumeration attributes may belong to:

* Current entity
* Relationship attributes
* Related entities

#### Enumeration Attribute: <Attribute Name>

| Value | Impacted Elements | Candidate Rule |
| ----- | ----------------- | -------------- |
|       |                   |                |

---

### 2.9 Real-World Consistency Analysis

Analyze consistency constraints involving:

* Entity attributes
* Relationship attributes
* Related entity attributes

| Involved Elements | Observation | Candidate Rule |
| ----------------- | ----------- | -------------- |
|                   |             |                |

Examples:

* Expected Participants vs Space Capacity
* Actual Start Time vs Actual End Time
* Maintenance Start Time vs Completion Time

---

### 2.10 Relationship Constraint Analysis

#### Relationship: <Relationship Name>

##### Participating Entities

* Entity A
* Entity B

##### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
|           |             |

##### Participation Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
|             |                |

##### Dependency Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
|             |                |

##### Exclusivity Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
|             |                |

##### Instance-Level Constraints

| Observation | Candidate Rule |
| ----------- | -------------- |
|             |                |

Examples:

* Overlapping bookings
* One active maintenance per space
* One requester per booking

---

### 2.11 Entity Rule Candidates

All candidate rules derived from this entity.

| Candidate ID | Candidate Rule | Source Analysis |
| ------------ | -------------- | --------------- |
| C001         |                | Cross-Entity    |
| C002         |                | Temporal        |
| C003         |                | Status          |
| C004         |                | Enumeration     |
| C005         |                | Consistency     |
| C006         |                | Relationship    |

---

# 3. Rule Consolidation

## Duplicate Rules Removed

| Duplicate Rule | Retained Rule |
| -------------- | ------------- |
|                |               |

---

## Rule Merges

| Related Candidate Rules | Consolidated Rule |
| ----------------------- | ----------------- |
|                         |                   |

---

# 4. Final Business Rules

## Validation Rules

| ID      | Rule |
| ------- | ---- |
| BR-V001 |      |

---

## Permission Rules

| ID      | Rule |
| ------- | ---- |
| BR-P001 |      |

---

## Lifecycle Rules

| ID      | Rule |
| ------- | ---- |
| BR-L001 |      |

---

## Temporal Rules

| ID      | Rule |
| ------- | ---- |
| BR-T001 |      |

---

## State-Based Rules

| ID      | Rule |
| ------- | ---- |
| BR-S001 |      |

---

## Relationship Rules

| ID      | Rule |
| ------- | ---- |
| BR-R001 |      |

---

## Real-World Consistency Rules

| ID      | Rule |
| ------- | ---- |
| BR-C001 |      |

---

# 5. Rule Traceability Matrix

| Final Rule | Source Entity | Analysis Type | Source Elements                      |
| ---------- | ------------- | ------------- | ------------------------------------ |
| BR-T001    | Booking       | Temporal      | RequestedStartTime, RequestedEndTime |
| BR-R001    | Booking       | Relationship  | Booking, Space                       |
| BR-C001    | Booking       | Cross-Entity  | ExpectedParticipants, Space.Capacity |

---

# 6. Validation Checklist

* [ ] All explicit business rules captured
* [ ] All entities analyzed
* [ ] All relationships analyzed
* [ ] Related entity attributes analyzed
* [ ] Cross-entity constraints analyzed
* [ ] Temporal constraints analyzed
* [ ] Status constraints analyzed
* [ ] Enumeration constraints analyzed
* [ ] Consistency constraints analyzed
* [ ] Relationship constraints analyzed
* [ ] Duplicate rules removed
* [ ] All final rules traceable to source analysis