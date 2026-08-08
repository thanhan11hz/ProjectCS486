-- ============================================================================
-- Analytical Queries Script (Phase 2 / Stage 16)
-- Project     : CS486 Booking System (Group 7)
-- DBMS        : Microsoft SQL Server (T-SQL)
-- Target      : SQL Server 2019+ (T-SQL)
-- Description : Executable reporting queries for the Facility Manager's new
--               reporting needs (RC-08). Formatted for baseline execution
--               against the large-scale dataset produced by
--               outputs/14-data-generator-G7.sql (>= 100,000 bookings across
--               three academic years + autumn 2026 semester).
-- Source      : req/business-requirement-change.md  -- "New reporting needs"
-- Design      : outputs/09-updated-erd-and-logical-design-G7.md
-- Schema      : outputs/05-db-implementation-G7.sql +
--               outputs/10-schema-migration-G7.sql (impact_level,
--               advisory_acknowledged)
-- Artifact    : outputs/16-analytical-queries-G7.sql
-- Prerequisite: Database CS486_Booking_System populated by
--               outputs/14-data-generator-G7.sql.
-- ============================================================================

-- ============================================================================
-- 1. EXECUTION CONTEXT
-- ----------------------------------------------------------------------------
-- DATEFIRST 1 (Monday = 1 ... Sunday = 7) makes the weekday dimension of
-- Q2 (Booking Density Heatmap) deterministic regardless of session defaults.
-- ============================================================================

USE [CS486_Booking_System];
GO

SET NOCOUNT ON;
SET DATEFIRST 1;
GO

IF DB_ID(N'CS486_Booking_System') IS NULL
    THROW 51000, N'Database CS486_Booking_System does not exist. Execute outputs/05-db-implementation-G7.sql and then outputs/14-data-generator-G7.sql first.', 1;
GO

-- ============================================================================
-- 2. STEP 15 DESIGNATION — QUERIES SELECTED FOR INDEX TUNING
-- ----------------------------------------------------------------------------
-- Per Phase 2 Stage 15, in addition to the mandatory Multi-Criteria Room
-- Finder (Q3) and the BR-14/BR-50 booking-conflict availability check, the
-- following TWO reporting queries are designated for detailed execution plan
-- analysis and index tuning in outputs/15-index-tuning-report-G7.md:
--
-- | # | Query selected for Step 15                  | Why |
-- |---|---------------------------------------------|-----|
-- | 1 | Q1 Total Approved Booking Hours per Space   | Large LEFT JOIN + GROUP BY aggregation over the full booking history; the LEFT JOIN drives a scan of bookings and the GROUP BY + HAVING aggregation over all spaces. Prime target for a covering index on bookings (space_code, status) INCLUDE (requested_start_time, requested_end_time) and a filtered index on bookings (requested_start_time) WHERE status IN (approved set). |
-- | 2 | Q2 Booking Density Heatmap (Weekday x Hour) | Semester-wide aggregation over up to ~100k booking rows with two DATEPART expressions in the GROUP BY. Prime target for a covering index on bookings (status, requested_start_time) INCLUDE (space_code) so the semester range can be seeked instead of scanned. |
--
-- NOT selected (still analyzed in Step 15 as mandatory): Q3 Multi-Criteria
-- Room Finder and the BR-14/BR-50 booking-conflict availability check.
-- ============================================================================

-- ============================================================================
-- SHARED SEMANTICS — "APPROVED BOOKING"
-- ----------------------------------------------------------------------------
-- Throughout this script, "approved booking" (an effective reservation of a
-- space) is any booking whose status proves it passed approval, i.e. it is
-- either currently approved and upcoming ('approved') or was realized after
-- approval ('checked_in', 'completed', 'no_show'). Rejected / pending /
-- cancelled bookings never reserve the space and are excluded.
--
-- The only exception is Q4 (Maintenance Escalation Impact), which follows the
-- BR-48 semantics of usp_escalate_maintenance_impact in
-- outputs/12-concurrency-implementation-G7.sql: only still-upcoming approved
-- bookings (status = 'approved') are reported for staff contact, because
-- already-realized bookings cannot be un-booked.
-- ============================================================================

