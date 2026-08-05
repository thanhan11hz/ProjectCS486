# Concurrency Design

Baseline: `outputs/08-req-change-analysis-G7.md` (Phase 2 requirement change analysis)
Changed requirements: `req/business-requirement-change.md`

# 1. Concurrency-Sensitive Business Rules

| Business Rule | Description | Reason Concurrency Matters |
|----------------|-------------|----------------------------|
| BR-14 (Modified) | The same space cannot have two approved bookings with overlapping time periods. | Availability is checked before the booking result is recorded; under simultaneous operations two transactions may both pass the check and both record an approved booking. |
| BR-44 | A space with an active out-of-service maintenance record cannot be booked for any time period overlapping the maintenance period. | The booking transaction must validate the space's maintenance state at booking time; a maintenance escalation committing concurrently can invalidate that validation. |
| BR-45 | A space with only active advisory maintenance records may be booked; the requester must be notified of all active advisories at booking time. | The notification must cover exactly the set of advisories active at booking time; a concurrently inserted advisory can be missed by the notification. |
| BR-46 | The booking must record the requester's acknowledgement that they were informed of the active advisories. | The acknowledgement is only valid if the advisory set it refers to was complete and stable at booking time. |
| BR-47 | The impact level of an open maintenance record may be escalated (advisory → out-of-service) or downgraded. | Concurrent decisions on the same record can silently overwrite each other (lost update), leaving an impact level that matches neither decision. |
| BR-48 | When advisory maintenance is escalated to out-of-service, all approved bookings overlapping the maintenance period must be identifiable so staff can contact the requesters. | The escalation's scan of affected bookings can miss a booking that is approved concurrently with the scan. |
| BR-49 | For selected space types, booking requests satisfying the usage policy are approved automatically at submission time. | Instant booking introduces an automated approval path that can race with the staff approval path over the same space and time period. |
| BR-50 | The no-overlapping-approved-bookings rule (BR-14) must hold regardless of whether bookings are created through instant booking or staff approval, and even when multiple users and staff operate concurrently. | All booking paths share the same invariant, so every path must use an equally strong concurrency strategy. |

All rules above are concurrency-sensitive: each requires validation before data modification, depends on the current state of shared business resources, and can be violated by simultaneous transactions.

---

# 2. Concurrent Operations

| Operation ID | Operation | Description |
|--------------|-----------|-------------|
| OP-01 | Create Instant Booking | User submits a booking request that satisfies the usage policy for a selected space type; the request is approved automatically at submission time. |
| OP-02 | Submit Booking Request | User submits a booking request that goes through the staff approval workflow. |
| OP-03 | Approve Booking | Staff member approves a pending booking request. |
| OP-04 | Escalate Maintenance Impact Level | Staff changes an open maintenance record from advisory to out-of-service. |
| OP-05 | Downgrade Maintenance Impact Level | Staff changes an open maintenance record from out-of-service to advisory. |
| OP-06 | Record Advisory Maintenance | Staff records a new open maintenance record with impact level advisory for a space. |
| OP-07 | Record Out-of-Service Maintenance | Staff records a new open maintenance record with impact level out-of-service for a space. |
| OP-08 | Identify Affected Approved Bookings | Staff-run scan, triggered by an escalation, that lists approved bookings overlapping the escalated maintenance period. |

---

# 3. Concurrency Conflict Analysis

---

## CC-01 — Simultaneous Instant Bookings for the Same Space and Overlapping Period

### Scenario

At the beginning of the semester, two users submit instant bookings for the same popular space at approximately the same time. Both request overlapping time periods (for example, 10:00–12:00 and 11:00–13:00). Each submission runs the availability check before its result is recorded.

### Concurrent Operations

- OP-01 (User A creates instant booking for space S, period P1)
- OP-01 (User B creates instant booking for space S, period P2, where P1 and P2 overlap)

### Shared Business Resources

- The space's availability for the requested time period, i.e., the set of approved bookings of that space overlapping the requested period.

### Business Rule(s) Affected

- BR-14
- BR-50

### Business Invariant

At any point in time, at most one approved booking exists for a given space and time point; two approved bookings for the same space must never overlap.

### Conflict Explanation

Both transactions read the availability state of space S (no conflicting approved booking found), then both record an approved booking. Because neither transaction's check sees the other's not-yet-committed booking, both results are recorded and the invariant is violated. The failure is a phantom: the concurrent overlapping booking is not part of either transaction's read set, so no row-level lock protects the invariant.

Classification: Explicitly Required — RC-07 states multiple users may submit simultaneously and BR-50 requires the no-overlap rule to hold under concurrent operation.

