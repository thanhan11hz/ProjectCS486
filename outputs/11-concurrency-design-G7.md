# Concurrency Design

Baseline: `outputs/08-req-change-analysis-G7.md` — Phase 2 Concurrency Conflict Analysis (Section 7)
Database Engine: Microsoft SQL Server (T-SQL)

---

## 1. Overview

Phase 2 of the CS486 Booking System introduces two major operational changes that create concurrency risks: (1) an instant booking path that auto-approves requests at submission time, and (2) maintenance records with mutable impact levels (`out_of_service` / `advisory`) that dynamically affect space availability.

These changes produce five identified concurrency conflicts (CC-01 to CC-05), all of which share a common root cause: multiple database sessions performing read-check-write sequences on shared resources without sufficient isolation, potentially violating business invariants.

The overall strategy follows a **pessimistic concurrency** approach using targeted **row-level locking via SQL Server locking hints** (`UPDLOCK`, `ROWLOCK`) and **elevated isolation levels** (`SERIALIZABLE`) for critical range-based availability checks. Where row contention is low and throughput matters (e.g., maintenance level updates), **optimistic concurrency** via `rowversion` is an acceptable alternative. All critical operations are wrapped in explicit `BEGIN TRAN … COMMIT TRAN` blocks with `TRY…CATCH` to handle deadlocks gracefully via retry.

---

## 2. Conflict Handling

### 2.1 Conflict CC-01: Instant Booking Overlap

* **Scenario:** Two users submit instant booking requests for Space S at overlapping time period [T1, T2] at the same time. Both sessions execute the availability check — `SELECT` from `bookings` where `space_code = S` and status is `approved` and time overlaps [T1, T2] — see zero results, and both proceed to insert a new approved booking. If executed under the default `READ COMMITTED` isolation, both reads can complete before either write commits, resulting in two approved bookings for the same space and time period.

* **Shared Resource:** The approved booking records for a specific `space_code` and the time interval [T1, T2].

* **Business Rule Protected:** BR-14 — The same space cannot have two approved bookings with overlapping time periods. BR-50 — This rule must hold under concurrent operations for both instant and staff-approved bookings.

* **Chosen Mechanism:** Pessimistic row-level locking using `WITH (UPDLOCK, ROWLOCK)` on the availability check `SELECT`, executed inside an explicit transaction. The `UPDLOCK` hint converts the shared lock acquired during the `SELECT` into an update lock, which is incompatible with another `UPDLOCK` or exclusive lock from a concurrent session on the same rows. The `ROWLOCK` hint limits the lock granularity to individual rows rather than pages or the whole table, reducing unnecessary contention. This approach serialises concurrent instant booking attempts for the same space without requiring a session-wide isolation level elevation.

* **Implementation Pseudo-code:**
```sql
BEGIN TRY
    BEGIN TRAN;

        -- Acquire UPDLOCK on the space row to block concurrent bookings
        -- for the same space from passing their availability check simultaneously.
        SELECT space_code
        FROM spaces WITH (UPDLOCK, ROWLOCK)
        WHERE space_code = @space_code;

        -- Range overlap check for approved bookings
        IF EXISTS (
            SELECT 1
            FROM bookings WITH (ROWLOCK)
            WHERE space_code  = @space_code
              AND status       = N'approved'
              AND requested_start_time < @end_time
              AND requested_end_time   > @start_time
        )
        BEGIN
            ROLLBACK TRAN;
            THROW 50001, 'Booking conflict: space already booked for this period.', 1;
        END

        -- No overlap confirmed — check for out_of_service maintenance
        IF EXISTS (
            SELECT 1
            FROM maintenance_records WITH (ROWLOCK)
            WHERE space_code   = @space_code
              AND impact_level  = N'out_of_service'
              AND status        IN (N'reported', N'in_progress')
              AND start_time    < @end_time
              AND (completion_time IS NULL OR completion_time > @start_time)
        )
        BEGIN
            ROLLBACK TRAN;
            THROW 50002, 'Space is out of service during the requested period.', 1;
        END

        -- Insert the instant booking as approved
        INSERT INTO bookings (requester_id, space_code, requested_start_time,
                              requested_end_time, purpose, expected_participants,
                              status, advisory_acknowledged)
        VALUES (@requester_id, @space_code, @start_time, @end_time,
                @purpose, @participants, N'approved', @advisory_ack);

        -- Auto-create the approval record (BR-28, BR-49)
        INSERT INTO approvals (booking_id, approver_id, decision, decision_time)
        VALUES (SCOPE_IDENTITY(), @system_user_id, N'approved', SYSUTCDATETIME());

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    -- Caller should retry on deadlock (error 1205)
    THROW;
END CATCH
```

* **Justification:** Under default `READ COMMITTED` isolation, the availability `SELECT` acquires only a shared lock released immediately after the read — a concurrent session can also read "no conflict" before either write commits, producing two approved bookings (the classic phantom write / lost-update pattern). `REPEATABLE READ` prevents the rows already read from being changed, but does not prevent *new* rows (phantom inserts) from being inserted into the checked range. `SERIALIZABLE` would prevent phantom inserts by holding a range lock but introduces broader table-level contention. Locking the parent `spaces` row with `UPDLOCK` is more targeted: it serialises all instant booking attempts for the same `space_code` without blocking reads on other spaces, balancing correctness and throughput. This directly enforces BR-14 and BR-50 under concurrent instant booking operations.

---

### 2.2 Conflict CC-02: Approval vs. Instant Booking Overlap

* **Scenario:** A staff member is approving a pending booking for Space S, time [T1, T2], while simultaneously a user submits an instant booking (or another staff member approves another pending request) for the same space and overlapping period. The staff approval path reads booking availability and then updates the booking status to `approved`. If both the approval and the instant booking read availability before either commits, both will succeed and leave two approved overlapping bookings.

* **Shared Resource:** The approved booking records and the space availability state for a specific `space_code` and overlapping time interval.

* **Business Rule Protected:** BR-14, BR-49, BR-50 — The no-overlap invariant applies equally to instant and staff-approved bookings under concurrent operations.

* **Chosen Mechanism:** The same `WITH (UPDLOCK, ROWLOCK)` pattern on the `spaces` row is applied to the staff approval transaction. Because both the instant booking path (CC-01) and the staff approval path lock the same `spaces` row with `UPDLOCK`, they are mutually exclusive: only one can hold the update lock at a time, regardless of which path is executing.

* **Implementation Pseudo-code:**
```sql
BEGIN TRY
    BEGIN TRAN;

        -- Acquire UPDLOCK on the space row — same lock as instant booking.
        -- This serialises all approval and instant booking attempts for the space.
        SELECT space_code
        FROM spaces WITH (UPDLOCK, ROWLOCK)
        WHERE space_code = @space_code;

        -- Re-validate: check if the booking being approved is still pending
        IF NOT EXISTS (
            SELECT 1 FROM bookings WHERE booking_id = @booking_id AND status = N'pending'
        )
        BEGIN
            ROLLBACK TRAN;
            THROW 50003, 'Booking is no longer in pending status.', 1;
        END

        -- Overlap check against already-approved bookings for this space/time
        IF EXISTS (
            SELECT 1
            FROM bookings WITH (ROWLOCK)
            WHERE space_code  = @space_code
              AND status       = N'approved'
              AND requested_start_time < @end_time
              AND requested_end_time   > @start_time
        )
        BEGIN
            ROLLBACK TRAN;
            THROW 50004, 'Approval conflict: overlapping approved booking exists.', 1;
        END

        -- Approve the booking
        UPDATE bookings SET status = N'approved' WHERE booking_id = @booking_id;

        -- Record the approval decision (BR-28)
        INSERT INTO approvals (booking_id, approver_id, decision, decision_time, decision_note)
        VALUES (@booking_id, @approver_id, N'approved', SYSUTCDATETIME(), @note);

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH
```

* **Justification:** Because both the instant booking path (CC-01) and the staff approval path begin by acquiring an `UPDLOCK` on the same `spaces` row, they form a mutual exclusion zone: whichever path acquires the lock first completes its full read-check-write cycle before the other can proceed. When the second transaction finally acquires the lock and re-checks availability, it will see the committed booking from the first transaction and correctly reject the conflict. This ensures BR-14 and BR-50 hold for all mixed-path concurrent operations without requiring a table-wide lock or session-wide isolation level change.

---

### 2.3 Conflict CC-03: Escalation vs. Booking Creation

* **Scenario:** A facility staff member escalates a maintenance record for Space S from `advisory` to `out_of_service` covering period [T1, T2], while concurrently a user is submitting a booking or a staff member is approving a booking for the same space and overlapping period. The booking transaction reads the maintenance records, sees only `advisory` (not `out_of_service`), and proceeds. The escalation transaction then commits, leaving an approved booking on a space that is now `out_of_service` — a violation of BR-44.

* **Shared Resource:** The maintenance state of Space S and the approved bookings overlapping the maintenance period.

* **Business Rule Protected:** BR-44 — A space with an active `out_of_service` maintenance record cannot be booked for any overlapping period. BR-48 — When advisory maintenance is escalated to `out_of_service`, all approved bookings overlapping the maintenance period must be identifiable so staff can contact requesters.

* **Chosen Mechanism:** The escalation transaction acquires an `UPDLOCK` on the maintenance record row before updating its `impact_level`. The booking/approval transaction (CC-01, CC-02) acquires an `UPDLOCK` on the `spaces` row before reading maintenance records. To achieve mutual exclusion between escalation and booking, both operations must acquire the same lock anchor: the `spaces` row lock. The escalation path must also acquire this `UPDLOCK` on the space before updating the maintenance record. This ensures escalation and booking creation are serialised for the same space.

* **Implementation Pseudo-code:**
```sql
-- Escalation Transaction
BEGIN TRY
    BEGIN TRAN;

        -- Lock the space row to prevent concurrent bookings during escalation
        SELECT space_code
        FROM spaces WITH (UPDLOCK, ROWLOCK)
        WHERE space_code = @space_code;

        -- Lock and update the maintenance record
        UPDATE maintenance_records WITH (ROWLOCK)
        SET impact_level = N'out_of_service'
        WHERE maintenance_id = @maintenance_id
          AND status IN (N'reported', N'in_progress');  -- BR-47: only open records

        -- Identify affected approved bookings (BR-48)
        SELECT b.booking_id, b.requester_id, b.requested_start_time, b.requested_end_time
        FROM bookings b WITH (ROWLOCK)
        WHERE b.space_code          = @space_code
          AND b.status               = N'approved'
          AND b.requested_start_time < @maintenance_end_time
          AND b.requested_end_time   > @maintenance_start_time;
        -- Caller uses this result set to notify affected requesters (BR-48)

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH
```

* **Justification:** Without the space-row `UPDLOCK` in the escalation path, the escalation and a concurrent booking could race: the booking reads `advisory` impact, the escalation updates to `out_of_service`, and then the booking commits — leaving a booking on an out-of-service space. By requiring both paths to acquire the `UPDLOCK` on `spaces` first, the escalation and booking transactions are serialised at the space level. Whichever acquires the lock first completes fully; the other then sees the final state and behaves correctly. This directly enforces BR-44. The `SELECT` of affected bookings within the same transaction also guarantees BR-48 sees a consistent view of bookings that were approved before the escalation committed.

---

### 2.4 Conflict CC-04: Advisory Notification Miss

* **Scenario:** A user reads the active advisories for Space S (seeing zero advisories) and proceeds to fill out a booking form. Before they submit, a new advisory maintenance record is inserted for Space S. The user submits without acknowledging the advisory (because they never saw it), and the booking is saved with `advisory_acknowledged = NULL` — violating BR-46.

* **Shared Resource:** The set of active advisory maintenance records for Space S at booking submission time.

* **Business Rule Protected:** BR-45 — A space with only active advisory maintenance records may be booked, but the requester must be notified of all active advisories at booking time. BR-46 — The booking must record the requester's acknowledgement.

