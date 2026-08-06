-- ============================================================================
-- CC-05 -- SESSION 2 (WITHOUT enforcement)  [downgrade side]
-- Downgrades the SAME maintenance record while Session 1 escalates it. Without
-- the UPDLOCK read, Session 2 also reads "advisory" and writes "advisory"
-- (a no-op) or, depending on interleaving, overwrites Session 1's out-of-service
-- back to advisory. The final impact level reflects a lost update -- one staff
-- decision is silently discarded.
-- Launch this after Session 1 has started (during its WAITFOR DELAY or while its
-- escalate is in flight).
-- ============================================================================
USE [CS486_Booking_System];
GO

WAITFOR DELAY '00:00:02';

DECLARE @mtn_id INT =
    (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
      WHERE space_code = N'X-100' ORDER BY maintenance_id DESC);

PRINT 'Session 2: downgrade maintenance to advisory.';
EXEC dbo.usp_downgrade_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-503';
GO

-- The final row shows the last-writer result; compare with Session 1's SELECT.
SELECT maintenance_id, impact_level, status, start_time, completion_time
  FROM dbo.maintenance_records
 WHERE space_code = N'X-100'
 ORDER BY maintenance_id;
GO