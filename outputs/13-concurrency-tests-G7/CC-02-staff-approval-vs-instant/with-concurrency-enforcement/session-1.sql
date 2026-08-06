-- ============================================================================
-- CC-02 -- SESSION 1 (WITH enforcement)  [staff approval path]
-- Prepares a pending booking for space X-100 (09:00-11:00) and then approves
-- it. Session 2 simultaneously submits an instant booking for the same space
-- and period. Both paths share the space-row UPDLOCK + HOLDLOCK, so only one of
-- them commits as an approved booking (BR-50).
-- ============================================================================
USE [CS486_Booking_System];
GO

-- Prepare a pending booking that Session 1 will approve.
IF NOT EXISTS (SELECT 1 FROM dbo.spaces WHERE space_code = N'X-100')
    INSERT INTO dbo.spaces (space_code, space_type) VALUES (N'X-100', N'classroom');
GO

DECLARE @pending_id INT;
INSERT INTO dbo.bookings
    (requester_id, space_code, requested_start_time, requested_end_time,
     purpose, expected_participants, status)
VALUES
    (N'U-201', N'X-100', '2026-09-01 09:00:00', '2026-09-01 11:00:00',
     N'seminar', 25, N'pending');
SET @pending_id = SCOPE_IDENTITY();
PRINT N'Prepared pending booking #' + CAST(@pending_id AS VARCHAR(20));

-- Give Session 2 a chance to start before we acquire the space lock.
WAITFOR DELAY '00:00:03';

PRINT 'Session 1: staff approves the pending booking.';
EXEC dbo.usp_approve_pending_booking
    @booking_id   = @pending_id,
    @approver_id  = N'FM-301';
GO

SELECT booking_id, requester_id, space_code, requested_start_time,
       requested_end_time, status
  FROM dbo.bookings
 WHERE space_code = N'X-100'
   AND requested_start_time >= '2026-09-01 00:00'
   AND requested_start_time <  '2026-09-02 00:00'
 ORDER BY booking_id;
GO