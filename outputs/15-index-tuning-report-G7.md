# CS486 Booking System — Query Tuning Analysis (Stage 15 / Group 7)

| Artifact | `outputs/15-index-tuning-report-G7.md` |
|---|---|
| Companion script | `outputs/15-index-tuning-G7.sql` |
| Baseline schema | `outputs/05-db-implementation-G7.sql` |
| Migration | `outputs/10-schema-migration-G7.sql` |
| Dataset | `outputs/14-data-generator-G7.sql` (>= 100,000 bookings, 3 academic years + autumn 2026) |
| Reporting queries | `outputs/16-analytical-queries-G7.sql` (Q1-Q4) |
| Empirical results | `docs/15-index-tuning-results-G7.md` (cold-cache timings captured on the >= 100,000-record benchmark) |
| Plan evidence | `docs/QueryPlan.sqlplan` (operator lists and estimated costs of the baseline and post-tuning plans) |
| DBMS | Microsoft SQL Server 2019+ (validated on SQL Server 2025, Build 17.0.1000.7) |
| Author | Group 7 |

---

## 1. Objective

Design, implement and benchmark targeted non-clustered, covering and filtered
index strategies for the four key workload operations designated by Phase 2
Stage 15, and the additional maintenance-escalation analytical query:

1. **W1 — Booking Conflict Check** (BR-14 / BR-50 availability probe, hot
   transactional path of every booking submission and approval).
2. **W2 — Multi-Criteria Room Finder** (Stage 16 **Q3**).
3. **W3 — Total Approved Booking Hours per Space** (Stage 16 **Q1**).
4. **W4 — Booking Density Heatmap, Weekday x Hour** (Stage 16 **Q2**).
5. **W5 — Maintenance Escalation Impact** (Stage 16 **Q4**, BR-48).

W3 and W4 are the two reporting queries that `outputs/16-analytical-queries-G7.sql`
formally designated for detailed execution-plan analysis and index tuning. W5 is
added because the Skill's index strategy includes the maintenance-escalation
impact index; it is benchmarked so that every recommended index is justified by
workload characteristics and execution plans (project design rule).

---

## 2. Workload and Dataset Profile

The tuned database carries the following characteristics. The row counts were
verified empirically against the populated instance before benchmarking:

| Object | Row count | Notes |
|---|---|---|
| `bookings` | 125,971 (verified) | clustered PK `booking_id` (INT IDENTITY); ~3,150 rows/space |
| `maintenance_records` | 3,100 (verified) | only OPEN rows (status reported/in_progress) are ever read |
| `users` | 1,500 (verified) | PK `user_id` (VARCHAR) |
| `spaces` | 40 (verified) | PK `space_code` (VARCHAR) |
| `facilities` | 18 | PK `facility_id` (INT IDENTITY) |
| `space_facilities` | ~150 | clustered PK `(space_code, facility_id)` |

Because the clustered key of `bookings` is `booking_id` (not space/time), every
space- or time-based access path begins as a **clustered index scan** of
~126,000 rows before tuning. This is the single dominant cost across all five
workloads.

**Status semantics.** An *effective reservation* is any booking with
`status IN ('approved','checked_in','completed','no_show')`. W1 and W5 restrict
to `status = 'approved'` only (BR-14/BR-50 and BR-48 semantics, matching the
concurrency procedures in `outputs/12-concurrency-implementation-G7.sql`).

---

## 3. Methodology

Every measured workload uses an identical harness (implemented in
`outputs/15-index-tuning-G7.sql`):

1. **Cold-cache preparation** before each run:
   `CHECKPOINT` -> `DBCC DROPCLEANBUFFERS` -> `DBCC FREEPROCCACHE`, so every
   execution is measured on an empty buffer pool and a freshly compiled plan
   (worst case, identical for the before/after comparison).
2. **Profiling**: `SET STATISTICS TIME ON` (CPU / elapsed), `SET STATISTICS IO ON`
   (logical reads / scan counts) — captured in the Messages tab.
3. **Inline timing**: `SYSDATETIME()`/`DATEDIFF(MILLISECOND, ...)` emits an
   explicit `execution_time_ms` row per workload.
4. **PRINT headers** label every block (workload + BASELINE/POST-TUNING) so
   statistics output maps unambiguously to a measurement.
5. **Phase sequence**: Section 4.0 drops any previously created tuned indexes
   (clean baseline on every re-run) -> Section 4 baselines W1-W5 -> Section 5
   creates the indexes -> Section 6 re-runs W1-W5 identically.

The baseline phase therefore measures the database with *only* the clustered
primary keys and unique constraints from Phases 1-2. Section 8 (cleanup) or
Section 4.0 alone restores that state for re-measurement.

The empirical metrics from one full run over the >=100,000-record dataset are
recorded in `docs/15-index-tuning-results-G7.md` and are reproduced and analyzed
in Sections 6 and 7 of this report. **Verification run:** the harness
(`outputs/15-index-tuning-G7.sql`) was executed end-to-end again on 2026-08-10
against the same populated instance (SQL Server 2025) while this report was being
updated. The script compiled and ran to completion with no errors; the five
filtered/covering indexes (I-1 .. I-5) were created, used and then dropped by the
cleanup, and the recorded times were reproduced within timing noise (W1 7->1 ms,
W2 200->64 ms, W3 33->15 ms, W4 22->8 ms, W5 18->2 ms vs the recorded
197->64 ms, 31->15 ms, 23->7 ms, 19->3 ms). The plan evidence in Section 6 was
extracted from `docs/QueryPlan.sqlplan`, which was captured during the recorded
run.

---

## 4. Index Strategy — Design and Justification

**Five** indexes are implemented (I-1 .. I-5). All filtered-index filters use
**plain VARCHAR literals** because the filter columns are `VARCHAR(20)` — see
Section 5, which documents the decisive finding of this stage.

| ID | Index | Keys | Include | Filter | Serves |
|---|---|---|---|---|---|
| I-1 | `ix_bookings_conflict_approved` | `(space_code, requested_start_time, requested_end_time)` | — | `status = 'approved'` | W1 conflict probe; BR-48 escalation select; W5 bookings join |
| I-2 | `ix_bookings_space_effective_covering` | `(space_code, requested_start_time)` | `requested_end_time` | `status IN (approved, checked_in, completed, no_show)` | W3 (Q1) per-space semester aggregation; W2 (Q3) bookings anti-join |
| I-3 | `ix_bookings_status_semester_covering` | `(requested_start_time)` | — | `status IN (approved, checked_in, completed, no_show)` | W4 (Q2) heatmap aggregation |
| I-4 | `ix_maintenance_open_covering` | `(space_code, impact_level, start_time, completion_time)` | — | `status IN (reported, in_progress)` | BR-44/BR-45 probes; W2 (Q3) maintenance anti-join |
| I-5 | `ix_bookings_escalation_impact` | `(space_code)` | `requested_start_time, requested_end_time, requester_id` | `status = 'approved'` | W5 (Q4) escalation impact report |

### Index descriptions

A short description of each index, before the per-index rationale:

* **I-1 `ix_bookings_conflict_approved`** — a filtered index that isolates the
  `approved` bookings of each space, ordered by the requested period. It exists
  so the booking-conflict availability probe (W1) and the BR-48 escalation select
  can answer "is this space free in this window?" from a tiny approved-only
  subset instead of the whole booking history.
* **I-2 `ix_bookings_space_effective_covering`** — a filtered covering index over
  the effective-reservation statuses, ordered by space then requested start time.
  It serves both the semester space-utilisation report (W3/Q1, per-space
  aggregation of booking hours) and the bookings anti-join of the room finder
  (W2/Q3, "does any reservation overlap the target period?").
* **I-3 `ix_bookings_status_semester_covering`** — a filtered covering index
  over the effective-reservation statuses, keyed on `requested_start_time`
  alone. It is shaped for the weekday x hour heatmap (W4/Q2), which aggregates
  the whole semester but has **no** `space_code` predicate. The filtered
  predicate already restricts the index to the effective statuses, so `status`
  would be a constant-valued key column and is deliberately **dropped from the
  key**; the single-column key on `requested_start_time` turns the baseline
  full-scan + sort into a narrow semester seek.
* **I-4 `ix_maintenance_open_covering`** — a filtered covering index over only
  the open (`reported` / `in_progress`) maintenance records, ordered by space,
  impact level and period. It serves the BR-44 out-of-service and BR-45 advisory
  overlap probes and the maintenance anti-join of the room finder (W2/Q3).
