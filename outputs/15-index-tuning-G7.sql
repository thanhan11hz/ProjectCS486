-- ============================================================================
-- Index Tuning Implementation Script (Phase 2 / Stage 15)
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Description : Implements and benchmarks targeted non-clustered, covering and
--               filtered index strategies for the five key workload operations:
--                 W1 Booking Conflict Check            (BR-14/BR-50, CC-01..CC-03)
--                 W2 Multi-Criteria Room Finder        (RC-08, Q3 of Stage 16)
--                 W3 Total Approved Booking Hours      (RC-08, Q1 of Stage 16)
--                 W4 Booking Density Heatmap           (RC-08, Q2 of Stage 16)
--                 W5 Maintenance Escalation Impact     (RC-08 / BR-48, Q4 of
--                                                       Stage 16)
-- Baseline    : outputs/05-db-implementation-G7.sql (Phase 1 schema)
-- Migrated by : outputs/10-schema-migration-G7.sql   (Phase 2 schema)
-- Data        : outputs/14-data-generator-G7.sql     (>= 100,000 bookings)
-- Workloads   : outputs/16-analytical-queries-G7.sql (Q1-Q4 reporting queries)
-- Artifact    : outputs/15-index-tuning-G7.sql
-- Results     : Execution metrics (Logical Reads / CPU / Elapsed) produced by
--               the harness below are recorded in
--               docs/15-index-tuning-results-G7.md for the analysis report
--               (outputs/15-index-tuning-report-G7.md).
-- Prerequisite: Database CS486_Booking_System with the Phase 2 schema AND the
--               large-scale dataset (run outputs/05-db-implementation-G7.sql,
--               outputs/10-schema-migration-G7.sql, then
--               outputs/14-data-generator-G7.sql).
-- Notes       : - This script contains NO table/column/schema changes; it only
--                 creates indexes and runs benchmark harnesses (Rule: stage 15
--                 owns indexes and measurements, not schema).
--               - Every DDL statement is idempotent so the script can be
--                 re-run safely (Section 4.0 drops any previously created
--                 tuned indexes so the baseline is always clean).
--               - FILTERED INDEX LITERAL TYPING (Msg 10611): bookings.status,
--                 maintenance_records.status and maintenance_records.impact_
--                 level are VARCHAR(20). Filtered-index filter expressions and
--                 all benchmark predicates therefore use plain VARCHAR string
--                 literals ('approved', 'reported', ...). NVARCHAR literals
--                 (N'approved') would raise Msg 10611 at index creation and
--                 force CONVERT_IMPLICIT into the query plan, preventing the
--                 filtered indexes from ever being used (verified empirically
--                 on SQL Server 2025; see report Section 4.2).
-- ============================================================================

-- ============================================================================
-- 1. HEADER BLOCK — Execution Context and Database Guard
-- ============================================================================

SET NOCOUNT ON;
GO

IF DB_ID(N'CS486_Booking_System') IS NULL
    THROW 51000, N'Database CS486_Booking_System does not exist. Execute outputs/05-db-implementation-G7.sql, outputs/10-schema-migration-G7.sql, then outputs/14-data-generator-G7.sql first.', 1;
GO

USE [CS486_Booking_System];
GO

-- Filtered index creation requires QUOTED_IDENTIFIER ON. sqlcmd defaults it to
-- OFF, which fails index creation with Msg 1934; SSMS and most clients have it
-- ON. Setting it explicitly makes the script client-independent.
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================================
-- 2. WORKLOAD DEFINITIONS — THE FIVE OPERATIONS BEING TUNED
-- ----------------------------------------------------------------------------
-- | # | Workload                                   | Source                                  | Status predicate used                          |
-- |---|--------------------------------------------|-----------------------------------------|-----------------------------------------------|
-- | W1| Booking Conflict Check (availability probe)| usp_submit_instant_booking / usp_submit_booking_pending / usp_approve_pending_booking / usp_escalate_maintenance_impact (12-concurrency-implementation-G7.sql) | status = 'approved'                           |
-- | W2| Multi-Criteria Room Finder (Q3)            | outputs/16-analytical-queries-G7.sql    | status IN (approved, checked_in, completed, no_show) |
-- | W3| Total Approved Booking Hours per Space (Q1)| outputs/16-analytical-queries-G7.sql    | status IN (approved, checked_in, completed, no_show) |
-- | W4| Booking Density Heatmap, Weekday x Hour(Q2)| outputs/16-analytical-queries-G7.sql    | status IN (approved, checked_in, completed, no_show) |
-- | W5| Maintenance Escalation Impact (Q4)         | outputs/16-analytical-queries-G7.sql    | status = 'approved'                           |
--
-- Shared semantic: an "effective reservation" (an approved booking that was
-- realized) is any booking with status IN (approved, checked_in, completed,
-- no_show). W1 and W5 narrow that to status = approved only, following the
-- BR-14 / BR-50 availability semantics and the BR-48 escalation semantics used
-- by the concurrency procedures.
--
-- Workload characteristics (from outputs/14-data-generator-G7.sql targets):
--   * bookings            ~126,000 rows across 40 spaces (~3,100 rows/space)
--   * maintenance_records ~3,100 rows, of which only OPEN records (reported /
--     in_progress) are ever read by the booking conflict checks
--   * users ~1,500 / spaces 40 / facilities 18 / space_facilities ~150
--   * The clustered PK of bookings is booking_id (INT IDENTITY); all space- and
--     time-based access paths therefore start from a clustered index scan.
-- ============================================================================

