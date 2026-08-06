# Updated ERD and Logical Design

# 1. Design Change Summary

Summarize all design changes introduced in this phase.

| Design Element | Action | Related Requirement | Description |
| -------------- | ------ | ------------------- | ----------- |
|                | Added / Modified / Removed / No Change | | |

---

# 2. Design Decisions

Document design decisions that are not uniquely determined by the business requirements.

| ID | Design Decision | Alternatives Considered | Rationale |
| -- | --------------- | ----------------------- | --------- |
| DD-01 | | | |

---

# 3. Updated Conceptual Design

## Conceptual Design Changes

Document only the conceptual model changes.

| Element | Action | Description |
| ------- | ------ | ----------- |
|         | Added / Modified / Removed / No Change | |

### Updated Conceptual ERD

> Insert the complete updated conceptual ERD (Mermaid Flowchart using Chen notation).

---

# 4. Updated Logical Design

## Logical Design Changes

Document only the logical model changes.

| Element | Action | Description |
| ------- | ------ | ----------- |
|         | Added / Modified / Removed / No Change | |

### Updated Relational Schema

```text
Relation_Name(
    attribute_1,
    attribute_2,
    ...
)
```

### Updated Logical Schema Diagram

> Insert the complete updated logical schema diagram (Crow's Foot notation).

---

# 5. Functional Dependency and Normalization Analysis

## 5.1 Functional Dependencies

For each relation, identify:

- Candidate Key(s)
- Primary Key
- Non-trivial Functional Dependencies

Example:

### Booking

**Candidate Key(s)**

- booking_id

**Functional Dependencies**

- booking_id → requester_id, space_id, start_time, end_time, status, ...

---

## 5.2 Normal Form Verification

For each relation, verify:

- First Normal Form (1NF)
- Second Normal Form (2NF)
- Third Normal Form (3NF)

Use the following table.

| Relation | Candidate Key(s) | Highest Normal Form | 3NF Status | Justification |
| -------- | ---------------- | ------------------- | ---------- | ------------- |
| Booking | booking_id | 3NF | ✓ | All non-key attributes depend only on the candidate key and no transitive dependency exists. |

If any relation does not satisfy 3NF, document:

- Violated Functional Dependency
- Cause of the violation
- Decomposition performed
- Resulting normalized relations

---

# 6. Traceability

Map each approved requirement change to the corresponding design changes.

| Requirement Change | Design Change |
| ------------------ | ------------- |
| RC-01 | DD-01 |

---

# 7. Assumptions

Record assumptions that influenced the design.

| ID | Assumption |
| -- | ---------- |
| A-01 | |

---

# 8. Summary

Briefly summarize:

- Major design changes.
- Key design decisions.
- Functional dependency and normalization results.
- Remaining assumptions.