---

### Recommended SQL Server Mechanism

- Isolation Level: SERIALIZABLE
- Locking Hint: UPDLOCK (on the space row) and HOLDLOCK (on the availability range read)

### Justification

- Why the selected mechanism prevents the conflict: SERIALIZABLE takes range locks (key-range locks) on the availability read over the requested space and time period, so a concurrent insert of an overlapping approved booking cannot proceed while the first transaction is uncommitted. UPDLOCK on the space row serializes all booking operations on the same space through one common row and avoids shared-lock-to-exclusive-lock conversion deadlocks between concurrent check-and-record flows.
- Why weaker mechanisms are insufficient: READ COMMITTED releases read locks immediately after the check, so both transactions can pass the check and both insert. REPEATABLE READ holds shared locks on rows that were read but does not lock the range, so a concurrently inserted overlapping booking (a phantom) is still not prevented. Only range locking closes the phantom gap.
- Performance considerations: concurrency is reduced only for conflicting space/time ranges; bookings for different spaces or non-overlapping periods are unaffected. Blocking is limited to the duration of the availability check plus booking recording, and conflicts are rare relative to total bookings.
- Why this mechanism is appropriate: the invariant is strict (no overlap, ever), so the least restrictive mechanism that still prevents phantoms for the checked range is SERIALIZABLE; the UPDLOCK hint makes the per-space serialization point explicit and deadlock-resistant.

---

## CC-02 — Staff Approval Racing with Booking Submission or Instant Booking for an Overlapping Period

### Scenario

A pending booking request for space S (14:00–15:00) is being approved by a staff member while, at the same time, another user submits an instant booking for the same space for 14:30–16:00, or another staff member approves a different pending request for an overlapping period.

### Concurrent Operations

- OP-03 (Staff approves pending booking for space S, period P1)
- OP-01 or OP-02 (User submits a booking for space S, period P2 overlapping P1)
- OP-03 (Second staff member approves a different pending request for space S, overlapping period)

### Shared Business Resources

- The space's availability for the requested time period (the set of approved bookings of that space overlapping the period).

### Business Rule(s) Affected

- BR-14
- BR-49
- BR-50

### Business Invariant

Approval decisions — whether produced by instant booking or by staff approval — must never result in overlapping approved bookings for the same space.

### Conflict Explanation

The approval transaction performs a check-then-act: it verifies the pending request's availability, then records the approval. If an instant booking or another approval commits in the interval between the check and the recording of the approval, both bookings become approved and overlap. Because the two operations go through different workflows (user submission vs. staff approval) but share the same underlying availability state, the check-then-act race is the same as CC-01.

Classification: Explicitly Required — RC-07 explicitly names simultaneous booking and approval operations by users and staff.

---

### Recommended SQL Server Mechanism

- Isolation Level: SERIALIZABLE
- Locking Hint: UPDLOCK (on the space row), HOLDLOCK (on the availability range read)

### Justification

- Why the selected mechanism prevents the conflict: the approval transaction locks the checked availability range (space + time period) with range locks and takes UPDLOCK on the space row before recording the approval; any concurrent instant booking or other approval for an overlapping period must wait, so both results cannot both be recorded.
- Why weaker mechanisms are insufficient: under READ COMMITTED or REPEATABLE READ, the concurrently recorded booking is a phantom relative to the approval's availability check; the approval commits based on a stale read. Row-level protection of existing rows cannot prevent the phantom, so range locking is required.
- Performance considerations: the staff approval path gains the same range-lock cost as instant booking, which is acceptable because approval operations are less frequent than submissions; the serialization point on the space row also limits deadlock-prone lock conversions between the two paths.
- Why this mechanism is appropriate: BR-50 requires identical guarantees from both booking paths; using the same mechanism for OP-01, OP-02, and OP-03 keeps the guarantee uniform and enforceable in one place.

---

## CC-03 — Booking Submitted or Approved While Maintenance Is Escalated to Out-of-Service

### Scenario

A staff member escalates an open advisory maintenance record of space S to out-of-service for 09:00–17:00. At the same time, a user submits an instant booking (or a staff member approves a pending booking) for space S for 10:00–11:00. The two transactions interact over both the space's booking availability and its maintenance state.

### Concurrent Operations

- OP-04 (Staff escalates maintenance of space S to out-of-service for period P)
- OP-01, OP-02, or OP-03 (Booking is created/approved for space S for period Q overlapping P)

### Shared Business Resources

- The space's booking availability for the requested period.
- The space's active maintenance state (out-of-service records overlapping the period).

### Business Rule(s) Affected

- BR-44
- BR-48
- BR-47 (the escalation is itself a level change)

### Business Invariant

A space covered by active out-of-service maintenance for a period must not have approved bookings overlapping that period; and every escalation to out-of-service must surface every already-approved booking affected by the new out-of-service period, so staff can contact the requesters.

### Conflict Explanation

Two directions of the same race:

- Direction A (booking misses the escalation): the booking transaction checks the space's active maintenance, sees only advisory (or no) maintenance, and records the booking; the escalation commits afterwards. Result: an approved booking now overlaps an out-of-service period and was never identified as affected — BR-44 and BR-48 are both violated.
- Direction B (escalation misses the booking): the escalation transaction scans approved bookings overlapping the maintenance period, finds none, and commits; the booking transaction commits afterwards. Result: the booking was approved on a space that was already out-of-service — BR-44 is violated and BR-48's affected list is incomplete.

In both directions the other transaction's committed data is a phantom relative to the current transaction's read.

Classification: Directly Inferred — RC-07 explicitly guarantees concurrency safety for booking and approval operations; the requirement that maintenance escalation stays consistent with those operations (BR-44, BR-48) follows from the combination of RC-04/RC-05 with concurrent booking.

---

### Recommended SQL Server Mechanism

- Isolation Level: SERIALIZABLE
- Locking Hint: HOLDLOCK on both range reads; UPDLOCK on the space row as a common serialization point

### Justification

- Why the selected mechanism prevents the conflict: the booking transaction reads the space's active maintenance with SERIALIZABLE range locks, so an escalation that would insert or update an out-of-service record covering the requested period must wait until the booking commits. Symmetrically, the escalation transaction scans approved bookings for the maintenance period with SERIALIZABLE range locks, so a concurrent booking insert into the period must wait until the escalation commits. Either way, the two operations are serialized and both invariants hold.
- Why weaker mechanisms are insufficient: READ COMMITTED and REPEATABLE READ both allow the phantom in one of the two directions — the booking's maintenance read or the escalation's booking scan can each miss the other transaction's uncommitted result. Only range locking forces mutual exclusion over the time period.
- Performance considerations: the escalation operation is rare and already involves a staff workflow, so the blocking it introduces is acceptable; booking operations on the affected space wait only while the maintenance state of that space is being changed.
- Why this mechanism is appropriate: the invariant requires that no booking overlaps out-of-service maintenance and that the affected-booking scan is complete; the least restrictive mechanism providing complete protection for both directions is SERIALIZABLE with range locks, with UPDLOCK on the space row giving both transactions a common ordering point.

---

## CC-04 — Booking Submitted While a New Advisory Maintenance Record Is Being Recorded

### Scenario

A user submits a booking for space S (10:00–12:00) at the same time a staff member records a new advisory maintenance record for S covering 09:00–12:00. The booking must notify the requester of all active advisories at booking time and record the acknowledgement.

### Concurrent Operations

- OP-01 or OP-02 (User submits a booking for space S, period Q)
- OP-06 (Staff records a new advisory maintenance record for space S, period P overlapping Q)

### Shared Business Resources

- The space's set of active advisories at booking time.

### Business Rule(s) Affected

- BR-45
- BR-46

### Business Invariant

Every booking made while advisories are active on the space must have its requester notified of all advisories active at booking time, with the acknowledgement recorded; a booking must not silently miss an advisory that became active at booking time.

### Conflict Explanation

The booking transaction reads the set of active advisories (for example, sees none), then records the booking with its acknowledgement. If the advisory insert commits after the read but before or concurrently with the booking's recording, the booking was created without notification of an advisory that was active at booking time. The advisory is a phantom relative to the booking's read, so row-level locks on previously read rows do not protect the invariant.

Classification: Directly Inferred — BR-45/BR-46 require the notification and acknowledgement "at booking time"; the requirement does not explicitly describe concurrent advisory recording, but the semester-start scenario (RC-07) makes concurrent maintenance recording realistic, and the "at booking time" obligation (Q-05) makes the timing boundary a concurrency issue.

---

### Recommended SQL Server Mechanism

- Isolation Level: SERIALIZABLE
- Locking Hint: HOLDLOCK on the read of active advisories within the booking transaction

### Justification

- Why the selected mechanism prevents the conflict: the booking transaction's advisory read takes range locks over the space's active advisory records, so a concurrent insert of a new advisory for that space must wait until the booking transaction commits. If the advisory commits first, it is included in the notification; otherwise it is recorded after the booking and the booking's acknowledgement remains complete for the state at booking time.
- Why weaker mechanisms are insufficient: READ COMMITTED and REPEATABLE READ protect only rows that were actually read; the new advisory row does not exist yet at read time, so only range locking (SERIALIZABLE or HOLDLOCK) blocks the phantom insert.
- Performance considerations: advisory recording waits while a booking on the same space is being processed; advisory records are typically created during inspections and are much less frequent than bookings, so the impact is limited.
- Why this mechanism is appropriate: the obligation is defined per booking against the advisory set at booking time; SERIALIZABLE is the least restrictive mechanism that gives a well-defined, stable snapshot of that set for the duration of the booking transaction.

---

## CC-05 — Concurrent Escalation and Downgrade Decisions on the Same Maintenance Record

### Scenario

Two staff members review the same open maintenance record of space S at the same time. One escalates the impact level from advisory to out-of-service; the other downgrades it (for example, back to advisory, or from out-of-service to advisory). Each decision is based on the record state read at the start of the review.

### Concurrent Operations

- OP-04 (Staff escalates the impact level of maintenance record M)
- OP-05 (Staff downgrades the impact level of maintenance record M)

### Shared Business Resources

- The maintenance record's impact level (the maintenance record row itself).

### Business Rule(s) Affected

- BR-47
- BR-44 and BR-48 (indirectly: the final committed level determines whether bookings must be blocked and whether an affected-booking scan must run)

### Business Invariant

The impact level of an open maintenance record has exactly one consistent current value at any point in time, and a decision recorded by staff must be applied to the most recent state of the record.

### Conflict Explanation

Both staff transactions read the current impact level of record M (for example, advisory). Each applies its own decision and writes the record. The last writer to commit silently overwrites the other's decision: the first decision is lost without any error, and the committed level may contradict the business intent of the staff member whose decision was overwritten. This is a classic lost update on a check-then-write flow. Additionally, whether the record ends as advisory or out-of-service determines whether an affected-booking scan is required, so the lost update can also cause a required escalation workflow (BR-48) to be skipped.

Classification: Directly Inferred — BR-47 states levels may be escalated or downgraded by staff; the requirement does not explicitly describe simultaneous staff decisions, but the semester-start workload and multiple staff members make concurrent decisions realistic.

---

### Recommended SQL Server Mechanism

- Isolation Level: READ COMMITTED
- Locking Hint: UPDLOCK on the maintenance record row when reading it for a decision

### Justification

- Why the selected mechanism prevents the conflict: the decision transaction reads the maintenance record with UPDLOCK, so a concurrent decision transaction on the same record blocks until the first decision commits; the second decision is then evaluated against the latest committed level instead of a stale one. The final UPDATE itself takes an exclusive row lock, so two writers cannot both commit from the same read.
- Why weaker mechanisms are insufficient: a plain READ COMMITTED read takes no retained lock, so both decision transactions can read the same stale level and both proceed; the last writer wins and the first decision is silently lost. Snapshot-based reads (without a version check) have the same lost-update problem.
- Performance considerations: contention exists only on the single maintenance record row and only during the brief decision transaction; concurrent work on other records or on bookings for the same space is not blocked by the row lock.
- Why this mechanism is appropriate: the conflict is row-level, so the least restrictive mechanism is a row-level update lock acquired at the read; READ COMMITTED with UPDLOCK provides exactly this with minimal blocking.

---

# 4. Concurrency Mechanism Summary

| Conflict | Business Rule(s) | Recommended Mechanism | Reason |
|-----------|------------------|-----------------------|--------|
| CC-01 | BR-14, BR-50 | SERIALIZABLE + UPDLOCK (space row) + HOLDLOCK (range read) | Prevent phantom overlapping approved bookings between simultaneous instant bookings |
| CC-02 | BR-14, BR-49, BR-50 | SERIALIZABLE + UPDLOCK (space row) + HOLDLOCK (range read) | Prevent phantom bookings across instant and staff approval paths |
| CC-03 | BR-44, BR-48 | SERIALIZABLE + HOLDLOCK on both range reads; UPDLOCK (space row) | Prevent booking/escalation races in both directions (booking misses escalation; escalation misses booking) |
| CC-04 | BR-45, BR-46 | SERIALIZABLE + HOLDLOCK (advisory range read) | Prevent phantom advisory insert while a booking captures its advisory set |
| CC-05 | BR-47 | READ COMMITTED + UPDLOCK (maintenance record row) | Prevent lost update on concurrent escalation/downgrade decisions |

---

# 5. Assumptions

