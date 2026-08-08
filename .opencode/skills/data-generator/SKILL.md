---
name: data-generator
description: Generate SQL Server code to seed at least three academic years of realistic data with at least 100,000 booking records.
compatibility: opencode
---

# Data Generator Skill

## Objective

* Generate a large-scale, realistic dataset for the Phase 2 database.

* Produce a Microsoft SQL Server (T-SQL) script to seed the database with at least 100,000 booking records across a minimum of 3 academic years.

* Ensure the generated data supports performance testing and index tuning.

* Follow all schema constraints, relationships, and business rules defined in Phase 1 and Phase 2.

* Include realistic operational scenarios such as maintenance, cancellations, no-shows, and advisory acknowledgements.

* Produce data distributions that reflect real-world usage patterns (not purely uniform random data).

* Ensure the script is efficient, scalable, and suitable for repeated execution in a testing environment.

* Randomness controls the distribution of data; it must never be relied upon to enforce business rules.

---

## Required Input Files

Read the following files:

* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`

If additional context is needed, also read:

* `outputs/09-updated-erd-and-logical-design-G7.md`
* `outputs/08-req-change-analysis-G7.md`
* `outputs/06-sample-data-G7.sql` (This is only small scale sample data preparation, but you can take the randomization mechanism from it)

If an existing analysis already exists, also read:

* `outputs/14-data-generator-G7.sql`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following file must exist:

* `outputs/05-db-implementation-G7.sql`
* `outputs/10-schema-migration-G7.sql`

If missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Data Generation Requirements

### 1. Scale
- Generate at least 100,000 bookings, scalable to 500,000.
- Cover at least 3 academic years.
- Generate sufficient related data for users, spaces, facilities, bookings, approvals, sessions, maintenance, and advisory acknowledgements.
- Data must be sufficient for indexing and performance analysis in Step 15.

### 2. Schema and Business Rules
- Read the final Phase 2 schema and migration before generating data.
- Respect all:
  - Primary keys
  - Foreign keys
  - Candidate/unique keys
  - Check constraints
  - NULL/NOT NULL constraints
  - Phase 1 and Phase 2 business rules
- Do not invent new business rules.
- Maintain referential integrity and generate records in dependency order.

### 3. Randomization

- **Set-Based Per-Row Randomization:** Do not use `RAND()` for set-based queries (`INSERT ... SELECT`), as T-SQL evaluates `RAND()` only once per query execution, producing identical values for every row.
- **Row-Level Expression:** Use `NEWID()`-derived expressions to guarantee independent, per-row evaluation across large sets without procedural `WHILE` loops.
- **Weighted Distributions & Percentages:** Use `ABS(CAST(CHECKSUM(NEWID()) AS BIGINT)) % 100` (or `ABS(CHECKSUM(NEWID())) % 100`) to generate integer values from `0` to `99`. Use this expression within `CASE` statements to enforce exact probability distributions (e.g., status percentages, peak-hour weighting).
- **Random Record Selection:** Use `ORDER BY NEWID()` with `TOP (N)` when randomly picking existing parent entities, spaces, or users.
- **Materialized Seeds for Dependent Values:** When multiple columns in a row depend on the same random seed, derive or materialize the value once using CTEs, `CROSS APPLY`, or staging tables rather than evaluating separate `NEWID()` calls per column.
- **Rule Enforcement Separation:** Randomness must control only data variance, frequency, and distribution. Never rely on random generation logic to accidentally satisfy business rules, constraints, or non-overlapping schedules.

### 4. Temporal Data
- Use `DATETIME2` or `DATETIME` for values requiring time components.
- Never apply `DATEADD(HOUR/MINUTE/SECOND, ...)` directly to a `DATE` value.
- Cast `DATE` to `DATETIME2` before time arithmetic:
  ```sql
  CAST(date_column AS DATETIME2)
  ```
- Generate `start_time` first and derive `end_time` from it.
- Ensure: `start_time < end_time`
- Realistic hours, approximately 07:00–21:00.
- Realistic durations, approximately 1–3 hours.

### 5. Booking Generation
- Approved bookings must not overlap for the same space when prohibited by the business rules.
- Two bookings overlap when:
  ```sql
  start1 < end2 AND end1 > start2
  ```
- Do not independently randomize space, start time, and end time and assume that conflicts will not occur.
- Generate approved bookings from valid available slots or explicitly check each candidate against existing approved bookings.
- The final dataset must satisfy:
  ```sql
  overlapping_approved_bookings = 0
  ```
- Non-approved overlapping bookings may be generated only when permitted by the Phase 2 business rules.

### 6. Realistic Distribution
- Use controlled or weighted distributions:
  - **Approved:** approximately 60–70%
  - **Completed:** approximately 20–30%
  - **Rejected:** approximately 5–10%
  - **Cancelled/no-show:** small percentage
- Weekdays and peak hours should be more heavily represented.
- Some spaces and users should have significantly higher activity than others.
- Include realistic maintenance periods and advisory acknowledgements.
- Include exceptional cases such as cancellations, no-shows, rejected requests, maintenance conflicts, and high-contention spaces where permitted.

### 7. Generation Method
- Prefer set-based SQL such as `INSERT ... SELECT`, CTEs, `CROSS APPLY`, `ROW_NUMBER()`, and tally/number generation.
- Avoid large row-by-row `WHILE` loops.
- Preserve the intended dataset size and distribution; do not generate excessive invalid records and delete them afterward.

### 8. Validation and Conflict Resolution

- **Automatic Conflict Resolution (Pre-Validation Fixes):**
  - **Overlapping Approved Bookings:** Run an explicit overlap check for approved bookings on the same space (`start1 < end2 AND end1 > start2`). Update the status of conflicting booking(s) to `'Cancelled'` or `'Rejected'` to strictly guarantee zero approved overlaps.
  - **Bookings Overlapping Out-of-Service (`bookings_overlapping_out_of_service`):** Identify and `DELETE` all booking records that overlap with space out-of-service or maintenance windows.
  - **Unacknowledged Wave 1 Advisory Overlaps (`wave1_advisory_overlaps_without_ack`):** Identify bookings overlapping active Wave 1 advisories that lack acknowledgement, and `UPDATE` them to `advisory_acknowledged = 1` to ensure all advisory requirements are met.
- **Validation Execution:** Execute validation queries against the actual finalized dataset after all conflict resolutions have completed.
- **Minimum Validation Checks:**
  - Orphan foreign keys
  - Duplicate primary/candidate keys
  - Missing required values
  - Invalid booking/maintenance times
  - Overlapping approved bookings (must return 0)
  - Bookings overlapping out-of-service periods (must return 0)
  - Wave 1 advisory overlaps without acknowledgement (must return 0)
  - Booking/status inconsistencies
  - Rejected/Cancelled bookings missing required reasons or cancellation logs
  - Invalid approvals and self-approvals
  - Maintenance/booking conflicts according to Phase 2 rules
  - All other SQL-checkable Phase 1/Phase 2 business rules
- **Validation Output Format:**
  Each validation query must return:
  ```text
  validation_name
  violation_count
  ```
- **Compliance Requirement:** Mandatory business rules must return `violation_count = 0`. If any non-zero violations remain after automated conflict resolution, report the failure and correct the underlying generation script.

### 9. Output
- Produce a single executable SQL Server seed script containing:
  - Data generation
  - Required sample data
  - Validation queries
  - A clearly labeled validation summary
- The script must be suitable for the Step 15 indexing and performance analysis.

---

## Output Specification

Create or update:

* `outputs/14-data-generator-G7.sql`

Do not omit any required section.

---

## Error Handling

If `outputs/05-db-implementation-G7.sql` or `outputs/10-schema-migration-G7.sql` do not exist:

* Stop execution.
* Report the missing file.