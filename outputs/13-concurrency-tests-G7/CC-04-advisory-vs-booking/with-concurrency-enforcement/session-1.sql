-- ============================================================================
-- CC-04 -- SESSION 1 (WITH enforcement)  [booking creation side]
-- A user submits a PENDING booking for space X-100 (09:00-11:00) which has NO
-- active advisory maintenance at the start. The booking procedure holds the
-- space-row UPDLOCK + HOLDLOCK from before the advisory snapshot until the COMMIT
-- (including the in-procedure WAITFOR DELAY between INSERT and COMMIT), so
-- Session 2's advisory recording blocks until this booking commits. The advisory
-- therefore commits AFTER the booking's acknowledgement -> outside the
-- booking-time window (Q-05). The booking correctly carries
-- advisory_acknowledged = NULL and no notification obligation is bypassed.
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

-- With enforcement, the booking committed BEFORE the advisory; its NULL
-- acknowledgement is correct because no advisory was active at booking time.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status, advisory_acknowledged
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO