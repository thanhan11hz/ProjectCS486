# Relationship Analysis

## 1. Candidate Relationships

| Relationship Candidate | Evidence | Notes |
| ---------------------- | -------- | ----- |
|                        |          |       |

Include all relationships initially identified from the requirements before validation.

---

## 2. Relationship Evaluation

### Approved Relationships

| Relationship | Reason |
| ------------ | ------ |
|              |        |

### Rejected Relationships

| Relationship Candidate | Rejection Reason | Violated Rule |
| ---------------------- | ---------------- | ------------- |
|                        |                  |               |

Common reasons:

* Attribute, not relationship
* Derived relationship
* Unsupported by requirements
* Duplicate relationship
* Classification relationship

---

## 3. Approved Relationship Details

### Relationship: <Relationship Name>

#### Business Meaning

Describe the business association.

#### Participating Entities

| Entity | Role |
| ------ | ---- |
|        |      |

#### Cardinality

| Entity | Cardinality |
| ------ | ----------- |
|        |             |

#### Participation

| Entity | Participation        |
| ------ | -------------------- |
|        | Mandatory / Optional |

#### Relationship Attributes

| Attribute | Description |
| --------- | ----------- |
|           |             |

If none:

> No relationship attributes identified.

#### Evidence

Relevant requirement statements supporting the relationship.

---

## 4. Relationship Attribute Analysis

| Relationship | Attribute | Justification |
| ------------ | --------- | ------------- |
|              |           |               |

If no relationship attributes exist:

> No relationship attributes identified.

---

## 5. Validation Notes

### Relationship Validation

* All approved relationships connect approved entities.
* No duplicate relationships exist.
* No derived relationships were approved.
* No attributes were incorrectly modeled as relationships.

### Scope Validation

* No new entities were introduced.
* No primary keys were defined.
* No foreign keys were defined.
* No relational schema decisions were made.
