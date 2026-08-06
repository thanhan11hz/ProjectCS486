# Concurrency Tests — Group 7

## Purpose

This folder verifies the concurrency enforcement implemented in
`outputs/12-concurrency-implementation-G7.sql` against the five
concurrency conflicts identified in `outputs/11-concurrency-design-G7.md`.

Each conflict (CC-01 .. CC-05) has a dedicated SQL test file. Every test file
contrasts two executions of the *same* operation:

1. **WITHOUT enforcement** — the operation is performed as raw, naive T-SQL with
   **no locking hints and no shared serialization point** (default READ
   COMMITTED). This reproduces the race window and demonstrates the invariant
   being **violated** (overlapping approved bookings, missed advisory
   acknowledgement, lost impact-level update, etc.).
2. **WITH enforcement** — the operation is performed through the stored
   procedures defined in `outputs/12-concurrency-implementation-G7.sql`, which
   apply the designed `UPDLOCK` / `UPDLOCK + HOLDLOCK` hints. The invariant is
   **preserved** (one operation is rejected, serialized, or the consistent
   result is returned).

## Mapping: Conflict → Test File

| Conflict | Business Rule(s) | Test File | Mechanism Verified |
|----------|------------------|-----------|--------------------|
| CC-01 | BR-14, BR-50 | `CC-01_concurrent_instant_bookings.sql` | UPDLOCK+HOLDLOCK space row (availability check) |
| CC-02 | BR-14, BR-49, BR-50 | `CC-02_approval_vs_instant.sql` | UPDLOCK+HOLDLOCK space row shared by both booking paths |
| CC-03 | BR-44, BR-48 | `CC-03_booking_vs_escalation.sql` | UPDLOCK+HOLDLOCK space row: booking vs escalate + affected-identification |
| CC-04 | BR-45, BR-46 | `CC-04_booking_vs_advisory.sql` | UPDLOCK+HOLDLOCK (space, booking) + UPDLOCK (advisory recording) |
| CC-05 | BR-47 | `CC-05_concurrent_escalation_downgrade.sql` | UPDLOCK on maintenance record (lost update) |

## Prerequisites

1. The Phase 2 schema and data must exist:
   - `outputs/05-db-implementation-G7.sql`
   - `outputs/10-schema-migration-G7.sql`
   - `outputs/06-sample-data-G7.sql` (for realistic users/spaces)
2. The concurrency procedures must be installed:
   - `outputs/12-concurrency-implementation-G7.sql`
3. Run `00-setup-and-reset.sql` once to create the small, deterministic test
   rows each test relies on.

## How to run a concurrency test

A genuine race (or its prevention) requires **two simultaneous transactions**.
Each test file therefore provides two halves:

- **Session A** — run in SQL Server Management Studio *Query Window 1*.
- **Session B** — run in *Query Window 2*.

A real interleaving is simulated with explicit `BEGIN TRANSACTION` + `WAITFOR`
markers:

1. Start **Session A** `BEGIN` block (acquires locks / reads).
2. Start **Session B** `BEGIN` block (attempts the concurrent operation).
3. Step through the `WAITFOR`/`GO` checkpoints in a controlled order.
4. Inspect the printed result.

> Because SQL statement text runs sequentially inside one window but blocks
> wait on locks held by the other window, having two windows open lets you
> reproduce the true interleavings.

## Files

| File | Contents |
|------|----------|
| `00-setup-and-data.sql` | Idempotent test-data helper (deterministic space, users, maintenance) |
| `CC-01_concurrent_instant_bookings.sql` | Instant booking vs instant booking on the same space/overlap |
| `CC-02_approval_vs_instant.sql` | Staff approval racing instant booking / another approval |
| `CC-03_booking_vs_escalation.sql` | Booking creation racing escalation to out-of-service |
| `CC-04_booking_vs_advisory.sql` | Booking creation racing recording of a new advisory |
| `CC-05_concurrent_escalation_downgrade.sql` | Concurrent escalation/downgrade of one maintenance record |