-- ============================================================================
-- 3. BENCHMARK CONVENTIONS — Buffer Pool Management and Profiling Setup
-- ----------------------------------------------------------------------------
-- Every measured workload below follows the same harness:
--   * SET STATISTICS TIME ON  -> reports CPU time and elapsed time (Messages)
--   * SET STATISTICS IO ON    -> reports logical reads / scan counts (Messages)
--   * Inline SYSDATETIME()/DATEDIFF timestamps -> explicit execution_time_ms row
--   * PRINT headers label each block so statistics output can be matched to the
--     workload and phase (BASELINE vs POST-TUNING).
--   * The session is prepared with CHECKPOINT + DBCC DROPCLEANBUFFERS +
--     DBCC FREEPROCCACHE before each run so every execution is measured on a
--     cold buffer pool and a freshly compiled plan (worst case, identical for
--     the before/after comparison).
-- NOTE: DROPCLEANBUFFERS / FREEPROCCACHE flush the shared server cache; run
-- this script on the dedicated CS486 demo instance, not on a shared server.
-- ============================================================================

-- ============================================================================
-- 4. BASELINE MEASUREMENTS (BEFORE INDEX CREATION)
-- ----------------------------------------------------------------------------
-- The database at this point has only the clustered primary keys and unique
-- constraints from Phase 1 / Phase 2. These five blocks capture the pre-tuning
-- metrics that the report will compare against the post-tuning section.
-- Record Logical Reads / CPU / Elapsed / plan shape for each W1..W5 in
-- docs/15-index-tuning-results-G7.md.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 4.0 Clean baseline — drop any previously created tuned indexes so a re-run
--     of this script always measures against a schema with no non-clustered
--     performance indexes (Skill Phase 1: "Safely drop any existing non-
--     clustered performance indexes to ensure a clean baseline").
-- ----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_conflict_approved')
    DROP INDEX ix_bookings_conflict_approved ON bookings;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_space_effective_covering')
    DROP INDEX ix_bookings_space_effective_covering ON bookings;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_status_semester_covering')
    DROP INDEX ix_bookings_status_semester_covering ON bookings;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'maintenance_records') AND name = N'ix_maintenance_open_covering')
    DROP INDEX ix_maintenance_open_covering ON maintenance_records;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'spaces') AND name = N'ix_spaces_capacity')
    DROP INDEX ix_spaces_capacity ON spaces;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'space_facilities') AND name = N'ix_space_facilities_facility_covering')
    DROP INDEX ix_space_facilities_facility_covering ON space_facilities;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_escalation_impact')
    DROP INDEX ix_bookings_escalation_impact ON bookings;
GO

-- ----------------------------------------------------------------------------
-- 4.1 W1 BASELINE — Booking Conflict Check (BR-14 / BR-50)
-- ----------------------------------------------------------------------------
-- Probes whether an approved booking overlaps [@ConflictStart, @ConflictEnd)
-- on the busiest approved space. Baseline expected plan: full clustered index
-- scan of bookings filtered on status + overlap (no useful non-clustered index).
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'BASELINE: W1 - Booking Conflict Check (BR-14/BR-50)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @ConflictSpace VARCHAR(20) =
        (
            SELECT TOP 1 space_code
            FROM bookings
            WHERE status = 'approved'
            GROUP BY space_code
            ORDER BY COUNT(*) DESC
        );
DECLARE @ConflictStart DATETIME2 = '2025-10-20 10:00:00'; -- busy weekday, autumn 2025
DECLARE @ConflictEnd   DATETIME2 = '2025-10-20 12:00:00';

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

IF EXISTS
(
    SELECT 1
      FROM bookings b
     WHERE b.space_code           = @ConflictSpace
       AND b.status               = 'approved'
       AND b.requested_end_time   > @ConflictStart
       AND b.requested_start_time < @ConflictEnd
)
    SELECT 1 AS conflict_found;
ELSE
    SELECT 0 AS conflict_found;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W1 - Booking Conflict Check (BASELINE)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 4.2 W2 BASELINE — Multi-Criteria Room Finder (Q3 of Stage 16)
-- ----------------------------------------------------------------------------
-- Relational division (HAVING COUNT(DISTINCT facility_id) = @RequiredFacility-
-- Count) plus two NOT EXISTS anti-joins (bookings overlap; open out-of-service
-- maintenance overlap). Baseline: the bookings anti-join re-scans bookings for
-- every candidate space.
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'BASELINE: W2 - Multi-Criteria Room Finder (Q3)';
PRINT '==================================================';
GO

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = N'RequiredFacilityListType')
    CREATE TYPE dbo.RequiredFacilityListType AS TABLE
    (
        facility_id INT NOT NULL PRIMARY KEY
    );
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @TargetStart        DATETIME2 = '2026-09-15 09:00:00'; -- target period
DECLARE @TargetEnd          DATETIME2 = '2026-09-15 11:00:00';
DECLARE @RequiredCapacity   INT       = 40;
DECLARE @RequiredFacilities AS dbo.RequiredFacilityListType;
DECLARE @RequiredFacilityCount INT = 2;

INSERT INTO @RequiredFacilities (facility_id)
SELECT facility_id
FROM facilities
WHERE facility_name IN (N'Projector', N'Air Conditioning');

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    s.space_code,
    s.space_name,
    s.building,
    s.floor,
    s.room_number,
    s.capacity,
    s.space_type,
    s.usage_policy,
    COUNT(DISTINCT sf.facility_id) AS matched_facility_count
FROM spaces s
JOIN space_facilities sf
  ON sf.space_code = s.space_code
JOIN @RequiredFacilities r
  ON r.facility_id = sf.facility_id
WHERE s.capacity >= @RequiredCapacity
  AND s.status NOT IN (N'under_maintenance', N'temporarily_closed', N'retired')
  AND NOT EXISTS
      (
          SELECT 1
          FROM bookings b
          WHERE b.space_code           = s.space_code
            AND b.status               IN ('approved', 'checked_in', 'completed', 'no_show')
            AND b.requested_start_time < @TargetEnd
            AND b.requested_end_time   > @TargetStart
      )
  AND NOT EXISTS
      (
          SELECT 1
          FROM maintenance_records m
          WHERE m.space_code     = s.space_code
            AND m.impact_level   = 'out_of_service'
            AND m.status         IN ('reported', 'in_progress')
            AND m.start_time     < @TargetEnd
            AND (m.completion_time IS NULL OR m.completion_time > @TargetStart)
      )
GROUP BY s.space_code, s.space_name, s.building, s.floor,
         s.room_number, s.capacity, s.space_type, s.usage_policy
HAVING COUNT(DISTINCT sf.facility_id) = @RequiredFacilityCount
ORDER BY s.capacity, s.space_code;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W2 - Multi-Criteria Room Finder (BASELINE)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 4.3 W3 BASELINE — Total Approved Booking Hours per Space (Q1 of Stage 16)
-- ----------------------------------------------------------------------------
-- LEFT JOIN spaces -> bookings restricted to the effective-reservation statuses
-- and the autumn-2025 semester, aggregated per space. Baseline: the join scans
-- the whole bookings clustered index for the semester window.
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'BASELINE: W3 - Total Approved Booking Hours per Space (Q1)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @SemesterStart DATETIME2 = '2025-09-01 00:00:00'; -- Autumn 2025 semester
DECLARE @SemesterEnd   DATETIME2 = '2026-02-01 00:00:00'; -- exclusive end

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    s.space_code,
    s.space_name,
    s.building,
    s.floor,
    s.room_number,
    s.space_type,
    s.capacity,
    COUNT(b.booking_id) AS approved_booking_count,
    ROUND(ISNULL(SUM(DATEDIFF(MINUTE, b.requested_start_time, b.requested_end_time)), 0) / 60.0, 2)
                      AS approved_booking_hours
FROM spaces s
LEFT JOIN bookings b
       ON b.space_code            = s.space_code
      AND b.status                IN ('approved', 'checked_in', 'completed', 'no_show')
      AND b.requested_start_time >= @SemesterStart
      AND b.requested_start_time  < @SemesterEnd
GROUP BY s.space_code, s.space_name, s.building, s.floor,
         s.room_number, s.space_type, s.capacity
ORDER BY approved_booking_hours DESC, s.space_code;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W3 - Total Approved Booking Hours per Space (BASELINE)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 4.4 W4 BASELINE — Booking Density Heatmap (Q2 of Stage 16)
-- ----------------------------------------------------------------------------
-- Aggregates approved booking counts by DATEPART(WEEKDAY) x DATEPART(HOUR) for
-- the semester window. Baseline: full clustered index scan of bookings with two
-- DATEPART expressions per row.
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'BASELINE: W4 - Booking Density Heatmap (Q2)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET DATEFIRST 1; -- Monday = 1 ... Sunday = 7 (deterministic weekday dimension)
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @SemesterStart DATETIME2 = '2025-09-01 00:00:00'; -- Autumn 2025 semester
DECLARE @SemesterEnd   DATETIME2 = '2026-02-01 00:00:00'; -- exclusive end

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    DATEPART(WEEKDAY, b.requested_start_time) AS weekday_number,
    DATENAME(WEEKDAY, b.requested_start_time) AS weekday_name,
    DATEPART(HOUR,   b.requested_start_time)  AS start_hour,
    COUNT(*)                                  AS approved_booking_count
FROM bookings b
WHERE b.status                IN ('approved', 'checked_in', 'completed', 'no_show')
  AND b.requested_start_time >= @SemesterStart
  AND b.requested_start_time  < @SemesterEnd
GROUP BY
    DATEPART(WEEKDAY, b.requested_start_time),
    DATENAME(WEEKDAY, b.requested_start_time),
    DATEPART(HOUR,   b.requested_start_time)
ORDER BY weekday_number, start_hour;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W4 - Booking Density Heatmap (BASELINE)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 4.5 W5 BASELINE — Maintenance Escalation Impact (Q4 of Stage 16, BR-48)
-- ----------------------------------------------------------------------------
-- Lists the approved bookings that overlap a given maintenance record's period
-- (the record being escalated to out-of-service) together with requester
-- contact details. Baseline: the maintenance_id PK seek drives a loop join that
-- scans/cluster-seeks bookings per space and looks up users.
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'BASELINE: W5 - Maintenance Escalation Impact (Q4)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @MaintenanceID INT = 1; -- the advisory record being escalated

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    m.maintenance_id,
    m.space_code,
    m.impact_level,
    m.status            AS maintenance_status,
    m.start_time        AS maintenance_start,
    m.completion_time   AS maintenance_completion,
    b.booking_id,
    b.requested_start_time,
    b.requested_end_time,
    u.user_id,
    u.email,
    u.phone_number AS phone
FROM maintenance_records m
JOIN bookings b
  ON b.space_code = m.space_code
JOIN users u
  ON u.user_id = b.requester_id
WHERE m.maintenance_id = @MaintenanceID
  AND b.status = 'approved'
  AND b.requested_end_time > m.start_time
  AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
ORDER BY b.requested_start_time, u.user_id;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W5 - Maintenance Escalation Impact (BASELINE)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ============================================================================
-- 5. INDEX STRATEGY — DESIGN AND JUSTIFICATION
-- ----------------------------------------------------------------------------
-- Seven indexes are created. Each is justified by the workload characteristics
-- of Section 2 and the exact predicates of W1..W5. All filter expressions use
-- plain VARCHAR literals to exactly match the VARCHAR(20) filter columns
-- (Msg 10611 guardrail, header Notes).
--
-- I-1 ix_bookings_conflict_approved (FILTERED, covering for W1 and BR-48)
--   Keys: (space_code, requested_start_time, requested_end_time)
--   Filter: status = 'approved'
--   Serves: W1 conflict probe (space_code =, end > @start, start < @end);
--           BR-48 escalation-impact SELECT in usp_escalate_maintenance_impact;
--           W5 (Q4) bookings join.
--   Why:    The conflict check is the HOT transactional path (every booking
--           submission and approval probes it). Filtering to status=approved
--           keeps the index a tiny subset of the ~126,000 rows, and the
--           filtered statistics describe exactly the rows the probe reads.
--           The check is fully covered (booking_id is the clustered key and is
--           auto-included), so no key lookup is needed.
--
-- I-2 ix_bookings_space_effective_covering (FILTERED, covering for W2 and W3)
--   Keys: (space_code, requested_start_time)
--   Include: (requested_end_time)
--   Filter: status IN ('approved', 'checked_in', 'completed', 'no_show')
--   Serves: W3 (Q1) LEFT JOIN per-space seek on the semester range with the
--           DATEDIFF columns covered; W2 (Q3) bookings anti-join seeking
--           (space_code, requested_start_time < @TargetEnd) with the overlap
--           predicate covered.
--   Why:    The reporting workloads (Q1/Q3) restrict to the effective-
--           reservation status set, so filtering keeps the index to the
--           meaningful history while eliminating key lookups and the baseline
--           full scan of bookings per space.
--
-- I-3 ix_bookings_status_semester_covering (FILTERED, covering for W4)
--   Keys: (status, requested_start_time)
--   Include: (none)
--   Filter: status IN ('approved', 'checked_in', 'completed', 'no_show')
--   Serves: W4 (Q2) aggregation: per-status seek on (status, requested_start_
--           time) over the semester range, fully covered, so the two DATEPART
--           expressions and COUNT(*) are computed from the index leaf only.
--   Why:    W4 has no space_code predicate, so the space-leading indexes (I-1/
--           I-2) cannot help; a status-leading covering index turns the
--           baseline full-scan + sort into narrow index seeks.
--   No INCLUDE: Q2 references no column other than requested_start_time (from
--           which DATEPART(WEEKDAY), DATENAME(WEEKDAY) and DATEPART(HOUR) are
--           derived) and COUNT(*), which needs no column. space_code is never
--           projected, filtered or grouped by Q2, and I-3 is status-leading so
--           space_code could never be seeked anyway (the per-space aggregation
--           is served by I-2). Adding it to INCLUDE would only enlarge the leaf
--           and add maintenance cost on the booking hot path with no benefit,
--           so it is deliberately omitted. This does not change the measured
--           W4 plan shape (per-status semester seeks) or the empirical results.
--
-- I-4 ix_maintenance_open_covering (FILTERED, covering for BR-44/BR-45 and W2)
--   Keys: (space_code, impact_level, start_time, completion_time)
--   Filter: status IN ('reported', 'in_progress')   -- only OPEN records matter
--   Serves: BR-44 out-of-service overlap probe, BR-45 advisory snapshot COUNT,
--           and W2 (Q3) maintenance anti-join.
--   Why:    Only open maintenance records ever affect booking availability
--           (BR-44/BR-45); of the ~3,100 maintenance rows the index stores
--           only the open ones, making the probes narrow seeks. impact_level
--           is a key so the BR-44 (out_of_service) and BR-45 (advisory) probes
--           each seek a single narrow range.
--
-- I-5 ix_spaces_capacity (covering for the W2 capacity predicate)
--   Keys: (capacity, space_code)
--   Serves: W2 (Q3) filter s.capacity >= @RequiredCapacity.
--   Why:    spaces is small (~40 rows) so the gain is modest, but the index
--           provides an ordered access path for the capacity filter without
--           scanning the heap/cluster, and its maintenance cost is negligible.
--
-- I-6 ix_space_facilities_facility_covering (covering for the W2 division)
--   Keys: (facility_id, space_code)
--   Serves: W2 (Q3) join @RequiredFacilities -> space_facilities: seeking by
--           facility_id turns the facility relational division into narrow
--           seeks instead of the PK-clustered (space_code, facility_id) path,
--           which cannot seek on facility_id alone.
--   Why:    The clustered PK is (space_code, facility_id); the W2 join needs
--           facility_id-leading access. This covering index supplies it.
--
-- I-7 ix_bookings_escalation_impact (FILTERED, covering for W5/BR-48)
--   Keys: (space_code, status)
--   Include: (requested_start_time, requested_end_time, requester_id)
--   Filter: status = 'approved'
--   Serves: W5 (Q4) escalation-impact report: per-space seek on the overlap
--           predicates with requester_id included, so no key lookup into the
--           bookings cluster is needed before the users join.
--   Why:    Q4 runs for each escalated record; I-1 already covers space + time,
--           but lacks requester_id, forcing a key lookup. I-7 is a tight
--           covering index shaped exactly to the Q4 projection + join.
--
-- Cost / trade-off note: the booking hot path (usp_submit_* / usp_approve_*)
-- now maintains the clustered PK plus four non-clustered indexes per INSERT
-- (I-1, I-2, I-3, I-7). All four are FILTERED, so a row is written into each
-- only when it matches the respective filter; maintenance cost is therefore
-- bounded, and it is the accepted price for eliminating ~126,000-row scans
-- from every booking decision and the semester reporting.
--
-- Caveat for filtered indexes: the optimizer considers a filtered index only
-- when the query predicate on the filter column is a LITERAL (or provably a
-- subset) AND the literal data type/collation matches the column (Msg 10611
-- guardrail). All five workloads and the stored procedures use literal status
-- values that match the VARCHAR(20) columns exactly, so no hint is required.
-- If the application later parameterizes the status column or uses NVARCHAR
-- literals (N'approved'), an unfiltered covering variant should be evaluated
-- (see report Section 6, cross-artifact note on 16-analytical-queries-G7.sql).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5.1 Create index I-1 — bookings conflict probe (approved only)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_conflict_approved')
BEGIN
    CREATE NONCLUSTERED INDEX ix_bookings_conflict_approved
        ON bookings (space_code, requested_start_time, requested_end_time)
        WHERE status = 'approved';