* **I-5 `ix_bookings_escalation_impact`** — a filtered covering index over the
  `approved` bookings of each space that additionally carries the booking period
  and requester id. It is shaped exactly for the maintenance escalation impact
  report (W5/Q4), which joins approved bookings to a maintenance record by space
  and then to the requester's contact data.

### Considered but removed — `ix_spaces_capacity`

An earlier draft also created a capacity-leading index on `spaces`
(`(capacity, space_code)`) so the room finder (W2/Q3) could seek the
`capacity >= @RequiredCapacity` filter instead of scanning the cluster. It is
**not** part of the final design: `spaces` has only **40 rows**, and the
optimizer never selects the index — both the baseline and the post-tuning W2
plans (Section 6) read `spaces` via a **Clustered Index Scan on `pk_spaces`**
(est. 12 rows after the capacity filter). A non-clustered index cannot beat a
40-row clustered scan, so the index would add storage and write-path overhead
for zero benefit. The script still cleans up the legacy index if an older
version created it.

### Considered but removed — `ix_space_facilities_facility_covering`

An earlier draft also created a facility-leading covering index on
`space_facilities` (`(facility_id, space_code)`) for the W2 (Q3) relational
division. It is **not** part of the final design: `space_facilities` is tiny
(~150 rows), and the observed post-tuning W2 plan (Section 6) shows the division
is resolved against the clustered PK `(space_code, facility_id)` at negligible
cost. Dropping it keeps the design lean (no storage / write-path overhead). The
script still cleans up the legacy index if an older version created it.

### Key vs INCLUDE — deciding column placement

SQL Server stores **KEY** columns at every level of the non-clustered index
B-tree and **INCLUDE** columns only in the leaf level (together with the
clustered-key row locator). The placement rule applied to all five indexes:

* **KEY** — columns that participate in a **seek** (equality predicates such as
  `space_code = @x`, `impact_level = 'out_of_service'`; seekable range predicates
  such as `requested_start_time < @end`, `capacity >= @n`) or in `ORDER BY` /
  `GROUP BY`. They define the index order, and the optimizer can only use the
  index from its leftmost prefix, so the most-restricting / leading-predicate
  columns come first. A column that must be seeked (or must order the result)
  **has to be a key** — INCLUDE columns can never restrict a seek or supply
  ordering.
* **INCLUDE** — columns needed **only** to make the index covering: values that
  appear in the `SELECT` list, in non-seekable *residual* predicates, or in
  aggregations, but that never restrict the seek and never order the result.
  Storing them in INCLUDE avoids a key lookup into the clustered index without
  inflating the upper B-tree levels (they are physically present only at the
  leaf). A column that is neither seeked nor ordered should go to INCLUDE, never
  to the key, to keep the key narrow.

Applied per index (what is a key and why, what is included and why):

| Index | KEY columns — why in KEY | INCLUDE columns — why in INCLUDE |
|---|---|---|
| I-1 `ix_bookings_conflict_approved` | `space_code` (equality), `requested_start_time` (range seek `< @ConflictEnd`), `requested_end_time` (overlap residual — kept as a key so the probe is fully covered without a separate INCLUDE list) | — none: the probe projects nothing beyond existence, and `booking_id` (clustered key) is the row locator |
| I-2 `ix_bookings_space_effective_covering` | `space_code` (equality join), `requested_start_time` (semester range seek) | `requested_end_time` — used only by the `DATEDIFF` hours expression and the `> @TargetStart` overlap residual; not seeked, so kept out of the key to keep it narrow |
| I-3 `ix_bookings_status_semester_covering` | `requested_start_time` (semester range seek). `status` is NOT a key: the filtered predicate already restricts the index to the effective statuses, so it would be constant-valued and redundant | — none: Q2 projects only `requested_start_time`-derived expressions and `COUNT(*)`, so no INCLUDE column is needed |
| I-4 `ix_maintenance_open_covering` | `space_code` (equality), `impact_level` (equality — BR-44 `out_of_service` vs BR-45 `advisory` probe), `start_time` (range), `completion_time` (open-record overlap residual — kept as a key so no INCLUDE is needed) | — none |
| I-5 `ix_bookings_escalation_impact` | `space_code` (equality join to `maintenance_records`). `status` is NOT a key: the filtered predicate `status = 'approved'` already restricts the rows, so it would be constant-valued and redundant | `requested_start_time`, `requested_end_time` (overlap residual evaluated after the space seek, never seeked themselves), `requester_id` (only drives the `users` join; no predicate) |

