-- Host response rate is a percentage and must be between 0 and 100.
-- severity='warn': a violation is reported but does not fail the run.
{{ config(severity='warn') }}

SELECT
    HOST_ID,
    RESPONSE_RATE
FROM {{ ref('silver_hosts') }}
WHERE RESPONSE_RATE < 0
   OR RESPONSE_RATE > 100