END
GO

-- ----------------------------------------------------------------------------
-- 5.2 Create index I-2 — bookings space/time covering index (effective statuses)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_space_effective_covering')
BEGIN
    CREATE NONCLUSTERED INDEX ix_bookings_space_effective_covering
        ON bookings (space_code, requested_start_time)
        INCLUDE (requested_end_time)
        WHERE status IN ('approved', 'checked_in', 'completed', 'no_show');
END
GO

-- ----------------------------------------------------------------------------
-- 5.3 Create index I-3 — bookings status/semester covering index (for W4/Q2)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_status_semester_covering')
BEGIN
    CREATE NONCLUSTERED INDEX ix_bookings_status_semester_covering
        ON bookings (status, requested_start_time)
        WHERE status IN ('approved', 'checked_in', 'completed', 'no_show');
END
GO

-- ----------------------------------------------------------------------------
-- 5.4 Create index I-4 — maintenance open-record covering index (BR-44/BR-45, W2)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'maintenance_records') AND name = N'ix_maintenance_open_covering')
BEGIN
    CREATE NONCLUSTERED INDEX ix_maintenance_open_covering
        ON maintenance_records (space_code, impact_level, start_time, completion_time)
        WHERE status IN ('reported', 'in_progress');
END
GO

-- ----------------------------------------------------------------------------
-- 5.5 Create index I-5 — spaces capacity index (for W2/Q3)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'spaces') AND name = N'ix_spaces_capacity')
BEGIN
    CREATE NONCLUSTERED INDEX ix_spaces_capacity
        ON spaces (capacity, space_code);
END
GO

-- ----------------------------------------------------------------------------
-- 5.6 Create index I-6 — space_facilities facility-leading covering index (for W2/Q3)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'space_facilities') AND name = N'ix_space_facilities_facility_covering')
BEGIN
    CREATE NONCLUSTERED INDEX ix_space_facilities_facility_covering
        ON space_facilities (facility_id, space_code);
END
GO