### Justification per index

* **I-1 (conflict probe).** The conflict check is the hottest transactional
  query: it runs on every booking submission (`usp_submit_instant_booking`,
  `usp_submit_booking_pending`), every approval (`usp_approve_pending_booking`)
  and every escalation (`usp_escalate_maintenance_impact`). Filtering to
  `status = 'approved'` keeps the index to the small subset of history that
  actually reserves the space, and the filtered statistics describe exactly the
  rows the probe reads. The probe predicate
  `space_code = @x AND requested_end_time > @s AND requested_start_time < @e` is
  fully covered by the keys, so no key lookup is needed.
* **I-2 (space/time covering).** W3 (Q1) joins per space on the semester range
  and aggregates `DATEDIFF(MINUTE, start, end)` — both start and end are covered.
  W2 (Q3) seeks `(space_code, requested_start_time < @TargetEnd)` and needs
  `requested_end_time > @TargetStart` for the overlap test. Filtering to the
  effective-reservation statuses discards cancelled/rejected/pending history.
* **I-3 (semester covering).** W4 (Q2) has **no** `space_code` predicate, so
  space-leading indexes cannot help. The filtered predicate already restricts
  the rows to the effective-reservation statuses, so `status` is constant-valued
  in the key and is deliberately dropped; the single-column key on
  `requested_start_time` lets the optimizer seek the semester window and compute
  the two `DATEPART` expressions and `COUNT(*)` from the leaf only. Q2 projects
  no column other than `requested_start_time`-derived expressions and the row
  count, so **no INCLUDE column is needed** — adding `space_code` would only
  enlarge the leaf and the write path for no benefit.
* **I-4 (open maintenance covering).** Only open records affect availability
  (BR-44/BR-45); of ~3,100 maintenance rows the index stores only the open ones.
  `impact_level` is a key so the BR-44 (`out_of_service`) and BR-45 (`advisory`)
  probes each seek a single narrow range.
* **I-5 (escalation impact).** W5 (Q4) joins bookings by `space_code` with
  `status = 'approved'` and the BR-48 overlap predicate, then projects requester
  contact data. I-1 covers space+time but not `requester_id`, forcing a key
  lookup; I-5 is a tight covering index shaped to the exact Q4 projection, so the
  `users` join can be driven directly by the seeked `requester_id`.

### Write-path cost

The booking hot path now maintains the clustered PK plus **four** non-clustered
indexes per INSERT (I-1, I-2, I-3, I-5). All four are **filtered**, so a row is
written into each only when it matches the filter. For example, a `cancelled` or
`rejected` row matches no filter at all and is written to none of them; an
`approved` row is written to all four (I-1, I-2, I-3, I-5). Maintenance cost is
therefore bounded and is the accepted price for eliminating ~126,000-row scans
from every booking decision and the semester reports.

---

## 5. Critical Finding — Msg 10611 and Filtered-Index Literal Typing

### 5.1 The defect discovered in the draft harness

The original draft of `outputs/15-index-tuning-G7.sql` wrote filtered-index
filters and benchmark predicates with **NVARCHAR literals** (`N'approved'`,
`N'reported'`, ...). The filter columns (`bookings.status`,
`maintenance_records.status`, `maintenance_records.impact_level`) are declared
**`VARCHAR(20)`** in the Phase 1 DDL. This is exactly the implicit-conversion
scenario the Skill's Rule A warns about — but in the opposite direction from the
usual example.

### 5.2 Empirical verification (SQL Server 2025, Developer Edition)

Tested directly on a local instance with a probe table of 200,000 rows
(`status VARCHAR(20)`, filtered index `WHERE status = 'approved'`):

| Case | Result |
|---|---|
| `CREATE NONCLUSTERED INDEX ... WHERE status = N'approved'` on a `VARCHAR` column | **Msg 10611** — "…compared with a constant of higher data type precedence…Converting a column to the data type of a constant is not supported for filtered indexes." Index **not created**. |
| Query `WHERE status = N'approved'` (NVARCHAR literal) | **Clustered Index Scan** of all 200,000 rows, plan cost **1.39**, `CONVERT_IMPLICIT(nvarchar(20), status)` in the predicate. Filtered index **not used**. |
| Query `WHERE status = 'approved'` (VARCHAR literal, type-matched) | **Index Seek** on the filtered index, plan cost **0.0033** (~**420x** cheaper). |

Two consequences follow:

1. **Creation fails** with `N'...'` literals on `VARCHAR` columns (Msg 10611).
2. Even if the index existed, a query whose predicate converts the filter column
   (`N'...'` literal) is **not eligible** for the filtered index — the optimizer
   falls back to a full clustered scan.

### 5.3 Resolution applied in `outputs/15-index-tuning-G7.sql`

* All filtered-index filter expressions use plain `VARCHAR` literals:
  `WHERE status = 'approved'`,
  `WHERE status IN ('approved', 'checked_in', 'completed', 'no_show')`,
  `WHERE status IN ('reported', 'in_progress')`.
* All benchmark predicates on `status` and `impact_level` use type-matched
  literals so the plans demonstrate real filtered-index usage.
* `SET QUOTED_IDENTIFIER ON` is set explicitly at the top of the script because
  `sqlcmd` defaults it to OFF, which otherwise fails index creation with Msg 1934.

The verification run (Section 3) confirmed the resolution: the filtered indexes
were created without error, and every post-tuning plan used them via Index Seek
(Section 6).

### 5.4 Cross-artifact note (reported to Stage 16, not modified here)

`outputs/16-analytical-queries-G7.sql` predicates `status` with **NVARCHAR
literals** (`N'approved'`, ...). Per the evidence above, those literals introduce
`CONVERT_IMPLICIT` on the `VARCHAR(20)` column and would prevent the filtered
indexes created in this stage from being selected by the optimizer when the
reporting script is run as-is. Stage 15 owns `outputs/15-index-tuning-G7.sql` only
and therefore does not modify the Stage 16 artifact; the recommended follow-ups
are:

* align the Stage 16 literals to the column type (`'approved'`, ...), or
* parameterize via matching types, or
* if `N'...'` literals must stay, replace the filtered indexes with unfiltered
  covering variants (larger, but immune to the typing issue).

The benchmark harness intentionally measures the type-matched form, which is the
form that can actually use the indexes.

---

## 6. Execution Plan Analysis — Observed Transitions

The transitions below were **observed empirically** on the benchmark run over the
≥ 100,000-record dataset. The operator lists and the estimated subtree costs are
taken from the captured plans in `docs/QueryPlan.sqlplan`. Every workload shifted
from a clustered-index scan of the ~126,000-row `bookings` table (and per-
candidate-space re-scans) to narrow seeks bounded by (a) a single space, (b) a
semester window, or (c) the small approved-subset of the filtered indexes.

| Workload | Baseline plan (observed) | Post-tuning plan (observed) | Transition | Elapsed (base -> post) |
|---|---|---|---|---|
| W1 Conflict Check | **Clustered Index Scan** on `pk_bookings`, status + overlap residual filter (cost 0.0056) | **Index Seek** on `ix_bookings_conflict_approved`, fully covering (cost 0.0033) | Clustered Scan -> **Index Seek**; no key lookups | 6 ms -> 0 ms |
| W2 Room Finder | Bookings anti-join: **Clustered Index Scan** on `pk_bookings` per candidate space; maintenance anti-join: **Clustered Index Scan** on `pk_maintenance_records`; facility division via `pk_space_facilities` (cost 0.082) | Bookings anti-join: **Index Seek** on `ix_bookings_space_effective_covering`; maintenance anti-join: **Index Seek** on `ix_maintenance_open_covering`; facility division still via `pk_space_facilities` (cost 0.063) | Per-space re-scans -> **narrow covering seeks** in both anti-joins | 197 ms -> 64 ms |
| W3 Total Hours (Q1) | **Clustered Index Scan** of `bookings` for the semester window + Hash Match + Sort (cost 1.835) | `spaces` cluster scan (40 rows) + **Index Seek** on `ix_bookings_space_effective_covering` per space (start/end covered) + Stream Aggregate (cost 0.287) | Clustered Scan -> **covering Index Seek**; key lookups eliminated | 31 ms -> 15 ms |
| W4 Heatmap (Q2) | **Clustered Index Scan** of `bookings` + Hash Match + Sort (cost 2.127) | **Index Seek** on `ix_bookings_status_semester_covering` over the semester window + Hash Match + Sort (cost 0.589) | Clustered Scan -> **covering Index Seek** | 23 ms -> 7 ms |
| W5 Escalation (Q4) | `maintenance_id` Clustered Index Seek -> **Clustered Index Scan** of the whole `bookings` history of the space (~11,184 est. rows) -> `users` Clustered Index Seek (cost 1.367) | `maintenance_id` Clustered Index Seek -> **Index Seek** on `ix_bookings_escalation_impact` (~3.7 est. rows) -> `users` Clustered Index Seek (cost 0.035) | bookings re-scan -> **covering Index Seek**; `users` lookups unchanged (PK seeks) | 19 ms -> 3 ms |

