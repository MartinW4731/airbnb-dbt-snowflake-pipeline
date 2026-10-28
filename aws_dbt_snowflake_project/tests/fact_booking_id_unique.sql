-- Each booking must appear only once in the fact table; returned rows are duplicated booking ids.
SELECT
    BOOKING_ID,
    COUNT(*) AS cnt
FROM {{ ref('fact') }}
GROUP BY BOOKING_ID
HAVING COUNT(*) > 1