-- ============================================================================
-- Q1. TOTAL APPROVED BOOKING HOURS PER SPACE (for a given semester)
-- ----------------------------------------------------------------------------
-- Business question (RC-08 / "Total approved booking hours of each space for
-- a given semester"): how many approved booking hours did each space contribute
-- in a semester, including spaces with zero bookings?
-- Uses a LEFT JOIN from Space to Booking so that spaces with no bookings
-- report 0 hours (the requirement). A booking is attributed to the semester in
-- which it starts (requested_start_time inside [@SemesterStart, @SemesterEnd)).
-- ============================================================================

DECLARE @SemesterStart DATETIME2 = '2025-09-01 00:00:00'; -- Autumn 2025 semester
DECLARE @SemesterEnd   DATETIME2 = '2026-02-01 00:00:00'; -- exclusive end

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
      AND b.status                IN (N'approved', N'checked_in', N'completed', N'no_show')
      AND b.requested_start_time >= @SemesterStart
      AND b.requested_start_time  < @SemesterEnd
GROUP BY s.space_code, s.space_name, s.building, s.floor,
         s.room_number, s.space_type, s.capacity
ORDER BY approved_booking_hours DESC, s.space_code;
GO

-- ============================================================================
-- Q2. BOOKING DENSITY HEATMAP (Weekday x Hour) (for a given semester)
-- ----------------------------------------------------------------------------
-- Business question (RC-08 / "Number of approved bookings by weekday and hour
-- for a given semester"): which weekday x starting-hour slots are the busiest?
-- Aggregates approved booking counts by DATEPART(WEEKDAY, ...) and
-- DATEPART(HOUR, ...) of the requested start time. Weekday numbering is made
-- deterministic by SET DATEFIRST 1 (see Section 1).
-- ============================================================================

DECLARE @SemesterStart DATETIME2 = '2025-09-01 00:00:00'; -- Autumn 2025 semester
DECLARE @SemesterEnd   DATETIME2 = '2026-02-01 00:00:00'; -- exclusive end

SELECT
    DATEPART(WEEKDAY, b.requested_start_time) AS weekday_number,
    DATENAME(WEEKDAY, b.requested_start_time) AS weekday_name,
    DATEPART(HOUR,   b.requested_start_time)  AS start_hour,
    COUNT(*)                                  AS approved_booking_count
FROM bookings b
WHERE b.status                IN (N'approved', N'checked_in', N'completed', N'no_show')
  AND b.requested_start_time >= @SemesterStart
  AND b.requested_start_time  < @SemesterEnd
GROUP BY
    DATEPART(WEEKDAY, b.requested_start_time),
    DATENAME(WEEKDAY, b.requested_start_time),
    DATEPART(HOUR,   b.requested_start_time)
ORDER BY weekday_number, start_hour;
GO

-- ============================================================================
-- Q3. MULTI-CRITERIA ROOM FINDER
-- ----------------------------------------------------------------------------
-- Business question (RC-08 / "Available spaces that satisfy a required
-- capacity and a required facility list within a given time period"): which
-- spaces (1) meet the minimum capacity, (2) contain ALL facilities in the
-- required list (relational division via HAVING COUNT(DISTINCT facility_id) =
-- @RequiredFacilityCount), and (3) have no overlapping approved booking and no
-- active out-of-service maintenance in the requested period (BR-44, BR-14)?
--
-- The required facility list is passed as a table-valued parameter. The
-- sample below populates it by facility name so the script is robust against
-- the IDENTITY values of outputs/14-data-generator-G7.sql. Edit the sample
-- values to match the facilities the user requires.
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = N'RequiredFacilityListType')
    CREATE TYPE dbo.RequiredFacilityListType AS TABLE
    (
        facility_id INT NOT NULL PRIMARY KEY
    );
GO

DECLARE @TargetStart        DATETIME2 = '2026-09-15 09:00:00'; -- target period
DECLARE @TargetEnd          DATETIME2 = '2026-09-15 11:00:00';
DECLARE @RequiredCapacity   INT       = 40;
DECLARE @RequiredFacilities AS dbo.RequiredFacilityListType;
DECLARE @RequiredFacilityCount INT = 2;

-- Sample requirement: a space equipped with a Projector AND Air Conditioning.
-- (Edit this list for other facility requirements.)
INSERT INTO @RequiredFacilities (facility_id)
SELECT facility_id
FROM facilities
WHERE facility_name IN (N'Projector', N'Air Conditioning');

-- @RequiredFacilityCount MUST equal the number of distinct facilities in the
-- list above (COUNT(DISTINCT) semantics of the relational division).
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
          WHERE b.space_code            = s.space_code
            AND b.status                IN (N'approved', N'checked_in', N'completed', N'no_show')
            AND b.requested_start_time  < @TargetEnd
            AND b.requested_end_time    > @TargetStart
      )
  AND NOT EXISTS
      (
          SELECT 1
          FROM maintenance_records m
          WHERE m.space_code     = s.space_code
            AND m.impact_level   = N'out_of_service'
            AND m.status         IN (N'reported', N'in_progress')  -- open record
            AND m.start_time     < @TargetEnd
            AND (m.completion_time IS NULL OR m.completion_time > @TargetStart)
      )
GROUP BY s.space_code, s.space_name, s.building, s.floor,
         s.room_number, s.capacity, s.space_type, s.usage_policy
HAVING COUNT(DISTINCT sf.facility_id) = @RequiredFacilityCount
ORDER BY s.capacity, s.space_code;
GO

-- ============================================================================
-- Q4. MAINTENANCE ESCALATION IMPACT REPORT
-- ----------------------------------------------------------------------------
-- Business question (RC-08 / BR-48, RC-05 / "Approved bookings affected when
-- a maintenance record is escalated to out-of-service"): if the specified
-- advisory maintenance record were escalated to out-of-service, which approved
-- bookings overlap its maintenance period, and how can staff contact their
-- requesters?
-- Period-overlap uses the same predicate as the BR-44 trigger and
-- usp_escalate_maintenance_impact: [start_time, completion_time) vs
-- [requested_start_time, requested_end_time). An open record (completion_time
-- IS NULL) overlaps any later booking.
-- Status scope: still-upcoming approved bookings (status = 'approved'), in
-- line with the BR-48 semantics of usp_escalate_maintenance_impact — only
-- requesters of not-yet-realized bookings need to be contacted.
-- ============================================================================

DECLARE @MaintenanceID INT = 1; -- the advisory record being escalated

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
  AND b.status = N'approved'
  AND b.requested_end_time > m.start_time
  AND (m.completion_time IS NULL OR b.requested_start_time < m.completion_time)
ORDER BY b.requested_start_time, u.user_id;
GO

-- ============================================================================
-- TRACEABILITY — REPORT TO REQUIREMENT CHANGE TO BUSINESS RULE
-- ----------------------------------------------------------------------------
-- | Query | Reporting Need (req/business-requirement-change.md) | Business Rule | Design Ref |
-- |-------|-----------------------------------------------------|---------------|------------|
-- | Q1    | Total approved booking hours of each space for a given semester | BR-14 (approved bookings), BR-50 | RC-08, A-05 |
-- | Q2    | Number of approved bookings by weekday and hour for a given semester | BR-14 (approved bookings), BR-50 | RC-08, A-05 |
-- | Q3    | Available spaces satisfying capacity + facility list within a period | BR-14/BR-50 (overlap), BR-44 (out-of-service), BR-42 (impact_level) | RC-08, 09 §3.7 |
-- | Q4    | Approved bookings affected by escalation to out-of-service | BR-48 (escalation impact), BR-14/BR-50 | RC-05, RC-08, A-05 |
-- ============================================================================

-- ============================================================================
-- ASSUMPTIONS AND OPEN NOTES
-- ----------------------------------------------------------------------------
-- A-AQ01: "Approved booking" = status IN ('approved','checked_in','completed',
--   'no_show') for Q1-Q3 (effective reservations); Q4 uses status = 'approved'
--   to match the BR-48 escalation procedure (12-concurrency-implementation-G7.sql).
-- A-AQ02: A booking is attributed to the semester in which it starts
--   (requested_start_time in [@SemesterStart, @SemesterEnd)). No pro-rating of
--   hours is applied to bookings straddling a semester boundary.
-- A-AQ03: Weekday numbering is normalized with SET DATEFIRST 1 (Monday = 1).
-- A-AQ04: Q3 treats status under_maintenance / temporarily_closed / retired as
--   non-bookable (BR-32 retained part) and treats open out-of-service
--   maintenance as blocking for the target period (BR-44). Advisory records do
--   not block (BR-45).
-- A-AQ05: Q4 is a derived query (BR-48, A-05); it does not modify the escalation
--   itself, which is the responsibility of usp_escalate_maintenance_impact in
--   outputs/12-concurrency-implementation-G7.sql.
-- ============================================================================

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
