-- Booking total amount must be positive; returned rows are the invalid bookings.
-- Thresholds: 1-10 bad rows only warn, more than 10 fails the test.
{{ config(warn_if='>0', error_if='>10') }}

SELECT
    BOOKING_ID,
    TOTAL_AMOUNT
FROM {{ ref('silver_bookings') }}
WHERE TOTAL_AMOUNT IS NULL
   OR TOTAL_AMOUNT <= 0