| ID | Assumption |
|----|------------|
| A-01 | The two impact levels (out-of-service, advisory) are exhaustive for now; no other levels are introduced. (From `outputs/08-req-change-analysis-G7.md`, A-01.) |
| A-02 | Impact level escalation/downgrade applies only while the maintenance record is open. (From `outputs/08-req-change-analysis-G7.md`, A-04.) |
| A-03 | The mechanism of notifying requesters of advisories is outside this design's scope; only the concurrency-safe capture of the advisory set at booking time is addressed. (From `outputs/08-req-change-analysis-G7.md`, A-06.) |
| A-04 | Each business operation (instant booking, staff approval, maintenance escalation/downgrade, advisory recording) is executed as a single database transaction that contains both its validation reads and its writes. |
| A-05 | Instant bookings and staff approvals share the same availability check and the same transaction pattern, so one mechanism protects both paths. |
| A-06 | The database runs with default locking-based isolation (snapshot isolation not enabled); SERIALIZABLE and the locking hints are therefore effective as described. |
| A-07 | The availability check reads the space's approved bookings and active maintenance state within the same transaction that records the booking result. |
| A-08 | An escalation to out-of-service runs as one transaction containing the level update and the affected-bookings scan (OP-08), so both are protected by the same range locks. |
| A-09 | When a booking or approval finds a conflict under SERIALIZABLE blocking, the operation waits and then re-evaluates; the decision to reject or retry the conflicting request is a business policy outside this stage. |

---

# 6. Open Questions

| ID | Question | Reason |
|----|----------|--------|
| Q-01 | Which space types are eligible for instant booking, and what exactly does "satisfy the usage policy" require? | Affects how much traffic goes through the auto-approval path and therefore how much blocking the mechanism must absorb. (From `outputs/08-req-change-analysis-G7.md`, Q-01.) |
| Q-02 | How soon after an advisory is active must a booking-time notification capture it — what exactly counts as "at booking time"? | Determines the precise semantics CC-04 must guarantee and how long the advisory range lock must be held. (From `outputs/08-req-change-analysis-G7.md`, Q-05.) |
| Q-03 | When a booking operation blocks because a concurrent operation holds the range locks, should the requester receive an automatic rejection, an automatic retry, or a wait message? | Determines acceptable user-visible behavior and timeouts for the SERIALIZABLE mechanisms. |
| Q-04 | When two staff members make conflicting decisions on the same maintenance record, should the second decision wait (current design) or be rejected with an error prompting re-review? | Determines whether CC-05 should use blocking (UPDLOCK) or optimistic rejection semantics. |
| Q-05 | During an escalation's affected-booking scan, may new bookings for the whole maintenance period be blocked until the scan completes, or only the exact scanned range? | Determines the granularity of range locking for CC-03 and its performance impact. |
| Q-06 | May the impact level be downgraded below advisory (for example, to a "no impact" state), or is advisory the minimum? | If more levels exist, CC-05's row-level mechanism still applies, but the escalation workflow (CC-03) may need a wider range of transitions. (From `outputs/08-req-change-analysis-G7.md`, Q-03.) |

---

# 7. Conclusion

**Major concurrency risks identified:**

- Simultaneous bookings and approvals for the same space can produce overlapping approved bookings, across both the instant and staff approval paths (CC-01, CC-02).
- Booking operations racing with maintenance escalation to out-of-service can produce bookings on an unusable space and incomplete affected-booking identification (CC-03).
- Booking operations racing with advisory recording can bypass the notification and acknowledgement obligation (CC-04).
- Concurrent escalation/downgrade decisions on the same maintenance record can silently lose one decision (CC-05).

**Business rules protected:** BR-14, BR-44, BR-45, BR-46, BR-47, BR-48, BR-49, BR-50.

**Recommended SQL Server mechanisms:**

- SERIALIZABLE with HOLDLOCK range reads, plus UPDLOCK on the space row, for all booking/approval availability checks and for the maintenance escalation workflow (CC-01, CC-02, CC-03, CC-04).
- READ COMMITTED with UPDLOCK on the maintenance record row for impact level decisions (CC-05).

**Overall concurrency design strategy:**

- Treat the space's availability for a time period as the core shared resource: every operation that validates availability (instant booking, staff approval, escalation scan, advisory capture) acquires range locks over the exact space and period it validates, and every such operation orders itself through UPDLOCK on the space row.
- Protect the time-period invariants with range locking (SERIALIZABLE), the least restrictive mechanism that prevents the phantom overlaps these requirements allow; protect the single-row invariant of impact levels with a row-level update lock (UPDLOCK).
- All identified conflicts are traceable to business rules from the requirement change analysis, and all recommendations are exact Microsoft SQL Server mechanisms with no implementation details.

This document specifies the concurrency design only; SQL implementation, stored procedures, triggers, and transaction scripts belong to later stages.
