-- OBT is built with LEFT JOINs from silver_bookings, so the row counts must match.
-- A returned row means the joins duplicated or dropped bookings.
WITH obt AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('obt') }}
),
bookings AS (
    SELECT COUNT(*) AS cnt FROM {{ ref('silver_bookings') }}
)
SELECT
    obt.cnt AS obt_rows,
    bookings.cnt AS bookings_rows
FROM obt
CROSS JOIN bookings
WHERE obt.cnt <> bookings.cnt
