# aws_dbt_snowflake_project

The dbt project for the Airbnb analytics pipeline. See the [repository README](../README.md) for the architecture, setup instructions and data tests.

```bash
uv run dbt debug      # verify the Snowflake connection
uv run dbt run        # build models
uv run dbt snapshot   # build SCD Type 2 dimensions
uv run dbt test       # run data tests
```
