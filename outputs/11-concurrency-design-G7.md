# Concurrency Design

Baseline input artifacts:

- `req/business-requirement-change.md` (updated requirements)
- `outputs/08-req-change-analysis-G7.md` (requirement change analysis — treated as the baseline for business rules and conflicts)

This document specifies how business consistency must be preserved under concurrent execution using Microsoft SQL Server concurrency mechanisms. It is a design-only artifact: no SQL statements, transaction scripts, triggers, stored procedures, or pseudo code are included. Implementation belongs to `outputs/12-concurrency-implementation-G7.sql`.

---

# 1. Concurrency-Sensitive Business Rules

Identify every business rule that may be violated under concurrent execution.

| Business Rule | Description | Reason Concurrency Matters |
|----------------|-------------|----------------------------|
| BR-14 (Modified) | The same space cannot have two approved bookings with overlapping time periods. | The rule requires checking the current set of approved bookings (validate-before-insert) before recording a new approved booking; the check is only correct if the state cannot change between check and commit. |
| BR-44 (New) | A space with an active out-of-service maintenance record cannot be booked for any time period overlapping the maintenance period. | Booking creation must validate against the space's current maintenance state; the state may change concurrently (maintenance recorded, escalated, or downgraded). |
| BR-45 (New) | A space with only active advisory maintenance records may be booked; the requester must be notified of all active advisories at booking time. | The set of active advisories must be captured consistently at booking time; advisories may be recorded concurrently with the booking. |
| BR-46 (New) | The booking must record the requester's acknowledgement that they were informed of the active advisories. | The recorded acknowledgement must correspond to the advisory snapshot captured at booking time; otherwise the notification obligation is silently bypassed. |
| BR-48 (New) | When advisory maintenance is escalated to out-of-service, all approved bookings overlapping the maintenance period must be identifiable so staff can contact the requesters. | The identification read must observe a consistent state of approved bookings; a booking committed concurrently may otherwise be missed. |
| BR-49 (New) | For selected space types, booking requests satisfying the usage policy are approved automatically at submission time. | The instant approval decision is itself a check-then-act operation that must serialize with all other booking decisions for the same space. |
| BR-50 (New) | BR-14 must hold regardless of whether bookings are created through instant booking or staff approval, and even when multiple users and staff operate concurrently. | Umbrella rule: every booking path (instant, staff approval) must share the same conflict protection so the invariant cannot be bypassed through a different path. |

Excluded rules: BR-32, BR-33 (booking-blocking semantics are now fully expressed by BR-44), BR-42, BR-43 (structural/existential rules not state-dependent), BR-19 (removed in Phase 2). These cannot be violated by concurrent execution of the identified operations.

---

# 2. Concurrent Operations

Identify realistic operations that may execute simultaneously.

| Operation ID | Operation | Description |
|--------------|-----------|-------------|
| OP-01 | Submit instant booking | User submits a booking request for a space; because it satisfies the usage policy and the space type is eligible, the request is approved automatically at submission time. Includes validation of availability, out-of-service maintenance, and advisory notification with acknowledgement. |
| OP-02 | Submit booking for staff approval | User submits a booking request; the request is recorded as pending and continues through the staff approval workflow. Includes validation of availability, out-of-service maintenance, and advisory notification with acknowledgement. |
| OP-03 | Approve pending booking | Staff member approves a pending booking request; the request becomes an approved booking after re-validation of availability and maintenance state. |
| OP-04 | Record maintenance record | Staff member records a new maintenance record for a space with impact level out-of-service or advisory. |
| OP-05 | Escalate maintenance | Staff member changes the impact level of an open maintenance record from advisory to out-of-service and identifies affected approved bookings. |
| OP-06 | Downgrade maintenance | Staff member changes the impact level of an open maintenance record (e.g., out-of-service → advisory). |

Note: no DELETE-style operation exists in the workflow (booking cancellation and maintenance deletion are not part of the requirements). DELETE vs other operations is therefore not analyzed.

---

# 3. Concurrency Conflict Analysis

Each subsection describes one realistic concurrency conflict.

Classification legend (per Requirement Evidence Rule): **Explicitly Required** — directly stated in the updated requirements; **Directly Inferred** — follows necessarily from the stated rules and operating conditions; **Assumption** — plausible but not evidenced.

---

## CC-01 — Concurrent instant bookings for the same space and overlapping time period

**Classification:** Explicitly Required (RC-07, BR-50 — the requirements explicitly describe simultaneous instant bookings at semester start).

### Scenario

At the beginning of a semester, two users submit instant booking requests for the same popular space at approximately the same time. Both requests cover overlapping time periods. Both requests satisfy the usage policy and would be approved automatically at submission.

### Concurrent Operations

- OP-01 (user A — submit instant booking)
- OP-01 (user B — submit instant booking)

### Shared Business Resources

- The space's availability for the requested time period (the set of approved bookings of the space overlapping the request)

### Business Rule(s) Affected

- BR-14
- BR-50

### Business Invariant

At any point in time, at most one approved booking exists for a given space and time period; two approved bookings for the same space must never overlap.

### Conflict Explanation

Both submissions follow the same check-then-act sequence: check that no approved booking overlaps the request, then record the approved booking. If both checks run before either result is recorded, each transaction sees an empty availability window and both commit, producing two overlapping approved bookings. Availability is a derived property of the space's approved bookings, so the race is on the shared space availability, not on the booking rows themselves.

---

### Recommended SQL Server Concurrency Mechanism

- Locking Hint: UPDLOCK + HOLDLOCK (on the space row / availability check for the requested period)

No isolation level is required beyond SQL Server's default READ COMMITTED.

---

### Justification

The availability check must take a lock that is (a) update-oriented, so concurrent checkers are blocked rather than all reading at once, and (b) held to commit (HOLDLOCK), so the checked window cannot gain a phantom overlapping booking before the transaction ends. Two concurrent instant bookings for the same space then serialize: the second waits until the first commits (then sees the conflict) or rolls back (then proceeds). A plain READ COMMITTED read releases its lock immediately after the check, so both transactions can pass the check — insufficient. SERIALIZABLE isolation is unnecessary: it would protect every range read in the whole transaction, while the conflict is confined to the space availability check. Trade-off: booking creation for the same space is serialized, which is exactly the required business behavior; bookings for different spaces and all other operations remain fully concurrent.

---

## CC-02 — Staff approval racing with instant booking or another staff approval

**Classification:** Explicitly Required (BR-50 — the no-conflict rule must hold across both paths under concurrent operations).

### Scenario

A user submits an instant booking for a space while, at the same time, a staff member approves a pending booking for the same space and an overlapping period. Alternatively, two staff members approve two pending bookings for the same space and overlapping periods simultaneously.

### Concurrent Operations

- OP-03 (staff — approve pending booking)
- OP-01 (user — submit instant booking)
- OP-03 (staff — approve another pending booking)

### Shared Business Resources

- The space's availability for the requested time period (the set of approved bookings of the space overlapping the request)

### Business Rule(s) Affected

- BR-14
- BR-49
- BR-50

### Business Invariant

Approval decisions and instant approvals for the same space must never result in overlapping approved bookings, regardless of which booking path created them.

### Conflict Explanation

Instant booking (OP-01) and staff approval (OP-03) each validate availability before recording/approving. If the two paths use different or no concurrency protection, each may pass its availability check against the same pre-commit state and both succeed — the no-conflict rule then depends on which path commits first, not on any guarantee. The same race exists between two simultaneous staff approvals.

---

### Recommended SQL Server Concurrency Mechanism

- Locking Hint: UPDLOCK + HOLDLOCK (on the space row / availability check for the requested period, applied identically in both booking paths)

No isolation level is required beyond SQL Server's default READ COMMITTED.

---

### Justification

The mechanism of CC-01 must be shared by every path that produces an approved booking (instant submission and staff approval). If instant bookings lock but staff approval does not, the two paths race with each other exactly as before. Using the same UPDLOCK + HOLDLOCK availability check in both paths makes every approved-booking decision serialize on the space's availability, so the two paths cannot interleave their checks and commits. Weaker mechanisms (plain reads on either path) are insufficient for the same reason as CC-01. SERIALIZABLE is unnecessary — the conflict is again confined to the shared availability check. Trade-off: an approval may wait briefly behind an in-flight booking decision for the same space; this is required to preserve BR-50.

---

## CC-03 — Booking creation racing with escalation to out-of-service

**Classification:** Explicitly Required (BR-44, BR-48 — the requirements define out-of-service blocking and escalation to out-of-service with affected-booking identification).

### Scenario

A space currently has only advisory maintenance. A user submits (or a staff member approves) a booking for the space. At the same time, the Facility Manager escalates the advisory maintenance record to out-of-service, and the maintenance period covers the requested booking period.

### Concurrent Operations

- OP-01 / OP-02 / OP-03 (booking creation path)
- OP-05 (staff — escalate maintenance to out-of-service)

### Shared Business Resources

- The space's booking availability and its active maintenance state (out-of-service coverage over the requested period)

### Business Rule(s) Affected

- BR-44
- BR-48

### Business Invariant

A space covered by active out-of-service maintenance for a period must never have an approved booking overlapping that period; when a record is escalated to out-of-service, every already-approved booking overlapping the maintenance period must be identifiable.

### Conflict Explanation

Two interleavings violate the invariant:

1. The booking transaction checks the maintenance state (sees advisory only) and is about to commit; the escalation commits first. The booking is then created on a space that is already out-of-service for the booked period — BR-44 is violated.
2. The escalation updates the impact level to out-of-service, then reads the approved bookings overlapping the maintenance period; a booking commits in between. The affected-booking list misses that booking — BR-48 is violated.

The root cause is that booking creation and escalation read and modify the same space availability/maintenance state without a common serialization point.

---

### Recommended SQL Server Concurrency Mechanism

- Locking Hint: UPDLOCK + HOLDLOCK (on the space row), acquired by the booking transaction before validating maintenance state and by the escalation transaction before updating the impact level and identifying affected bookings

No isolation level is required beyond SQL Server's default READ COMMITTED.

---

### Justification

Acquiring the space-row lock with UPDLOCK + HOLDLOCK in both transactions serializes booking creation and escalation per space. The escalation then holds the lock for its entire update-and-identify sequence, so no overlapping booking can commit while the affected-booking identification runs: any booking that commits before the escalation took the lock is already committed and appears in the identification read, and any booking attempted afterward sees the escalated out-of-service state and is rejected by BR-44. Without the lock, the escalation's identification read under default READ COMMITTED can miss a concurrently committed booking — a plain read is insufficient. SERIALIZABLE on the escalation transaction would lock more state than the space's booking/maintenance data and is not needed once booking creation shares the same space lock. Trade-off: bookings for a space are briefly blocked while an escalation commits; the escalation (a rare, deliberate staff action) accepts this short blocking in exchange for BR-44/BR-48 correctness.

---

## CC-04 — Booking creation racing with recording of a new advisory maintenance record

**Classification:** Directly Inferred (from BR-45/BR-46 and BR-43 — the requirements state multiple active maintenance records may exist concurrently and the requester must be notified of all active advisories at booking time; the simultaneous execution of advisory recording and booking follows necessarily from the concurrent operating conditions).

### Scenario

A user submits a booking for a space that currently has no active advisory maintenance. At the same time, a staff member records a new advisory maintenance record for that space (or an additional advisory is added to an already-advisory space).

### Concurrent Operations

- OP-01 / OP-02 / OP-03 (booking creation path, advisory snapshot + acknowledgement recording)
- OP-04 (staff — record advisory maintenance record)

### Shared Business Resources

- The space's set of active advisory maintenance records

### Business Rule(s) Affected

- BR-45
- BR-46

### Business Invariant

Every booking made while advisories are active must have its requester notified of all active advisories, and the acknowledgement must be recorded with the booking; a booking must not silently miss an advisory that became active at booking time.

### Conflict Explanation

The booking transaction reads the space's active advisories (sees none), then records the booking with an acknowledgement "no advisories". If the advisory insertion commits between the advisory read and the acknowledgement recording, the booking was created while the advisory was active but the acknowledgement does not reflect it — the notification obligation is silently bypassed. The boundary question of what exactly counts as "at booking time" (Q-05) makes the serialization point the only unambiguous way to guarantee the invariant.

---

### Recommended SQL Server Concurrency Mechanism

- Locking Hint: UPDLOCK + HOLDLOCK (on the space row), acquired by the booking transaction while reading the active advisories and recording the acknowledgement
- Locking Hint: UPDLOCK (on the space row), acquired by the advisory recording transaction

No isolation level is required beyond SQL Server's default READ COMMITTED.

---

### Justification

The space row is the shared serialization point for all state that changes a space's booking conditions. Advisory recording takes an update lock on it, and booking creation holds the same lock from advisory read through acknowledgement recording, so an advisory commits either before the booking's snapshot (it is included in the notification) or after the booking's acknowledgement (outside the "at booking time" window, per Q-05). Weaker mechanisms fail: a plain READ COMMITTED read of advisories does not prevent an advisory from committing mid-transaction, so the acknowledgement can miss it. SERIALIZABLE is unnecessary — the conflict is confined to the space's advisory set, serialized via the space row. Trade-off: advisory recording for a space waits while a booking for that space is being finalized; advisory recording is a staff action whose brief wait preserves BR-45/BR-46.

