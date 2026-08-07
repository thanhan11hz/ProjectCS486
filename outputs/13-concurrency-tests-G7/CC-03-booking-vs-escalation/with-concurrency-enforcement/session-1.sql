-- ============================================================================
-- CC-03 -- SESSION 1 (WITH enforcement)  [booking creation side]
-- Space X-100 has an ADVISORY maintenance record covering 08:00-12:00. This
-- session submits an INSTANT (approved) booking for 09:00-11:00 while Session 2
-- escalates that advisory record to out-of-service. The booking procedure holds
-- the space-row UPDLOCK + HOLDLOCK from before the BR-44 check until the COMMIT
-- (including the in-procedure WAITFOR DELAY between INSERT and COMMIT), so
-- Session 2's escalation blocks until this booking commits. The booking therefore
-- commits BEFORE the escalation, and Session 2's BR-48 identification subsequently
-- FINDS it (returns it) -- no approved booking is ever left un-identified on an
-- out-of-service period.
--
-- Run procedure.sql once first, then run this in Query window 1 and session-2.sql
-- in Query window 2 a second later.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

-- Clean the test space for a deterministic run.
DELETE a FROM dbo.approvals a
  JOIN dbo.bookings b ON b.booking_id = a.booking_id
 WHERE b.space_code = N'X-100';
DELETE s FROM dbo.sessions s
  JOIN dbo.bookings b ON b.booking_id = s.booking_id
 WHERE b.space_code = N'X-100';
DELETE FROM dbo.bookings WHERE space_code = N'X-100';
DELETE FROM dbo.maintenance_records WHERE space_code = N'X-100';
GO

-- Prepare the space's ADVISORY maintenance record (08:00-12:00).
DECLARE @mtn_id INT;
INSERT INTO dbo.maintenance_records
    (reporter_id, space_code, assigned_staff_id, problem_description,
     start_time, status, impact_level)
VALUES
    (N'U-301', N'X-100', N'FM-302', N'AC unit running hot',
     '2026-09-01 08:00:00', N'reported', N'advisory');
SET @mtn_id = SCOPE_IDENTITY();
PRINT N'Prepared advisory maintenance #' + CAST(@mtn_id AS VARCHAR(20));
GO

PRINT 'Session 1: instant booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-303',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'lecture',
    @expected_participants = 40;
GO

-- Final state from Session 1: the approved booking exists (advisory maintenance
-- at booking time -> acknowledgement recorded).
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status, advisory_acknowledged
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO