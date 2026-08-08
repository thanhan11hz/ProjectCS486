---
name: analytical-queries
description: Implement all queries in new reporting needs with built-in execution timing harnesses, then select queries for indexing and performance analysis
compatibility: opencode
---

# Analytical Queries Skill

## Objective

* Implement all four mandatory reporting and operational SQL queries required by Phase 2 Section 1.3 (Semester Space Utilization, Weekday/Hour Booking Density, Multi-Criteria Room Finder, and Maintenance Escalation Impact).
* Embed execution timing logic into the script using T-SQL timing mechanisms (`SYSDATETIME()` / `DATEDIFF` and `SET STATISTICS TIME ON`) to measure and record baseline execution times for each query.
* Select two reporting queries (in addition to the required Room Finder query and Booking Conflict check) to undergo detailed indexing and performance analysis in Step 15.
* Produce an executable, parametrized SQL script (`outputs/16-analytical-queries.sql`) formatted for baseline execution against the generated Step 14 dataset.

---

## Required Input Files

Read the following files:

* `outputs/05-db-implementation-G7.md`
* `outputs/09-updated-erd-and-logical-design-G7.md`
* `outputs/10-schema-migration-G7.md`
* `req/business-requirement-change.md`

If an existing analysis already exists, also read:

* `outputs/16-analytical-queries.sql`

Do not read unrelated files unless explicitly requested.

---

## Prerequisites

The following files must exist:

* `outputs/05-db-implementation-G7.md`
* `outputs/09-updated-erd-and-logical-design-G7.md`
* `outputs/10-schema-migration-G7.md`
* `req/business-requirement-change.md`

If any prerequisite is missing:

* Stop execution.
* Report the missing prerequisite artifact.

---

## Output Specification

Create or update:

* `outputs/16-analytical-queries.sql`

Do not omit any required section.

---

## Implementation Guidelines

### 1. Execution Timing Harness

Every analytical query block in `outputs/16-analytical-queries.sql` must be wrapped in an explicit timing harness to measure exact execution elapsed time in milliseconds:

* Enclose queries with `SET STATISTICS TIME ON;` and `SET STATISTICS IO ON;` to report CPU time and I/O metrics in the SQL Server messages tab.
* Use inline timestamp variables before and after each query block:
  ```sql
  DECLARE @QueryStart DATETIME2 = SYSDATETIME();

  -- [Analytical Query Execution]

  DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
  SELECT 
      'Query Name / ID' AS query_name,
      DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;
  ```

### 2. Required Query Specifications (`outputs/16-analytical-queries.sql`)

The SQL script must implement T-SQL logic for all four Section 1.3 requirements using explicit parameters (e.g., `@SemesterStart`, `@SemesterEnd`, `@TargetStart`, `@TargetEnd`, `@RequiredCapacity`, `@MaintenanceID`):

1. **Total Approved Booking Hours per Space**
   - Calculate total approved/completed booking hours for each space within a given semester.
   - Use `LEFT JOIN` from `Space` to ensure spaces with zero bookings return `0` hours.
2. **Booking Density Heatmap (Weekday x Hour)**
   - Aggregate approved booking counts grouped by weekday (`DATEPART(WEEKDAY, ...)`) and starting hour (`DATEPART(HOUR, ...)`) for a given semester.
3. **Multi-Criteria Room Finder**
   - Identify available spaces meeting minimum capacity (`capacity >= @RequiredCapacity`) and containing **ALL** specified facility requirements (relational division via `HAVING COUNT(DISTINCT facility_id) = @RequiredFacilityCount`).
   - Filter out spaces with overlapping approved bookings or active `out-of-service` maintenance periods (`start1 < end2 AND end1 > start2`).
4. **Maintenance Escalation Impact Report**
   - Identify all approved bookings affected when a specified advisory maintenance record is escalated to `out-of-service`.
   - Output requester contact details (`user_id`, `email`, `phone`) so administrative staff can inform affected users.

### 3. Query Selection for Step 15 Indexing

- Include a header section in `outputs/16-analytical-queries.sql` explicitly declaring which **two reporting queries** (excluding Room Finder) are designated for Step 15 execution plan analysis and index tuning.

---

## Error Handling

If `outputs/05-db-implementation-G7.md` or `outputs/09-updated-erd-and-logical-design-G7.md` or `outputs/10-schema-migration-G7.md` or `req/business-requirement-change.md` do not exist:

* Stop execution.
* Report the missing file.

(Note: New reporting needs can be read from `req/business-requirement-change.md`)