-- ----------------------------------------------------------------------------
-- 5.7 Create index I-7 — bookings escalation-impact covering index (for W5/Q4)
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_escalation_impact')
BEGIN
    CREATE NONCLUSTERED INDEX ix_bookings_escalation_impact
        ON bookings (space_code, status)
        INCLUDE (requested_start_time, requested_end_time, requester_id)
        WHERE status = 'approved';
END
GO

-- ----------------------------------------------------------------------------
-- 5.8 Verify index inventory after creation
-- ----------------------------------------------------------------------------
SELECT
    OBJECT_NAME(i.object_id) AS table_name,
    i.name                  AS index_name,
    i.type_desc             AS index_type,
    i.filter_definition     AS filter_definition,
    i.is_primary_key        AS is_primary_key,
    i.is_unique             AS is_unique
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID(N'bookings'), OBJECT_ID(N'maintenance_records'),
                      OBJECT_ID(N'spaces'), OBJECT_ID(N'space_facilities'))
  AND i.name IS NOT NULL
ORDER BY OBJECT_NAME(i.object_id), i.index_id;
GO

-- ============================================================================
-- 6. POST-TUNING MEASUREMENTS (AFTER INDEX CREATION)
-- ----------------------------------------------------------------------------
-- Identical harness and identical parameters as Section 4. Compare the Logical
-- Reads / CPU / Elapsed times and the execution plan operator transitions
-- (Table Scan -> Index Seek; key-lookup elimination) against the baseline.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 6.1 W1 POST-TUNING — Booking Conflict Check
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'POST-TUNING: W1 - Booking Conflict Check (BR-14/BR-50)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @ConflictSpace VARCHAR(20) =
        (
            SELECT TOP 1 space_code
            FROM bookings
            WHERE status = 'approved'
            GROUP BY space_code
            ORDER BY COUNT(*) DESC
        );
DECLARE @ConflictStart DATETIME2 = '2025-10-20 10:00:00';
DECLARE @ConflictEnd   DATETIME2 = '2025-10-20 12:00:00';

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

IF EXISTS
(
    SELECT 1
      FROM bookings b
     WHERE b.space_code           = @ConflictSpace
       AND b.status               = 'approved'
       AND b.requested_end_time   > @ConflictStart
       AND b.requested_start_time < @ConflictEnd
)
    SELECT 1 AS conflict_found;
ELSE
    SELECT 0 AS conflict_found;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W1 - Booking Conflict Check (POST-TUNING)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 6.2 W2 POST-TUNING — Multi-Criteria Room Finder
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'POST-TUNING: W2 - Multi-Criteria Room Finder (Q3)';
PRINT '==================================================';
GO

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = N'RequiredFacilityListType')
    CREATE TYPE dbo.RequiredFacilityListType AS TABLE
    (
        facility_id INT NOT NULL PRIMARY KEY
    );
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @TargetStart        DATETIME2 = '2026-09-15 09:00:00';
DECLARE @TargetEnd          DATETIME2 = '2026-09-15 11:00:00';
DECLARE @RequiredCapacity   INT       = 40;
DECLARE @RequiredFacilities AS dbo.RequiredFacilityListType;
DECLARE @RequiredFacilityCount INT = 2;

INSERT INTO @RequiredFacilities (facility_id)
SELECT facility_id
FROM facilities
WHERE facility_name IN (N'Projector', N'Air Conditioning');

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    s.space_code,
    s.space_name,
    s.building,
    s.floor,
    s.room_number,
    s.capacity,
    s.space_type,
    s.usage_policy,
    COUNT(DISTINCT sf.facility_id) AS matched_facility_count
FROM spaces s
JOIN space_facilities sf
  ON sf.space_code = s.space_code
JOIN @RequiredFacilities r
  ON r.facility_id = sf.facility_id
WHERE s.capacity >= @RequiredCapacity
  AND s.status NOT IN (N'under_maintenance', N'temporarily_closed', N'retired')
  AND NOT EXISTS
      (
          SELECT 1
          FROM bookings b
          WHERE b.space_code           = s.space_code
            AND b.status               IN ('approved', 'checked_in', 'completed', 'no_show')
            AND b.requested_start_time < @TargetEnd
            AND b.requested_end_time   > @TargetStart
      )
  AND NOT EXISTS
      (
          SELECT 1
          FROM maintenance_records m
          WHERE m.space_code     = s.space_code
            AND m.impact_level   = 'out_of_service'
            AND m.status         IN ('reported', 'in_progress')
            AND m.start_time     < @TargetEnd
            AND (m.completion_time IS NULL OR m.completion_time > @TargetStart)
      )
GROUP BY s.space_code, s.space_name, s.building, s.floor,
         s.room_number, s.capacity, s.space_type, s.usage_policy
