# Concurrency Design (Initial)

Baseline: `outputs/08-req-change-analysis-G7.md` — Section 7: Concurrency Conflict Analysis

This document outlines a basic, high-level set of strategies to manage the concurrency conflicts
introduced by the Phase 2 business requirements for the CS486 Booking System. These strategies are
intentionally generic and serve as a starting point for understanding the problems, not as a complete
production-ready implementation plan.

---

## Concurrency Conflicts and Basic Solutions

### CC-01: Simultaneous Instant Bookings for the Same Space

**The Scenario:** Two users submit instant booking requests for the same space and the same overlapping
time period at approximately the same moment. Both users check availability, see the slot as free, and
both attempt to create a booking. Without any coordination, both bookings could be approved, resulting
in a double-booking which violates the fundamental no-overlap rule.

**The Solution:** Wrap the availability check and the booking creation in a single database transaction.
The transaction should ensure that once one user has read the availability state and committed a booking,
the other user's operation sees the updated state and is forced to check again. Using a lock on the
relevant records during the transaction will prevent two concurrent writes from both succeeding.

---

### CC-02: Staff Approval Concurrent with Another Booking Submission

**The Scenario:** A staff member is in the process of approving a pending booking for a space at the
same time another user submits a new booking request (or another staff member approves a different
pending request) for the same space and an overlapping time period. Because the approval and the new
booking submission happen simultaneously, both operations may pass their respective availability checks
before either one commits, again leading to two approved overlapping bookings.

**The Solution:** Both the approval operation and the instant booking submission operation should be
performed inside a transaction that acquires a lock on the space's booking records for the relevant
time window. This prevents the two operations from interfering with each other. Only one can hold the
lock at a time, so the second will wait and re-check the availability after the first completes.

---

### CC-03: Escalation to Out-of-Service Concurrent with a Booking

**The Scenario:** A maintenance record for a space is being escalated from "advisory" to "out_of_service"
by a facility staff member at the same moment a user is submitting or a manager is approving a booking
for that same space and overlapping time period. The booking check sees no out-of-service maintenance and
proceeds, while the escalation also completes, leaving an approved booking on a space that is now blocked.

**The Solution:** Use a transaction for the escalation process that locks the space and its related booking
records during the update. Similarly, the booking creation and approval process should lock the maintenance
records for the target space before checking availability. This mutual locking ensures that the escalation
and the booking cannot proceed simultaneously — one will complete first, and the other will then see the
correct updated state.

---

### CC-04: New Advisory Maintenance Created While a Booking Is Being Submitted

**The Scenario:** A user is in the process of filling out a booking form and submitting a booking for a
space. At the same time, a new advisory maintenance record is created for that space. The user's booking
check was done before the advisory was recorded, so they were not notified of it. Their booking gets
submitted without the required advisory acknowledgement, violating the business rule that all active
advisories must be acknowledged at booking time.

**The Solution:** When a booking is being finalized, the system should lock the maintenance records for
the target space at the moment of submission to prevent any new advisories from being inserted until the
booking transaction is complete. This ensures that the acknowledgement check captures the complete and
up-to-date set of active advisories. If a new advisory appears between the time the user views the form
and the time they submit, the transaction will detect it and require the user to re-acknowledge.

---

### CC-05: Concurrent Maintenance Impact Level Updates

**The Scenario:** Two facility staff members both retrieve the same maintenance record and attempt to
update its impact level at the same time. One may be escalating it to "out_of_service" while the other
is downgrading it to "advisory". Without coordination, one update will silently overwrite the other,
resulting in an inconsistent and unpredictable final state.

**The Solution:** Use a lock on the maintenance record row at the time of reading it for the purpose of
updating. This means that once the first staff member starts their update, the second must wait. When the
second staff member's operation proceeds, it will see the already-committed change from the first and
can make a properly informed decision. This ensures the impact level always reflects a single, consistent
and intentional decision rather than a lost or overwritten update.

---

## Summary

The five concurrency conflicts above all stem from the same root cause: multiple operations reading a
shared state and then writing changes based on that state without sufficient coordination. The universal
basic solution for all of them is to use database transactions to group the read-check-write operations
into an atomic unit, and to use locks to prevent other concurrent operations from modifying the shared
resource between the read and the write. More advanced implementation details (such as which specific
isolation level or locking hint to use in Microsoft SQL Server) will be addressed in the final version
of this document.
