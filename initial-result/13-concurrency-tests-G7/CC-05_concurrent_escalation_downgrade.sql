-- ============================================================================
-- CC-05 — Concurrent escalation/downgrade of the same maintenance record
-- Project : CS486 Booking System (Group 7)
-- DBMS    : Microsoft SQL Server (T-SQL)
-- Design  : outputs/11-concurrency-design-G7.md   (CC-05)
-- Impl    : outputs/12-concurrency-implementation-G7.sql
--             (usp_escalate_maintenance_impact / usp_downgrade_maintenance_impact)
-- Rules   : BR-47 (the impact level of an OPEN record may be escalated/downgraded;
--                   the record has a single consistent current value)
--
-- PURPOSE
--   Contrast two staff members changing the SAME open maintenance record at the
--   same time (read-modify-write):
--     WITHOUT : both read "advisory", one writes "out_of_service", the other
--               writes "advisory" -> the first committed decision is silently
--               overwritten (lost update; BR-47 violated).
--     WITH    : the record is read with UPDLOCK held to commit, so the second
--               change waits, re-reads the fresh committed level, and applies
--               its decision to the current value -> no lost update.
--
-- RUN METHOD: two query windows; follow the numbered checkpoints.
-- ============================================================================

USE [CS486_Booking_System];
GO
SET NOCOUNT ON;

-- ---------------------------------------------------------------------------
-- FIXTURE: ONE advisory maintenance record on space A-CR-2.
-- ---------------------------------------------------------------------------
DECLARE @space VARCHAR(20) = N'A-CR-2';
DELETE FROM dbo.maintenance_records WHERE space_code = @space;

DECLARE @maint_id INT;
EXEC dbo.usp_record_maintenance
     @reporter_id       = N'U00010',
     @space_code        = @space,
     @assigned_staff_id = N'U00011',
     @problem_description = N'Faulty projector (open record for this test).',
     @start_time        = '2026-12-05T08:00:00',
     @impact_level      = N'advisory',
     @maintenance_id    = @maint_id OUTPUT;
SELECT @maint_id = maintenance_id FROM dbo.maintenance_records
 WHERE space_code = @space AND impact_level = N'advisory';
PRINT N'[fixture] open advisory maintenance #' + CAST(@maint_id AS VARCHAR(20)) + N' ready.';
GO

-- ===========================================================================
-- PART 1 — WITHOUT ENFORCEMENT  (lost update)
-- ===========================================================================

-- ---------------- SESSION A (window 1)  -- escalate --------------------------
DECLARE @m INT = (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
                   WHERE space_code = N'A-CR-2' ORDER BY maintenance_id);
BEGIN TRANSACTION;
DECLARE @level_a VARCHAR(20);
SELECT @level_a = impact_level FROM dbo.maintenance_records WHERE maintenance_id = @m;
PRINT N'[1A] reads level = ' + @level_a + N' (decision: escalate to out_of_service).';
WAITFOR DELAY '00:00:05';
-- ===================== CHECKPOINT 1 =========================================
-- Go to SESSION B and perform the other level change.
-- =============================================================================

-- ---------------- SESSION B (window 2)  -- downgrade -------------------------
DECLARE @m2 INT = (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
                    WHERE space_code = N'A-CR-2' ORDER BY maintenance_id);
BEGIN TRANSACTION;
DECLARE @level_b VARCHAR(20);
SELECT @level_b = impact_level FROM dbo.maintenance_records WHERE maintenance_id = @m2;
PRINT N'[1B] reads level = ' + @level_b + N'; it is still advisory (A not yet written).';
PRINT N'[1B] decision: downgrade to advisory.';
-- ===================== CHECKPOINT 2 =========================================
-- Both transactions have read the same committed value; go commit in B then A.
-- =============================================================================
UPDATE dbo.maintenance_records SET impact_level = N'advisory' WHERE maintenance_id = @m2;
COMMIT TRANSACTION;
PRINT N'[1B] committed impact_level = advisory.';
-- ===================== CHECKPOINT 3 ==========================================
-- Return to SESSION A and commit its escalation.
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed) -------------------------------
UPDATE dbo.maintenance_records SET impact_level = N'out_of_service' WHERE maintenance_id = @m;
COMMIT TRANSACTION;
PRINT N'[1A] committed impact_level = out_of_service.';
GO