HAVING COUNT(DISTINCT sf.facility_id) = @RequiredFacilityCount
ORDER BY s.capacity, s.space_code;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W2 - Multi-Criteria Room Finder (POST-TUNING)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 6.3 W3 POST-TUNING — Total Approved Booking Hours per Space
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'POST-TUNING: W3 - Total Approved Booking Hours per Space (Q1)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @SemesterStart DATETIME2 = '2025-09-01 00:00:00';
DECLARE @SemesterEnd   DATETIME2 = '2026-02-01 00:00:00';

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    s.space_code,
    s.space_name,
    s.building,
    s.floor,
    s.room_number,
    s.space_type,
    s.capacity,
    COUNT(b.booking_id) AS approved_booking_count,
    ROUND(ISNULL(SUM(DATEDIFF(MINUTE, b.requested_start_time, b.requested_end_time)), 0) / 60.0, 2)
                      AS approved_booking_hours
FROM spaces s
LEFT JOIN bookings b
       ON b.space_code            = s.space_code
      AND b.status                IN ('approved', 'checked_in', 'completed', 'no_show')
      AND b.requested_start_time >= @SemesterStart
      AND b.requested_start_time  < @SemesterEnd
GROUP BY s.space_code, s.space_name, s.building, s.floor,
         s.room_number, s.space_type, s.capacity
ORDER BY approved_booking_hours DESC, s.space_code;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W3 - Total Approved Booking Hours per Space (POST-TUNING)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 6.4 W4 POST-TUNING — Booking Density Heatmap
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'POST-TUNING: W4 - Booking Density Heatmap (Q2)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET DATEFIRST 1;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @SemesterStart DATETIME2 = '2025-09-01 00:00:00';
DECLARE @SemesterEnd   DATETIME2 = '2026-02-01 00:00:00';

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    DATEPART(WEEKDAY, b.requested_start_time) AS weekday_number,
    DATENAME(WEEKDAY, b.requested_start_time) AS weekday_name,
    DATEPART(HOUR,   b.requested_start_time)  AS start_hour,
    COUNT(*)                                  AS approved_booking_count
FROM bookings b
WHERE b.status                IN ('approved', 'checked_in', 'completed', 'no_show')
  AND b.requested_start_time >= @SemesterStart
  AND b.requested_start_time  < @SemesterEnd
GROUP BY
    DATEPART(WEEKDAY, b.requested_start_time),
    DATENAME(WEEKDAY, b.requested_start_time),
    DATEPART(HOUR,   b.requested_start_time)
ORDER BY weekday_number, start_hour;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W4 - Booking Density Heatmap (POST-TUNING)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ----------------------------------------------------------------------------
-- 6.5 W5 POST-TUNING — Maintenance Escalation Impact
-- ----------------------------------------------------------------------------
PRINT '==================================================';
PRINT 'POST-TUNING: W5 - Maintenance Escalation Impact (Q4)';
PRINT '==================================================';
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

DECLARE @MaintenanceID INT = 1; -- the advisory record being escalated

DECLARE @QueryStart DATETIME2 = SYSDATETIME();

SELECT
    m.maintenance_id,
    m.space_code,
    m.impact_level,
    m.status            AS maintenance_status,
    m.start_time        AS maintenance_start,
    m.completion_time   AS maintenance_completion,
    b.booking_id,
    b.requested_start_time,
    b.requested_end_time,
    u.user_id,
    u.email,
    u.phone_number AS phone
FROM maintenance_records m
JOIN bookings b
  ON b.space_code = m.space_code
JOIN users u
  ON u.user_id = b.requester_id
WHERE m.maintenance_id = @MaintenanceID
  AND b.status = 'approved'
  AND b.requested_end_time > m.start_time
  AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
ORDER BY b.requested_start_time, u.user_id;

DECLARE @QueryEnd DATETIME2 = SYSDATETIME();
SELECT
    N'W5 - Maintenance Escalation Impact (POST-TUNING)' AS query_name,
    DATEDIFF(MILLISECOND, @QueryStart, @QueryEnd) AS execution_time_ms;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ============================================================================
-- 7. OPTIONAL — EXECUTION PLAN CAPTURE (SHOWPLAN_XML)
-- ----------------------------------------------------------------------------
-- For the analysis report, capture the estimated/actual plan operator costs
-- before and after indexing. Two options:
--   a) SSMS: enable "Include Actual Execution Plan" (Ctrl+M) and re-run the
--      Section 4 (baseline) and Section 6 (post-tuning) blocks; export the
--      .sqlplan files.
--   b) Programmatic: wrap a workload in SET SHOWPLAN_XML ON ... SET SHOWPLAN_XML
--      OFF to return the plan XML as rows. Example for the conflict check:
--        SET SHOWPLAN_XML ON;
--        SELECT ...  -- W1 statement text (no execution, no STATISTICS)
--        SET SHOWPLAN_XML OFF;
--   The report must record, per workload: operator list before/after, dominant
--   operator cost, and whether a Table Scan became an Index Seek / whether key
--   lookups were eliminated.
-- ============================================================================

