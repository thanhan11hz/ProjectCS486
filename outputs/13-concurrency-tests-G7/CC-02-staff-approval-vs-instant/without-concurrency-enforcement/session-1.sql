-- ============================================================================
-- CC-02 -- SESSION 1 (WITHOUT enforcement)  [staff approval path]
-- Same scenario as the with-enforcement test. Because the approval re-validation
-- is a plain unlocked read that releases its lock immediately, it can pass the
-- availability check even while Session 2's instant booking is concurrently
-- committing an overlapping booking.
-- ============================================================================
USE [CS486_Booking_System];
GO

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