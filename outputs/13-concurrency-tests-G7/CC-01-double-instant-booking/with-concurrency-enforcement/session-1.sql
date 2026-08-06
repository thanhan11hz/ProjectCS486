-- ============================================================================
-- CC-01 -- SESSION 1 (WITH enforcement)
-- Two users submit instant bookings for the SAME space (X-100) and the SAME
-- overlapping period (2026-09-01 09:00-11:00). Session 1 starts first, acquires
-- the space-row UPDLOCK + HOLDLOCK at the start of its procedure and HOLDS it
-- through the WAITFOR DELAY inside the procedure (between the availability check
-- and the INSERT). Session 2 (session-2.sql) therefore blocks on that lock.
--
-- Run procedure.sql once first (or it is already deployed), then run this file
-- in Query window 1 and, ~2 seconds later, session-2.sql in Query window 2.
-- ============================================================================
USE [CS486_Booking_System];
GO
SET NOCOUNT ON;
GO

-- Clean up any rows left by an earlier run so the test starts from a clean
-- state for space X-100 (delete approvals/sessions before their bookings).
DELETE a FROM dbo.approvals a
  JOIN dbo.bookings b ON b.booking_id = a.booking_id
 WHERE b.space_code = N'X-100';
DELETE s FROM dbo.sessions s
  JOIN dbo.bookings b ON b.booking_id = s.booking_id
 WHERE b.space_code = N'X-100';
DELETE FROM dbo.bookings WHERE space_code = N'X-100';
DELETE FROM dbo.maintenance_records WHERE space_code = N'X-100';
GO

PRINT 'Session 1: instant booking 09:00-11:00 for X-100 (U-101).';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-101',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'student_activity',
    @expected_participants = 20;
GO

-- Final state: exactly ONE approved booking must remain.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO