-- Each business key may have only one current version (dbt_valid_to = '9999-12-31') in a snapshot.
-- Otherwise joining the fact table to a dim would duplicate bookings.
-- severity='warn': report the problem without failing the run.
{{ config(severity='warn') }}

SELECT 'dim_listings' AS dim_table, LISTING_ID AS business_key, COUNT(*) AS cnt
FROM {{ ref('dim_listings') }}
WHERE dbt_valid_to = '9999-12-31'
GROUP BY LISTING_ID
HAVING COUNT(*) > 1

UNION ALL

SELECT 'dim_hosts', HOST_ID, COUNT(*)
FROM {{ ref('dim_hosts') }}
WHERE dbt_valid_to = '9999-12-31'
GROUP BY HOST_ID
HAVING COUNT(*) > 1

UNION ALL

SELECT 'dim_bookings', BOOKING_ID, COUNT(*)
FROM {{ ref('dim_bookings') }}
WHERE dbt_valid_to = '9999-12-31'
GROUP BY BOOKING_ID
HAVING COUNT(*) > 1
