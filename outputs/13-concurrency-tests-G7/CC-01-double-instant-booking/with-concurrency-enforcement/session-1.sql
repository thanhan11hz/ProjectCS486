-- ============================================================================
-- CC-01 -- SESSION 1 (WITH enforcement)
-- Two users submit instant bookings for the SAME space (X-100) and the SAME
-- overlapping period (09:00-11:00). Session 1 starts first and immediately
-- acquires the UPDLOCK + HOLDLOCK on the space row, then the second request
-- (Session 2) is forced to wait until this transaction commits.
--
-- Run session-1.sql in Query window 1, then instant command. In a real run:
--   1) run this file, 2) its EXEC keeps the space intent lock until commit,
--   3) launch session-2.sql while this is in flight so it blocks.
-- ============================================================================
USE [CS486_Booking_System];
GO

-- Give the operator a moment to position both windows at the same start time.
WAITFOR DELAY '00:00:05';

PRINT 'Session 1: submitting instant booking 09:00-11:00 for space X-100.';
EXEC dbo.usp_submit_instant_booking
    @requester_id          = N'U-101',
    @space_code            = N'X-100',
    @requested_start_time  = '2026-09-01 09:00:00',
    @requested_end_time    = '2026-09-01 11:00:00',
    @purpose               = N'study_group',
    @expected_participants = 20;
GO

-- Final state: only ONE approved booking must exist.
SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
 ORDER BY booking_id;
GO