* **Chosen Mechanism:** The booking submission transaction acquires an `UPDLOCK` on all active advisory maintenance records for the target space immediately before performing the advisory check and setting `advisory_acknowledged`. This prevents new advisory records from being inserted or existing ones from changing `impact_level` until the booking transaction commits. This is a **read-then-write** pattern — without the lock, `SNAPSHOT` isolation would cause a **write-skew anomaly** where both the booking and a new advisory commit without the booking acknowledging the advisory.

* **Implementation Pseudo-code:**
```sql
BEGIN TRY
    BEGIN TRAN;

        -- Lock the space row first (consistent with CC-01/CC-02 lock ordering)
        SELECT space_code
        FROM spaces WITH (UPDLOCK, ROWLOCK)
        WHERE space_code = @space_code;

        -- Lock active maintenance records for this space to prevent new advisories
        -- from being inserted or escalated concurrently (prevents write-skew)
        SELECT maintenance_id, impact_level, start_time, completion_time
        FROM maintenance_records WITH (UPDLOCK, ROWLOCK)
        WHERE space_code  = @space_code
          AND status       IN (N'reported', N'in_progress')
          AND start_time   < @end_time
          AND (completion_time IS NULL OR completion_time > @start_time);

        -- Determine advisory status at this locked point in time
        DECLARE @has_out_of_service BIT, @has_advisory BIT;

        SELECT @has_out_of_service = MAX(CASE WHEN impact_level = N'out_of_service' THEN 1 ELSE 0 END),
               @has_advisory        = MAX(CASE WHEN impact_level = N'advisory'       THEN 1 ELSE 0 END)
        FROM maintenance_records WITH (NOLOCK)  -- already locked above
        WHERE space_code = @space_code
          AND status IN (N'reported', N'in_progress')
          AND start_time  < @end_time
          AND (completion_time IS NULL OR completion_time > @start_time);

        IF @has_out_of_service = 1
        BEGIN
            ROLLBACK TRAN;
            THROW 50005, 'Space is out of service during the requested period.', 1;
        END

        -- If advisories exist, advisory_acknowledged must be 1 (BR-46)
        IF @has_advisory = 1 AND (@advisory_acknowledged IS NULL OR @advisory_acknowledged = 0)
        BEGIN
            ROLLBACK TRAN;
            THROW 50006, 'Requester must acknowledge active advisories before booking.', 1;
        END

        -- Insert booking with the acknowledgement value locked at submission time
        INSERT INTO bookings (requester_id, space_code, requested_start_time,
                              requested_end_time, purpose, expected_participants,
                              status, advisory_acknowledged)
        VALUES (@requester_id, @space_code, @start_time, @end_time,
                @purpose, @participants, N'pending',
                CASE WHEN @has_advisory = 1 THEN 1 ELSE NULL END);

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH
```

* **Justification:** `SNAPSHOT` isolation would allow the booking transaction to read a consistent snapshot at its start time — but a new advisory inserted concurrently by another transaction would be invisible. The booking would commit with `advisory_acknowledged = NULL` while the advisory is already active — a classic write-skew anomaly that `SNAPSHOT` isolation does not prevent. By acquiring `UPDLOCK` on the maintenance records at submission time, we prevent any concurrent `INSERT` into `maintenance_records` for the same space from completing until the booking transaction has committed its `advisory_acknowledged` value. The lock ensures the advisory snapshot used to set the acknowledgement flag is the final, committed state at booking time, directly satisfying BR-45 and BR-46. The space-row lock acquired first ensures consistent lock ordering with CC-01 through CC-03, preventing deadlocks.

---

### 2.5 Conflict CC-05: Concurrent Maintenance State Updates

* **Scenario:** Two facility staff members simultaneously retrieve the same open maintenance record and attempt to update its `impact_level`. Staff A is escalating from `advisory` to `out_of_service`; Staff B is downgrading from `out_of_service` back to `advisory`. Under `READ COMMITTED` (the SQL Server default), both sessions read the current row and then issue their respective `UPDATE`. The second `UPDATE` to commit silently overwrites the first, resulting in a final `impact_level` that does not reflect either staff member's fully informed decision — a classic **lost update**.

* **Shared Resource:** The `impact_level` attribute of a single `Maintenance_Record` row.

