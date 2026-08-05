# Concurrency Design

# 1. Concurrency-Sensitive Business Rules

Identify every business rule that may be violated under concurrent execution.

| Business Rule | Description | Reason Concurrency Matters |
|----------------|-------------|----------------------------|
| BR-xx | ... | ... |
| BR-xx | ... | ... |

---

# 2. Concurrent Operations

Identify realistic operations that may execute simultaneously.

| Operation ID | Operation | Description |
|--------------|-----------|-------------|
| OP-01 | Create Booking | User submits a booking request |
| OP-02 | Approve Booking | Staff approves a booking |
| OP-03 | Escalate Maintenance | Staff changes maintenance to Out of Service |
| ... | ... | ... |

---

# 3. Concurrency Conflict Analysis

Each subsection describes one realistic concurrency conflict.

---

## CC-01 — <Conflict Title>

### Scenario

Describe the business scenario.

### Concurrent Operations

- Operation A
- Operation B

### Shared Business Resources

- Space
- Booking
- Maintenance Record
- etc.

### Business Rule(s) Affected

- BR-xx
- BR-xx

### Business Invariant

Describe the business invariant that must always hold.

### Conflict Explanation

Explain how concurrent execution may violate the business rule.

---

### Recommended SQL Server Concurrency Mechanism

Recommend only the mechanisms actually required.

Mechanisms only include:

- Isolation Level (if required)
- Locking Hint (if required)

Example:

- Isolation Level: READ COMMITTED
- Locking Hint: UPDLOCK + HOLDLOCK

or

- Locking Hint: UPDLOCK

or

- Isolation Level: SERIALIZABLE

If a mechanism is unnecessary, omit it instead of providing a placeholder.

---

### Justification

Explain:

- Why the selected mechanism prevents the conflict.
- Why weaker mechanisms (if any) are insufficient.
- Why stronger mechanisms are unnecessary (if applicable).
- Expected impact on concurrency and performance.

---

## CC-02 — <Conflict Title>

(Same structure)

---

## CC-03 — <Conflict Title>

(Same structure)

---

(Add additional conflicts as necessary.)

---

# 4. Concurrency Mechanism Summary

| Conflict | Business Rule(s) | Recommended Mechanism | Reason |
|-----------|------------------|-----------------------|--------|
| CC-01 | BR-xx | UPDLOCK + HOLDLOCK | Prevent check-then-act race on booking availability |
| CC-02 | BR-xx | UPDLOCK | Prevent lost update |
| CC-03 | BR-xx | READ COMMITTED | Reading committed data is sufficient |
| ... | ... | ... | ... |

---

# 5. Assumptions

List assumptions made during the analysis.

Example:

- Maintenance updates execute within a single transaction.
- Booking approval is completed within one transaction.
- All operations follow the application's transactional boundaries.

---

# 6. Open Questions

List ambiguities or business questions requiring clarification.

Example:

- Can advisory maintenance be modified while bookings are being approved?
- Should booking availability be protected per space or per overlapping time period?

---

# 7. Conclusion

Summarize:

- Major concurrency risks identified.
- Business rules protected.
- Recommended SQL Server concurrency mechanisms.
- Overall concurrency design strategy.