---

# 4. Concurrency Mechanism Summary

| Conflict | Business Rule(s) | Recommended Mechanism | Reason |
|-----------|------------------|-----------------------|--------|
| CC-01 | BR-14, BR-50 | UPDLOCK + HOLDLOCK (space availability check) | Prevent check-then-act race between concurrent instant bookings for the same space |
| CC-02 | BR-14, BR-49, BR-50 | UPDLOCK + HOLDLOCK (space availability check, both paths) | Common serialization of staff approval and instant booking on the same availability check |
| CC-03 | BR-44, BR-48 | UPDLOCK + HOLDLOCK (space row) | Serialize booking creation vs escalation; make affected-booking identification consistent |
| CC-04 | BR-45, BR-46 | UPDLOCK + HOLDLOCK (booking, space row); UPDLOCK (advisory recording, space row) | Serialize advisory recording with the booking's advisory snapshot and acknowledgement |

All four conflicts are resolved with locking hints. No isolation level is required: SQL Server's default READ COMMITTED combined with the specified UPDLOCK/HOLDLOCK hints preserves every identified invariant (Rule SQL2 — isolation levels are recommended only when they contribute beyond default behavior).

---

# 5. Assumptions

- A-01 (from 08): The two impact levels defined in the requirements (out-of-service and advisory) are exhaustive for now.
- A-02 (from 08): "Selected space types" for instant booking are determined by the usage policy; the exact set is not specified.
- A-04 (from 08): Escalation/downgrade applies while the maintenance record is open.
- Booking creation (instant or pending, including availability validation, maintenance-state validation, advisory snapshot, and acknowledgement recording) executes within a single transaction.
- Booking approval executes within a single transaction, including its availability and maintenance-state re-validation.
- Escalation to out-of-service (level update plus affected-booking identification) executes within a single transaction.
- Every path that produces or validates an approved booking acquires the same space-row availability lock (UPDLOCK + HOLDLOCK) so all booking decisions share one serialization point.
- No DELETE-style operation (booking cancellation, maintenance record deletion) exists in the workflow, so DELETE concurrency is not analyzed.
- The advisory snapshot recorded with a booking covers advisories committed before the snapshot read; advisories committed after the acknowledgement are outside the "at booking time" window (depends on Q-05).

---

# 6. Open Questions

- Q-01 (from 08): Which space types are eligible for instant booking, and what exactly does "satisfy the usage policy" require?
- Q-02 (from 08): When a booking is created while advisories are active, how is the requester's acknowledgement confirmed (explicit consent at submission, or confirmation by the requester)?
- Q-03 (from 08): Can the impact level be downgraded below advisory, or is advisory the minimum?
- Q-04 (from 08): When maintenance is escalated to out-of-service and affected approved bookings are found, may those bookings be cancelled, or must staff only contact the requesters? (A cancellation operation would introduce a new DELETE-style concurrency consideration.)
- Q-05 (from 08): How soon after an advisory is active must a booking-time notification capture it — what counts as "at booking time"? (Defines the boundary that CC-04's serialization point enforces.)
- Q-06 (from 08): Is there a maximum number of simultaneous active maintenance records per space?

---

# 7. Conclusion

**Major concurrency risks identified:**

- Overlapping approved bookings for the same space, whether both created by instant booking (CC-01), by staff approval racing with instant booking (CC-02), or through approval of overlapping pending requests.
- Bookings created on a space whose maintenance has just escalated to out-of-service, and affected-booking identifications that miss concurrently committed bookings (CC-03).
- Acknowledgements that silently miss advisories recorded while the booking was being created (CC-04).

**Business rules protected:** BR-14, BR-44, BR-45, BR-46, BR-48, BR-49, BR-50.

**Recommended SQL Server concurrency mechanisms:**

- UPDLOCK + HOLDLOCK on the space availability check for every path that produces an approved booking (CC-01, CC-02), for booking creation vs maintenance escalation (CC-03), and for advisory snapshot + acknowledgement recording (CC-04).
- No isolation level changes; default READ COMMITTED plus the specified locking hints preserves every invariant with the least restrictive mechanism.

**Overall concurrency design strategy:** the space row is the single serialization point for everything that changes or validates a space's booking conditions (availability, out-of-service coverage, active advisories). Every booking path and every maintenance state change acquires the appropriate update lock on it. Reporting remains lock-free at READ COMMITTED. This yields pairwise serialization of conflicting operations with minimal blocking and no isolation-level overhead.