### Operator cost shifts per workload

* **W1 — scan to seek on the hot path.** The conflict probe goes from a clustered
  scan of all ~126,000 rows to a single-row-shaped seek on the filtered
  `ix_bookings_conflict_approved` index. The probe predicate
  `space_code = @x AND requested_end_time > @s AND requested_start_time < @e` is
  fully covered by the index keys, so the Index Seek is the only data-access
  operator and no Key Lookup appears. The measured elapsed time collapses from
  6 ms to sub-millisecond (recorded as 0 ms at millisecond resolution).
* **W2 — dominant cost moved out of `bookings`.** Baseline cost concentrates in
  re-scanning `bookings` per candidate space and scanning `maintenance_records`.
  After tuning both anti-joins use narrow covering seeks
  (`ix_bookings_space_effective_covering`, `ix_maintenance_open_covering`), the
  `capacity >= @RequiredCapacity` filter stays on a Clustered Index Scan of the
  40-row `spaces` table via `pk_spaces` (the optimizer never selects a
  non-clustered index there — see Section 4), and the facility division continues
  to use the clustered PK `(space_code, facility_id)` — the captured post plan
  has no facility index, which confirms the decision to remove
  `ix_space_facilities_facility_covering` (Section 4). The estimated plan cost
  drops modestly (0.082 -> 0.063) because the optimizer's row estimates are
  low for the anti-joins, but the *measured* elapsed time drops 197 -> 64 ms
  (3.08x) because the real runtime work of scanning the booking history is
  eliminated.
* **W3 — key-lookup elimination.** The baseline LEFT JOIN scans `bookings` for
  the semester window (est. ~18,552 rows) and aggregates from the clustered data.
  I-2 covers `requested_start_time` and `requested_end_time`, so the per-space
  aggregation (`DATEDIFF` + `COUNT`) reads index leaves only and no key lookup
  remains. Plan cost 1.835 -> 0.287; elapsed 31 -> 15 ms (2.07x).
* **W4 — aggregation over the small approved subset.** I-3 stores only the
  effective-reservation statuses, so the semester aggregation seeks
  `requested_start_time` and computes both `DATEPART` expressions and `COUNT(*)`
  from the leaf, eliminating the full-scan + sort of the baseline. Plan cost
  2.127 -> 0.589; elapsed 23 -> 7 ms (3.29x).
* **W5 — re-scan to covering seek.** Q4's bookings join previously scanned the
  whole `bookings` history of the escalated space (est. ~11,184 rows) after the
  `maintenance_id` PK seek; I-5 includes `requester_id`, `requested_start_time`
  and `requested_end_time`, so the `users` join is driven directly by the seeked
  `requester_id` (a PK seek) with no scan into the bookings cluster. Plan cost
  1.367 -> 0.035 (~39x); elapsed 19 -> 3 ms (6.33x), the largest relative speedup
  of the five workloads.

The dominant cost shift in every workload is the elimination of the ~126,000-row
`bookings` clustered scan, replaced by seeks bounded by (a) a single space, (b) a
semester window, or (c) the small approved-subset of the filtered indexes.

### 6.1 Actual Number of Rows Read — before and after

The "Actual Number of Rows Read" per workload and target table was captured
during the recorded run and added to `docs/15-index-tuning-results-G7.md`
(Section 2). It complements the plan-cost and elapsed-time evidence by
quantifying exactly how many rows each access path touched:

| Workload | Target table | Baseline access | Baseline rows read | Post-tuning access | Post rows read | Reduction |
|---|---|---|---|---|---|---|
| W1 | `bookings` | Clustered Index Scan | 125,971 | Index Seek (I-1) | 348 | 99.72% |
| W2 | `bookings` | Clustered Index Scan (×16) | 2,015,536 | Index Seek (I-2) | 33,312 | 98.35% |
| W2 | `maintenance_records` | Clustered Index Scan (×16) | 47,182 | Index Seek (I-4) | 16 | 99.97% |
| W3 | `bookings` | Clustered Index Scan | 125,971 | Index Seek (I-2) | 12,599 | 90.00% |
| W4 | `bookings` | Clustered Index Scan | 125,971 | Index Seek (I-3) | 12,599 | 90.00% |
| W5 | `bookings` | Clustered Index Scan | 125,971 | Index Seek (I-5) | 247 | 99.80% |

Three observations follow from the row counts, all cross-checked against the
seeded dataset (Section 3):

1. **W2's baseline volume is sixteen full-table passes.** 2,015,536 = 16 ×
   125,971: the room finder re-scanned the *entire* booking history once per
   qualifying candidate space (16 spaces passed the facility/capacity pre-filter
   in the recorded run). Post-tuning the same 16 iterations touch only 33,312
   rows from the I-2 seeks (~2,082 rows per candidate space on average) and 16
   rows from the I-4 maintenance seeks — one narrow probe per candidate space.
   The `SET STATISTICS IO` output of the post harness shows `Scan count 16` for
   both `bookings` and `maintenance_records`, matching the 16 candidate spaces
   exactly.
2. **W3 and W4 read the identical 12,599-row subset.** 12,599 is exactly the
   number of effective-reservation bookings (`approved` + `checked_in` +
   `completed` + `no_show`) whose `requested_start_time` falls in the Autumn-2025
   semester window (`2025-09-01`..`2026-02-01`) used by both harnesses — verified
   with a direct `COUNT(*)` against the dataset. Both queries apply the same
   status filter and the same window, so their covering indexes (I-2 for W3, I-3
   for W4) store and read exactly that subset. The identical 90.00% reduction is
   therefore a **consistency check on the effective-reservation status filter**,
   not a coincidence of the two runs.
3. **The per-space probes read only the approved subset.** W1's conflict probe
   reads 348 `approved` rows of its probe space and W5's escalation report reads
   247 `approved` rows of the escalated space (B-MR-206) — versus 125,971 rows
   for the whole history. For scale: the dataset holds 11,330 `approved` rows in
   total and 1,613 inside the semester window across all 40 spaces, so a
   heavily-booked single space legitimately contributes a few hundred rows to
   these seeks.

---

## 7. Metric Comparison — Empirical Results

The empirical metrics below are the recorded cold-cache measurements from
`docs/15-index-tuning-results-G7.md`, captured by executing
`outputs/15-index-tuning-G7.sql` against the >=100,000-record dataset. Every run
was cold-cache (`CHECKPOINT`; `DBCC DROPCLEANBUFFERS`; `DBCC FREEPROCCACHE`) so
the before/after comparison is worst-case and repeatable. The elapsed times are
the inline `SYSDATETIME()`/`DATEDIFF` `execution_time_ms` values emitted per
workload block. `SET STATISTICS IO/TIME ON` additionally reported Logical Reads
and CPU time in the Messages tab during the run; those two metrics are not
reproduced in the results artifact, so the per-workload tables below list Elapsed
Time and mark the other two metrics as not recorded. The percentage gain is
`(baseline - post) / baseline`; the speedup factor is `baseline / post`, both
derived from the recorded times.

### 7.0 Workload summary

| Workload | Query | Baseline (ms) | Post-tuning (ms) | Absolute gain (ms) | Performance gain (%) | Speedup factor |
|---|---|---|---|---|---|---|
| W1 | Booking Conflict Check (BR-14/BR-50) | 6 | 0 | -6 | 100.0% | Instant (sub-ms) |
| W2 | Multi-Criteria Room Finder (Q3) | 197 | 64 | -133 | 67.5% | 3.08x |
| W3 | Total Approved Hours per Space (Q1) | 31 | 15 | -16 | 51.6% | 2.07x |
| W4 | Booking Density Heatmap (Q2) | 23 | 7 | -16 | 69.6% | 3.29x |
| W5 | Maintenance Escalation Impact (Q4) | 19 | 3 | -16 | 84.2% | 6.33x |

