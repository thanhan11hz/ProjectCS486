# Concurrency Test Set-up Guide (G7)

How to run the concurrency conflict tests in `outputs/13-concurrency-tests-G7/`.

## 1. Objective

Each conflict folder contains two variants so you can contrast the behavior of
the same operation **with** and **without** concurrency enforcement:

- `with-concurrency-enforcement/`  — runs the stored procedure exactly as defined
  in `outputs/12-concurrency-implementation-G7.sql` (UPDLOCK / UPDLOCK + HOLDLOCK
  locking hints). The conflict is **prevented**.
- `without-concurrency-enforcement/` — runs an equivalent stored procedure from
  which all isolation-level statements and locking hints have been **removed**
  (plain READ COMMITTED reads, no UPDLOCK/HOLDLOCK). The conflict is **reproduced**.

Each folder contains three files:

| File | Description |
|------|-------------|
| `procedure.sql`  | The stored procedure definition actually used by the test. |
| `session-1.sql`  | Script to run in Session 1 (the "first" transaction). |
| `session-2.sql`  | Script to run in Session 2 (the "second" transaction). |

The two session scripts use `WAITFOR DELAY` so that both transactions overlap in
exactly the interleaving that exposes the target conflict.

## 2. Prerequisites

1 SQL Server 2019+ with the **Phase 2 schema** loaded into database
   `CS486_Booking_System` and the baseline procedures deployed:

   ```sql
   -- Phase 1 schema
   :r C:\...\outputs\05-db-implementation-G7.sql
   -- Phase 2 migration
   :r C:\...\outputs\10-schema-migration-G7.sql
   -- Concurrency-test reference data (users + test space X-100)
   :r C:\...\outputs\13-concurrency-tests-G7\data-init.sql
   -- Optional realistic baseline data
   :r C:\...\outputs\06-sample-data-G7.sql
   ```

   Out of the box, run instead `outputs/12-concurrency-implementation-G7.sql`
   to deploy the enforcement procedure, since `procedure.sql` is copied from it.

## 3. Overview of the conflicts under test

| Folder | Conflict | Operations | Business rules |
|--------|----------|-----------|----------------|
| `CC-01-double-instant-booking/` | Two instant bookings for the same space, overlapping period, both pass availability | OP-01 × OP-01 | BR-14, BR-50 |
| `CC-02-staff-approval-vs-instant/` | Instant booking racing with staff approval AND two staff approvals on the same space | OP-03 × OP-01, OP-03 × OP-03 | BR-14, BR-49, BR-50 |
| `CC-03-booking-vs-escalation/` | Booking created while the space escalates to out-of-service; missed affected-booking identification | OP-01/02/03 × OP-05 | BR-44, BR-48 |
| `CC-04-advisory-vs-booking/` | Advisory recorded while a booking captures its snapshot + acknowledgement | OP-01/02/03 × OP-04 | BR-45, BR-46 |
| `CC-05-escalate-vs-downgrade/` | Concurrent escalation/downgrade of the same maintenance record (lost update) | OP-05 × OP-06 | BR-47 |

## 4. How to run a scenario in SSMS

For every scenario, open **two** separate Query windows connected to the same
`CS486_Booking_System` database.

1. Run `procedure.sql` in a separate window (or deploy it once) to create the
   version of the procedure used by the test.
2. In Session 1, run `session-1.sql`. It begins, performs the first step, and
   waits (`WAITFOR DELAY`) at the point where the conflict window is open.
3. While Session 1 is waiting, run `session-2.sql` in Session 2. It begins its
   transaction and attempts the second step.

### With enforcement
The second statement blocks on the lock held by Session 1 (you can observe the
lock wait). Only after Session 1 commits does Session 2 proceed — and it then
sees the *fresh* committed state and is rejected (conflict prevented).

### Without enforcement
Session 2 does **not** block; both statements read the same pre-commit state and
both commit — the invariant is violated (conflict reproduced).

## 5. Verifying the result

Both `session-1.sql` and `session-2.sql` end with a `SELECT` over the affected
tables so you can see the final state.

| Conflict | Expected `with enforcement` | Expected `without enforcement` |
|----------|----------------|----------------|
| CC-01 | Only **1** approved booking exists for the space/period | **2** overlapping approved bookings |
| CC-02 | Only **1** approved booking; the slower approval is rejected | **2** overlapping approved bookings |
| CC-03 | Either no booking exists OR the escalation finds it; the requested period holds BR-44 | The booking commits on the now-out-of-service space; identification misses it |
| CC-04 | Either the acknowledgement reflects the advisory, or the advisory commits outside the booking-time window | Booking commits with `advisory_acknowledged = NULL` *while* the advisory was active |
| CC-05 | Impact level equals the second *committed* change; no committed change lost | Last-writer-wins leaves the record in the wrong level (one decision lost) |

## 6. Important notes

- Every test uses deterministic, small inline records so it is independent of the
  seeded sample data. `session-1`/`session-2` scripts record their own reference
  input where needed.
- `WAITFOR DELAY` timing is approximate. If the second session finishes before the
  first starts waiting, re-run Session 1 (or lengthen the delay) so the 
  interleaving is preserved.
- To re-run a scenario cleanly, restore the affected rows (delete the test
  bookings / maintenance rows) or reload the baseline sample data.