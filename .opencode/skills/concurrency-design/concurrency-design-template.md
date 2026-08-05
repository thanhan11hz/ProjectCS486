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

### Recommended SQL Server Mechanism

Specify:

- Isolation Level (if applicable)
- Locking Hint (if applicable)

Example:

- Isolation Level: SERIALIZABLE
- Locking Hint: UPDLOCK

---

### Justification

Explain:

- Why the selected mechanism prevents the conflict.
- Why weaker isolation levels are insufficient.
- Performance considerations.
- Why this mechanism is appropriate for this scenario.

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
| CC-01 | BR-xx | SERIALIZABLE + UPDLOCK | Prevent phantom booking |
| CC-02 | BR-xx | READ COMMITTED + UPDLOCK | Prevent lost update |
| ... | ... | ... | ... |

---

# 5. Assumptions

List assumptions made during the analysis.

Example:

- Maintenance updates are executed within a single transaction.
- Booking approval is performed by one staff member at a time.
- The application always uses transactional operations.

---

# 6. Open Questions

List ambiguities or business questions that require clarification.

Example:

- Can advisory maintenance be modified while bookings are being approved?
- Should concurrent booking approvals be serialized across the entire space or only overlapping time periods?

---

# 7. Conclusion

Summarize:

- Major concurrency risks identified.
- Business rules protected.
- Recommended SQL Server mechanisms.
- Overall concurrency design strategy.