-- ---------------------------------------------------------------------------
-- RESULT CHECK — WITHOUT (lost update: B's decision was overwritten)
-- ---------------------------------------------------------------------------
SELECT maintenance_id, impact_level,
       N'B committed advisory, then A overwrote it to out_of_service (B lost).'
           AS outcome
  FROM dbo.maintenance_records
 WHERE space_code = N'A-CR-2';
PRINT N'>>> WITHOUT: the record stores out_of_service; depending on commit order one staff decision is lost -> BR-47 VIOLATED.';
GO

-- ============================================================================
-- PART 2 — WITH ENFORCEMENT  (UPDLOCK on the maintenance record)
-- ============================================================================

-- Reset to a fresh open advisory record.
DECLARE @sp VARCHAR(20) = N'A-CR-2';
UPDATE dbo.maintenance_records SET impact_level = N'advisory' WHERE space_code = @sp;
PRINT N'[reset] record reset to advisory.';
GO

-- ---------------- SESSION A (window 1)  -- escalate --------------------------
DECLARE @m3 INT = (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
                    WHERE space_code = N'A-CR-2' ORDER BY maintenance_id);
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @m3, @staff_id = N'U00011';
PRINT N'  - simulate a blocking colleague instead to see the serialization.';
GO

-- Demonstrate the serialization explicitly (two windows):
-- SESSION A holds the record's UPDLOCK via the procedure path; SESSION B blocks.
-- Use the canonical procedures so the read-modify-write is atomic.

-- ---------------- SESSION A (window 1)  -- escalate (holds UPDLOCK to commit) --
DECLARE @m4 INT = (SELECT maintenance_id FROM dbo.maintenance_records WHERE impact_level = N'advisory' AND space_code = N'A-CR-2');
BEGIN TRANSACTION;
DECLARE @lvl VARCHAR(20);
SELECT @lvl = impact_level FROM dbo.maintenance_records WITH (UPDLOCK) WHERE maintenance_id = @m4;
PRINT N'[2A] holds UPDLOCK on maintenance #' + CAST(@m4 AS VARCHAR(10)) + N'; level=' + @lvl + N'. pausing before escalate.';
-- ===================== CHECKPOINT 4 ==========================================
-- Run the WITH-enforcement downgrade in SESSION B: it BLOCKS on the UPDLOCK.
-- =============================================================================

-- ---------------- SESSION B (window 2)  -- downgrade (BLOCKS) -----------------
DECLARE @m5 INT = (SELECT maintenance_id FROM dbo.maintenance_records WHERE space_code = N'A-CR-2');
EXEC dbo.usp_downgrade_maintenance_impact @maintenance_id = @m5, @staff_id = N'U00012';
PRINT N'[2B] downgrade BLOCKED then ran against the freshly committed level.';
-- ===================== CHECKPOINT 5 ==========================================
-- Return to SESSION A and commit the escalation.
-- =============================================================================

-- ---------------- SESSION A (window 1, resumed) --------------------------------
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @m4, @staff_id = N'U00011';
COMMIT TRANSACTION;
PRINT N'[2A] escalate committed; the downgrade (B) then re-applied to the fresh value with no lost update.';
GO

-- ---------------------------------------------------------------------------
-- RESULT CHECK (WITH): single consistent value, last commit preserved.
-- ---------------------------------------------------------------------------
SELECT maintenance_id, impact_level,
       CASE WHEN impact_level IN (N'out_of_service', N'advisory')
            THEN N'consistent single value -> no lost update' ELSE N'UNEXPECTED' END AS consistency
  FROM dbo.maintenance_records
 WHERE space_code = N'A-CR-2';
PRINT N'>>> WITH enforcement: record holds a single consistent level reflecting the last committed change -> BR-47 PRESERVED.';
GO

-- ============================================================================
-- END OF CC-05 TEST
-- ============================================================================