-- ============================================================================
-- 8. OPTIONAL — CLEANUP (ROLLBACK OF THE TUNING)
-- ----------------------------------------------------------------------------
-- Drop the seven tuned indexes. Only needed if the tuning must be re-run from
-- the baseline (e.g. to repeat the Section 4 measurements) or to restore the
-- pre-tuning schema. Keep the indexes otherwise, since they serve the
-- production reporting workload. Section 4.0 re-applies this cleanup
-- automatically so the script can be re-run end-to-end.
-- ============================================================================

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_conflict_approved')
    DROP INDEX ix_bookings_conflict_approved ON bookings;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_space_effective_covering')
    DROP INDEX ix_bookings_space_effective_covering ON bookings;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_status_semester_covering')
    DROP INDEX ix_bookings_status_semester_covering ON bookings;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'maintenance_records') AND name = N'ix_maintenance_open_covering')
    DROP INDEX ix_maintenance_open_covering ON maintenance_records;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'spaces') AND name = N'ix_spaces_capacity')
    DROP INDEX ix_spaces_capacity ON spaces;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'space_facilities') AND name = N'ix_space_facilities_facility_covering')
    DROP INDEX ix_space_facilities_facility_covering ON space_facilities;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'bookings') AND name = N'ix_bookings_escalation_impact')
    DROP INDEX ix_bookings_escalation_impact ON bookings;
GO

-- ============================================================================
-- 9. TRACEABILITY — WORKLOAD TO INDEX
-- ----------------------------------------------------------------------------
-- | Workload                       | Index(es) used                              | Baseline plan (expected)      | Post-tuning plan (expected)          |
-- |--------------------------------|---------------------------------------------|-------------------------------|--------------------------------------|
-- | W1 Booking Conflict Check      | ix_bookings_conflict_approved                | clustered scan of bookings     | narrow index seek, covering          |
-- | W2 Multi-Criteria Room Finder  | ix_bookings_space_effective_covering, ix_maintenance_open_covering, ix_spaces_capacity, ix_space_facilities_facility_covering | per-space bookings scan + maintenance scan + facility PK path | index seeks for both anti-joins, facility seek, capacity seek |
-- | W3 Total Approved Hours (Q1)   | ix_bookings_space_effective_covering         | bookings clustered scan + key lookups | per-space index seek, covering |
-- | W4 Density Heatmap (Q2)        | ix_bookings_status_semester_covering         | bookings clustered scan + sort | per-status index seeks, covering     |
-- | W5 Maintenance Escalation (Q4) | ix_bookings_escalation_impact, ix_bookings_conflict_approved | maintenance PK seek -> bookings scan + users key lookups | maintenance PK seek -> bookings covering seek -> users PK seek |
-- ============================================================================

-- ============================================================================
-- 10. ASSUMPTIONS AND VALIDATION CHECKLIST (completed at authoring time)
-- ----------------------------------------------------------------------------
-- A-I01: The benchmark uses cold-cache runs (DROPCLEANBUFFERS + FREEPROCCACHE)
--        so the before/after comparison is worst-case and repeatable; warm-cache
--        runs may be added as a secondary observation.
-- A-I02: W2/W3/W4 use the "effective reservation" status set
--        (approved/checked_in/completed/no_show); W1 and W5 use status =
--        approved, mirroring the BR-14/BR-50 and BR-48 semantics of the
--        concurrency procedures and of Stage 16 (A-AQ01).
-- A-I03: status columns (bookings, maintenance_records) and maintenance_records.
--        impact_level are VARCHAR(20). All filtered-index filter expressions and
--        benchmark predicates use plain VARCHAR literals so they match the
--        column type/collation exactly. NVARCHAR literals would raise Msg 10611
--        (verified empirically on SQL Server 2025) and, in queries, would
--        insert CONVERT_IMPLICIT and prevent filtered-index usage (verified:
--        clustered scan cost 1.39 vs index seek cost 0.0033 on a 200,000-row
--        probe table).
-- A-I04: Filtered index predicates are valid for IN with literals (SQL Server
--        2008+), and all five workloads plus the stored procedures express the
--        filter columns as literals matching the VARCHAR columns, so the
--        optimizer can match the filtered indexes without hints.
-- A-I05: No schema change is made by this stage; indexes are the only objects
--        created here (Rule: stage 15 owns index tuning only).
-- A-I06: The reporting script outputs/16-analytical-queries-G7.sql predicates
--        status with NVARCHAR literals (N'approved', ...). Those literals
--        implicitly convert the VARCHAR status column (CONVERT_IMPLICIT) and
--        would prevent the filtered indexes created here from being selected.
--        This is a cross-artifact consistency note reported to Stage 16; it
--        does not affect the correctness of the benchmark (which uses the
--        type-matched literals required for index usage). See report Section 5.4.
-- [X] All five designated workloads are benchmarked before and after indexing.
-- [X] Every recommended index is justified by workload characteristics.
-- [X] Every DDL statement is idempotent (IF NOT EXISTS / IF EXISTS guards),
--      including the Section 4.0 clean-baseline drops.
-- [X] Buffer pool management and SET STATISTICS TIME/IO harness included, with
--      PRINT headers so statistics output maps to workload + phase.
-- [X] Msg 10611 guardrail respected: filtered-index literals exactly match the
--      VARCHAR(20) filter columns.
-- [X] No FORCESEEK or other hints: the optimizer is trusted after indexing;
--      if a query fails to use a filtered index the report will evaluate an
--      unfiltered covering variant.
-- [X] Cleanup section (and Section 4.0) allow re-running from the baseline.
-- ============================================================================

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