### Interpretation

* **W1 dominates.** A 100% elapsed-time reduction on the hot transactional path
  (every booking submission, approval and escalation probes the conflict check)
  means the availability decision no longer scans history — it seeks the small
  approved subset.
* **W5 shows the largest relative speedup** (6.33x) because the baseline
  escalation report scanned the whole `bookings` history of the escalated space;
  the covering I-5 index collapses that to a per-space seek (~39x cheaper plan).
* **W2 shows the largest absolute gain** (133 ms): the room finder combines four
  access paths (capacity, facilities, bookings, maintenance), and moving both
  anti-joins from scans to covering seeks produces the biggest absolute saving
  even though the plan-cost estimate only reflects part of it.
* **W3 and W4 (the two formally designated reporting queries)** — W3 more than
  halves, W4 drops to a third of its elapsed time; the gains come from the
  covering indexes eliminating both the clustered scan and the key lookups in
  the aggregation paths.

---

## 8. Reproduction

Prerequisites (in order) on a dedicated instance (the harness flushes the shared
buffer pool and procedure cache):

1. `outputs/05-db-implementation-G7.sql` — creates the database and schema.
2. `outputs/10-schema-migration-G7.sql` — applies the Phase 2 schema changes.
3. `outputs/14-data-generator-G7.sql` — seeds the >= 100,000-booking dataset.
4. `outputs/15-index-tuning-G7.sql` — clean baseline -> create indexes -> post
   measurements, with PRINT headers and per-query `execution_time_ms` rows.
5. Record Logical Reads / CPU / Elapsed per block in
   `docs/15-index-tuning-results-G7.md`.
6. For plan evidence, enable *Include Actual Execution Plan* (Ctrl+M) in SSMS
   while re-running Sections 4 and 6, or use the `SET SHOWPLAN_XML` helper in
   Section 7 of the script, and record operator lists + dominant costs per
   workload.

The script is idempotent: Section 4.0 drops any previously created tuned indexes
before each baseline, so it can be re-run end-to-end without manual cleanup. This
report was updated after a full re-execution of step 4 on the populated instance
(SQL Server 2025), which reproduced the recorded times within timing noise
(Section 3).

---

## 9. Recommendations

1. **Keep all five indexes** in production: they serve the hot conflict path and
   the semester reporting workload, and their maintenance cost is bounded because
   all four `bookings` indexes are filtered.
2. **Align Stage 16 literals with the `VARCHAR(20)` columns** (Section 5.4), or
   widen the status columns to `NVARCHAR`, so the reporting queries actually use
   the filtered indexes. Without this, the reporting script falls back to
   clustered scans despite the indexes existing.
3. **Re-validate filtered-index usage after any status-predicate change** in the
   application layer: parameterizing `status` (or wrapping it in an expression)
   makes the filtered indexes invisible to the optimizer.
4. **Monitor write-path latency** of `usp_submit_*` / `usp_approve_*`: if booking
   insert throughput degrades, evaluate trimming I-3 (used only by the heatmap)
   or converting it to a covering index on a smaller column set.

---

## 10. Traceability — Workload to Index

| Workload | Requirement Change | Business Rule | Query | Index(es) |
|---|---|---|---|---|
| W1 Conflict Check | RC-01/RC-05 (Phase 2) | BR-14, BR-50 | concurrency procedures | I-1 |
| W2 Room Finder | RC-08 | BR-14, BR-42, BR-44, BR-50 | Q3 | I-2, I-4 |
| W3 Total Hours | RC-08 | BR-14, BR-50 | Q1 | I-2 |
| W4 Heatmap | RC-08 | BR-14, BR-50 | Q2 | I-3 |
| W5 Escalation Impact | RC-05, RC-08 | BR-48 | Q4 | I-5, I-1 |

Design references: `outputs/09-updated-erd-and-logical-design-G7.md`
(§3.7 BR-42/BR-44/BR-45/BR-46/BR-47/BR-48);
`outputs/12-concurrency-implementation-G7.sql` (BR-14/BR-50 enforcement).

---

*This report is a Stage 15 artifact. It updates only `outputs/15-index-tuning-G7.sql`
and itself; no artifact owned by another stage was modified.*


