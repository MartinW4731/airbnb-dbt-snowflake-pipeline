{% set configs = [
    {
        "table" : ref('obt'),
        "columns" : "GOLD_obt.BOOKING_ID, GOLD_obt.LISTING_ID, GOLD_obt.HOST_ID, GOLD_obt.TOTAL_AMOUNT, GOLD_obt.ACCOMMODATES, GOLD_obt.BEDROOMS, GOLD_obt.BATHROOMS, GOLD_obt.PRICE_PER_NIGHT, GOLD_obt.RESPONSE_RATE",
        "alias" : "GOLD_obt"
    },
    {
        "table" : ref('dim_listings'),
        "columns" : "",
        "alias" : "DIM_listings",
        "join_condition" : "GOLD_obt.listing_id = DIM_listings.listing_id AND DIM_listings.dbt_valid_to = '9999-12-31'"
    },
    {
        "table" : ref('dim_hosts'),
        "columns" : "",
        "alias" : "DIM_hosts",
        "join_condition" : "GOLD_obt.host_id = DIM_hosts.host_id AND DIM_hosts.dbt_valid_to = '9999-12-31'"
    }
] %}

SELECT
    {{ configs[0]['columns'] }}
FROM
    {% for cfg in configs %}
        {% if loop.first %}
            {{ cfg['table'] }} AS {{ cfg['alias'] }}
        {% else %}
            LEFT JOIN {{ cfg['table'] }} AS {{ cfg['alias'] }}
            ON {{ cfg['join_condition'] }}
        {% endif %}
    {% endfor %}
