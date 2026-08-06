-- ============================================================================
-- CC-03 -- SESSION 2 (WITHOUT enforcement)  [escalation side]
-- Escalates the space's advisory maintenance record to out-of-service using the
-- UNLOCKED procedure. Without the space lock, the escalation commits its
-- impact-level UPDATE and runs its BR-48 identification while Session 1's instant
-- booking is still UNCOMMITTED (it is inside the WAITFOR DELAY between its INSERT
-- and COMMIT). The identification therefore does NOT see the booking. Session 1
-- then commits its approved booking afterwards -> an approved booking now
-- overlaps the out-of-service maintenance period and was missed by the
-- identification (BR-48). The conflict is reproduced.
--
-- Launch this in Query window 2 one second after session-1.sql is started.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

WAITFOR DELAY '00:00:02';
GO

-- Find the advisory maintenance record prepared for space X-100. @mtn_id must be
-- in the SAME batch as the EXEC (T-SQL variables do not survive a GO separator).
DECLARE @mtn_id INT =
    (SELECT TOP 1 maintenance_id FROM dbo.maintenance_records
      WHERE space_code = N'X-100' AND impact_level = N'advisory'
      ORDER BY maintenance_id DESC);
PRINT N'Escalating advisory maintenance #' + CAST(@mtn_id AS VARCHAR(20));
PRINT 'Session 2: escalate advisory maintenance to out-of-service.';
EXEC dbo.usp_escalate_maintenance_impact @maintenance_id = @mtn_id, @staff_id = N'FM-302';
GO

-- With enforcement absent, the BR-48 result set above is EMPTY (it ran before
-- Session 1 committed). The approved booking appears only AFTER this session.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
   AND status = N'approved'
 ORDER BY booking_id;
GO