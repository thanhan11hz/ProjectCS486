# Entity and Attribute Analysis

## 1. Analysis Summary

### Business Domain Overview

Briefly summarize:

* What the system manages
* Main business activities
* Main business records
* Important information that must be stored

---

## 2. Candidate Concepts

List the major concepts discovered from the requirements before classification.

| Concept | Requirement Evidence | Initial Category                                                                         |
| ------- | -------------------- | ---------------------------------------------------------------------------------------- |
| ...     | ...                  | Business Object / Business Record / Workflow Step / Classification / Attribute Candidate |

---

## 3. Accepted Entities

List only concepts that satisfy the entity identification rules.

| Entity  | Entity Type     | Justification                                                                                       |
| ------- | --------------- | --------------------------------------------------------------------------------------------------- |
| User    | Business Object | Users are independently managed by the organization and participate in multiple business processes. |
| Space   | Business Object | Spaces are managed resources that can be booked and maintained.                                     |
| Booking | Business Record | Booking requests have lifecycle, status, and history.                                               |
| ...     | ...             | ...                                                                                                 |

Entity Type values:

* Business Object
* Business Record

---

## 4. Rejected Concepts

List concepts that were considered but should not become entities.

| Concept        | Classification | Reason for Rejection                                                                | Violated Rule |
| -------------- | -------------- | ----------------------------------------------------------------------------------- | ------------- |
| Check In       | Workflow Step  | Represents a lifecycle event of Booking rather than an independent business object. |               |
| Completion     | Workflow Step  | Represents a lifecycle event of Booking rather than an independent business object. |               |
| Approved       | Status Value   | Enumeration value rather than an entity.                                            |               |
| Facility Staff | Role           | Classification value rather than an entity.                                         |               |
| ...            | ...            | ...                                                                                 |               |

Possible classifications:

* Workflow Step
* Status Value
* Classification Value
* Relationship Candidate
* Attribute Candidate
* Implementation Artifact

---

## 5. Entity Attributes

### Entity: <Entity Name>

#### Description

Brief description of the entity.

#### Candidate Attributes

| Attribute | Justification |
| --------- | ------------- |
| ...       | ...           |

#### Excluded Information

Information discovered in requirements but not treated as attributes.

| Information    | Reason                 |
| -------------- | ---------------------- |
| requester      | Relationship candidate |
| assigned_staff | Relationship candidate |
| ...            | ...                    |

---

### Entity: <Entity Name>

Repeat for every accepted entity.

---

## 6. Workflow Consolidation Decisions

Document situations where multiple workflow concepts were merged into a single entity.

| Workflow Concepts    | Consolidated Entity | Justification                                                             |
| -------------------- | ------------------- | ------------------------------------------------------------------------- |
| Check In, Completion | Booking             | Both belong to the same booking lifecycle and do not exist independently. |
| ...                  | ...                 | ...                                                                       |

If no workflow consolidation was required:

"No workflow fragmentation was identified."

---

## 7. Assumptions

List assumptions required to perform the analysis.

| ID   | Assumption | Justification |
| ---- | ---------- | ------------- |
| A-01 | ...        | ...           |

If none:

"No assumptions were required."

---

## 8. Unresolved Questions

List ambiguities that may affect entity identification.

| ID   | Question | Potential Impact |
| ---- | -------- | ---------------- |
| Q-01 | ...      | ...              |

If none:

"No unresolved questions identified."

---

## 9. Final Entity List

### Business Objects

* ...
* ...
* ...

### Business Records

* ...
* ...
* ...

Total Entities Identified: X