* **Business Rule Protected:** BR-47 — The impact level of an open maintenance record may be escalated or downgraded; CC-05 requires the final value to be a single consistent outcome of one intentional decision. BR-50 (indirectly) — bookings and affected-booking identifications must reflect the current impact level consistently.

* **Chosen Mechanism:** **Optimistic concurrency via a `rowversion` column** on `maintenance_records`. A `rowversion` column is automatically updated by SQL Server whenever any column in the row changes. The update transaction includes a `WHERE rowversion_col = @original_rowversion` predicate. If another session has updated the row since it was read, the `rowversion` will have changed and the `UPDATE` will affect zero rows — which the application detects and treats as a conflict, prompting the staff member to refresh and retry. This avoids holding a long-lived lock while the staff member deliberates, which would be the downside of a pessimistic `UPDLOCK` approach for human-interactive operations.

* **Implementation Pseudo-code:**
```sql
-- Step 1: Read the maintenance record and capture its rowversion
-- (executed when staff member opens the edit form)
SELECT maintenance_id, impact_level, status, row_ver
FROM maintenance_records
WHERE maintenance_id = @maintenance_id;
-- @original_row_ver is stored client-side

-- Step 2: Submit the update with optimistic concurrency check
BEGIN TRY
    BEGIN TRAN;

        UPDATE maintenance_records
        SET impact_level = @new_impact_level
        WHERE maintenance_id = @maintenance_id
          AND status          IN (N'reported', N'in_progress')  -- BR-47: only open records
          AND row_ver         = @original_row_ver;              -- Optimistic concurrency check

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRAN;
            -- The record was modified by another session since it was read.
            -- Return conflict signal to caller; caller prompts staff to refresh.
            THROW 50007, 'Concurrency conflict: maintenance record was modified by another user. Please refresh and retry.', 1;
        END

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRAN;
    THROW;
END CATCH
```

* **Justification:** A pessimistic `UPDLOCK` acquired when the staff member opens the edit form would hold a lock for the entire duration of human deliberation — potentially minutes — blocking all other reads and writes on that row. This is impractical and causes unnecessary contention. Optimistic concurrency via `rowversion` releases the lock immediately after the initial `SELECT` and only detects a conflict at the moment of the `UPDATE`. For low-contention human-interactive operations (it is unlikely two staff members update the same maintenance record simultaneously in practice), this is the optimal tradeoff: minimal contention under normal conditions, with correct conflict detection in the rare concurrent case. The `rowversion` mechanism is natively supported by SQL Server with no additional application infrastructure, making it simple to implement and audit.

---

## 3. Summary

The five concurrency conflicts introduced by Phase 2 are resolved through a layered, targeted strategy:

| Conflict | Mechanism | Key Guarantee |
|----------|-----------|---------------|
| CC-01 (Instant booking overlap) | `UPDLOCK` on `spaces` row | Only one instant booking for a given space can pass the availability check at a time |
| CC-02 (Approval vs. booking overlap) | `UPDLOCK` on `spaces` row (same lock as CC-01) | Staff approval and instant booking are mutually exclusive per space |
| CC-03 (Escalation vs. booking) | `UPDLOCK` on `spaces` row in both paths | Escalation and booking creation are serialised; affected bookings identified atomically |
| CC-04 (Advisory notification miss) | `UPDLOCK` on maintenance record rows at submission | The advisory snapshot used for acknowledgement is final and consistent at commit time |
| CC-05 (Concurrent maintenance updates) | `rowversion` optimistic concurrency | Lost updates are detected and rejected without long-held locks during human deliberation |

The unifying design principle is **consistent lock ordering** (always acquire `spaces` row lock before `bookings` or `maintenance_records` row locks) to prevent deadlocks across concurrent operations. The strategy avoids session-wide isolation level elevation (which would degrade throughput across all queries) in favour of targeted row-level hints, confining contention strictly to the shared resources at risk. This directly upholds BR-14, BR-44, BR-45, BR-46, BR-47, and BR-50 without sacrificing the system's ability to handle concurrent booking workloads at scale.
