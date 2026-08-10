---
name: index-tuning
description: Tune the booking conflict check, room finder, and the two selected reporting queries. Compare their execution plans and execution times before and after indexing.
compatibility: opencode
---

# Index Tuning Skill

## Objective

* Design and implement targeted non-clustered and covering index strategies (`outputs/15-index-tuning-G7.sql`) for the 4 key workload operations: Booking Conflict Check, Multi-Criteria Room Finder, and the 2 selected analytical reporting queries from Step 16.
* Generate test harnesses and execution plan profiling setups (`SET STATISTICS IO ON`, `SET STATISTICS TIME ON`, buffer pool management) to evaluate query execution before and after index creation.

If `docs/15-index-tuning-results-G7.md` exists, also do:

* Analyze empirical execution statistics provided in `docs/15-index-tuning-results-G7.md` (Logical Reads, CPU Time, Elapsed Time) gathered from running the benchmark on the 100,000+ record dataset.
* Author a detailed Query Tuning Analysis report (`outputs/15-index-tuning-report-G7.md`) documenting execution plan transitions, operator cost shifts (e.g., Table Scan to Index Seek), key lookup eliminations, and metric comparisons.

---

## Required Input Files

Read the following files:

* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`
* `outputs/14-data-generator-G7.sql`
* `outputs/16-analytical-queries-G7.sql`

If an existing index tuning result already exists, also read:

* `docs/15-index-tuning-results-G7.md`
* `docs/QueryPlan.sqlplan`

If an existing index SQL code and Query Tuning Analysis already exists, also read:

* `outputs/15-index-tuning-G7.sql` (Index Tuning SQL Implementation)
* `outputs/15-index-tuning-report-G7.md` (Query Tuning Analysis)

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following files must exist:

* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`
* `outputs/14-data-generator-G7.sql`
* `outputs/16-analytical-queries-G7.sql`

If any prerequisite is missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Output Specification

Create or update:

* `outputs/15-index-tuning-G7.sql` (Index Tuning SQL Implementation)

If `docs/15-index-tuning-results-G7.md` exists, also use it to create or update:

* `outputs/15-index-tuning-report-G7.md` (Query Tuning Analysis)

Do not omit any required section.

---

## Implementation Guidelines

### Index Tuning SQL Requirements (`outputs/15-index-tuning-G7.sql`)

When generating or updating `outputs/15-index-tuning-G7.sql`, strictly adhere to the following T-SQL syntax guardrails and benchmarking structure to ensure script compilation and accurate metric collection.

#### 1. Critical T-SQL Syntax Guardrails

##### Rule A: Explicit Data Type Matching in Filtered Indexes (`Msg 10611` Prevention)
* **Problem:** SQL Server prohibits implicit data type or collation conversion in filtered index `WHERE` clauses. If a column is defined as `NVARCHAR`, passing a `VARCHAR` literal (e.g., `'Approved'`) will cause compilation failure `Msg 10611`.
* **Requirement:** Always match string literals explicitly to the column's underlying data type and collation:
  ```sql
  -- CORRECT (For NVARCHAR status columns):
  CREATE NONCLUSTERED INDEX ix_bookings_conflict_approved
  ON bookings (space_id, start_time, end_time)
  WHERE status = N'Approved';

  CREATE NONCLUSTERED INDEX ix_maintenance_open_covering
  ON maintenance_records (space_id, start_time, end_time)
  WHERE status IN (N'Open', N'In_Progress');
  ```

##### Rule B: Strict Statement Termination Before CTEs (`Msg 319` / `Msg 156` Prevention)
* **Problem:** T-SQL requires the statement immediately preceding a Common Table Expression (`WITH ... AS (...)`) to end with a semicolon. Statements like `CHECKPOINT` or `DBCC DROPCLEANBUFFERS` without semicolons will break execution.
* **Requirement:** Always terminate `CHECKPOINT;`, `DBCC DROPCLEANBUFFERS;`, and all SQL statements with explicit semicolons, or use `;WITH` for all CTEs:
  ```sql
  -- CORRECT:
  CHECKPOINT;
  DBCC DROPCLEANBUFFERS;

  ;WITH RequiredFacilities AS (
      SELECT space_id
      FROM space_facilities
      WHERE facility_id IN (1, 2, 3)
      GROUP BY space_id
      HAVING COUNT(DISTINCT facility_id) = 3
  )
  SELECT ...
  ```

---

#### 2. Benchmark Script Architecture

The script `outputs/15-index-tuning-G7.sql` must follow a strict three-phase sequence:

##### Phase 1: Clean Baseline Environment (Pre-Index Evaluation)
1. Safely drop any existing non-clustered performance indexes to ensure a clean baseline.
2. Enable performance metrics:
   ```sql
   SET STATISTICS TIME ON;
   SET STATISTICS IO ON;
   ```
3. Run baseline queries wrapped with cache clearing:
   ```sql
   CHECKPOINT;
   DBCC DROPCLEANBUFFERS;
   -- [Execute Query 1..4 Baseline]
   ```

##### Phase 2: Index Creation Phase
1. Create targeted non-clustered, covering, and filtered indexes.
2. Enforce index creation safety using drop-if-exists checks:
   ```sql
   IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'ix_bookings_conflict_approved' AND object_id = OBJECT_ID('bookings'))
       DROP INDEX ix_bookings_conflict_approved ON bookings;
   ```

##### Phase 3: Post-Index Verification
1. Re-run identical queries with cache clearing (`CHECKPOINT; DBCC DROPCLEANBUFFERS;`).
2. Output clear labeled print headers before each query block so statistics output in SSMS / SQL logs can be matched directly to query IDs:
   ```sql
   PRINT '==================================================';
   PRINT 'POST-INDEX BENCHMARK: Query 3 (Room Finder)';
   PRINT '==================================================';
   ```

---

#### 3. Targeted Indexing Strategy Guidelines

Design indexes tailored to the 4 target operations:

* **Booking Conflict Check:** Filtered composite index on `bookings(space_id, start_time, end_time) WHERE status = N'Approved'`.
* **Room Finder:** Composite index on `spaces(capacity, space_id)` and covering index on `space_facilities(facility_id, space_id)`.
* **Semester Space Utilization:** Covering index on `bookings(status, start_time, space_id) INCLUDE (end_time)`.
* **Maintenance Escalation Impact:** Index on `bookings(space_id, status) INCLUDE (start_time, end_time, user_id) WHERE status = N'Approved'`.

---

## Error Handling

If `outputs/05-db-implementation-G7.sql` or `outputs/10-schema-migration-G7.sql` or `outputs/16-analytical-queries-G7.sql` or `outputs/14-data-generator-G7.sql` do not exist:

* Stop execution.
* Report the missing file.