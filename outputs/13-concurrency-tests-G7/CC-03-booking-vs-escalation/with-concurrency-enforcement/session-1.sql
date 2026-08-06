-- ============================================================================
-- CC-03 -- SESSION 1 (WITH enforcement)  [booking creation side]
-- Space X-100 has an ADVISORY maintenance record covering 08:00-12:00. This
-- session submits a pending booking for 09:00-11:00 while Session 2 escalates
-- that advisory record to out-of-service. Because booking creation holds the
-- space-row UPDLOCK + HOLDLOCK, Session 2's escalation blocks until the booking
-- commits; the booking therefore either commits BEFORE the escalation (and is
-- later found by the BR-48 identification) or is rejected because the
-- escalation already committed and the period is out-of-service (BR-44).
-- ============================================================================
USE [CS486_Booking_System];
GO

-- Prepare the space and its advisory maintenance record.
IF NOT EXISTS (SELECT 1 FROM dbo.spaces WHERE space_code = N'X-100')
    INSERT INTO dbo.spaces (space_code, space_type) VALUES (N'X-100', N'classroom');
GO

DECLARE @mtn_id INT;
INSERT INTO dbo.maintenance_records
    (reporter_id, space_code, assigned_staff_id, problem_description,
     start_time, status, impact_level)
VALUES
    (N'U-301', N'X-100', N'FM-302', N'AC unit running hot',
     '2026-09-01 08:00:00', N'reported', N'advisory');
SET @mtn_id = SCOPE_IDENTITY();
PRINT N'Prepared advisory maintenance #' + CAST(@mtn_id AS VARCHAR(20));

-- Keep the maintenance id available across the batch boundary.
SELECT @mtn_id AS advisory_maintenance_id INTO #t FROM (SELECT 1) x;
GO

WAITFOR DELAY '00:00:03';

PRINT 'Session 1: submit pending booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_booking_pending
    @requester_id          = N'U-303',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'lecture',
    @expected_participants = 40;
GO

SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO