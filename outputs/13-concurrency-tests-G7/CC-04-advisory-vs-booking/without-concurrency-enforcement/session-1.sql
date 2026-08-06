-- ============================================================================
-- CC-04 -- SESSION 1 (WITHOUT enforcement)  [booking creation side]
-- The booking procedure (UNLOCKED) takes its advisory snapshot (sees no advisory),
-- INSERTs the pending booking with advisory_acknowledged = NULL, and then waits
-- inside the WAITFOR DELAY between the INSERT and the COMMIT. Session 2 records an
-- advisory during that wait and COMMITS it BEFORE this booking commits. The
-- booking therefore finalises with a NULL acknowledgement while an advisory was
-- already active at booking time -- the notification obligation (BR-45/BR-46) is
-- silently bypassed. Compare this session's final state with the enforcement run.
--
-- Run this in Query window 1, then session-2.sql in Query window 2 a second later.
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

WAITFOR DELAY '00:00:01';
GO

PRINT 'Session 1: submit pending booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_booking_pending
    @requester_id          = N'U-401',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'meeting',
    @expected_participants = 18;
GO

-- Conflict outcome: the booking stores advisory_acknowledged = NULL even though
-- Session 2's advisory (08:00-12:00) was active at the time this booking was
-- created.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status, advisory_acknowledged
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO