# Airbnb Analytics Pipeline with dbt and Snowflake

An end-to-end ELT project that turns raw Airbnb booking, listing and host data into analytics-ready tables in Snowflake, using dbt and a medallion (bronze / silver / gold) architecture.

## What this project demonstrates

- **Medallion architecture:** raw data is progressively cleaned and modeled across bronze, silver and gold layers, each in its own schema.
- **Incremental loading:** bronze models load only new rows using a watermark column; silver models upsert changed rows with `unique_key` (a `MERGE` under the hood).
- **Metadata-driven SQL:** the gold wide table (`obt`) is generated from a configuration list and a Jinja loop, so adding a joined table means adding one config entry.
- **Reusable macros:** shared SQL logic (`multiply`, `tag`, `trimmer`) and a custom `generate_schema_name` so models land in clean schema names.
- **Slowly changing dimensions (SCD Type 2):** dbt snapshots keep the full history of bookings, listings and hosts.
- **Star schema:** a `fact` table joined to the current version of each dimension.
- **Data tests:** singular tests with `warn` / `error` severities guard row counts, key uniqueness and value ranges.

## Architecture

```
Snowflake AIRBNB.STAGING (raw source tables)
        |
        v
BRONZE  bronze_bookings, bronze_listings, bronze_hosts      (incremental)
        |
        v
SILVER  silver_bookings, silver_listings, silver_hosts      (incremental upsert, cleaned and enriched)
        |
        v
GOLD    obt                                                 (wide table, metadata-driven joins)
        |-- ephemeral: bookings, listings, hosts            (column selection, no table created)
        |       |
        |       v
        |   snapshots: dim_bookings, dim_listings, dim_hosts (SCD Type 2)
        |
        +-- fact                                            (fact table joined to current dimension rows)
```

| Layer | Models | Materialization | Purpose |
| --- | --- | --- | --- |
| Bronze | `bronze_bookings`, `bronze_listings`, `bronze_hosts` | incremental | Copy new rows from the raw source tables |
| Silver | `silver_bookings`, `silver_listings`, `silver_hosts` | incremental, `unique_key` | Clean and enrich: booking totals, price tags, host response quality |
| Gold | `obt`, `fact` | table | Analytics-ready wide table and fact table |
| Gold | `bookings`, `listings`, `hosts` | ephemeral | Select the columns each snapshot tracks |
| Gold | `dim_bookings`, `dim_listings`, `dim_hosts` | snapshot | Full change history (SCD Type 2) |

## Project structure

```
.
├── pyproject.toml / uv.lock        # Python dependencies (managed with uv)
└── aws_dbt_snowflake_project/
    ├── dbt_project.yml             # Project config and per-layer defaults
    ├── macros/                     # multiply, tag, trimmer, generate_schema_name
    ├── models/
    │   ├── sources.yml             # Raw source tables in AIRBNB.STAGING
    │   ├── bronze/
    │   ├── silver/
    │   └── gold/                   # obt, fact and ephemeral/ models
    ├── snapshots/                  # dim_bookings, dim_listings, dim_hosts
    └── tests/                      # Singular data tests
```

## Data tests

| Test | What it checks | Severity |
| --- | --- | --- |
| `silver_bookings_total_amount_positive` | Booking totals are positive | warn above 0 rows, error above 10 rows |
| `silver_hosts_response_rate_in_range` | Host response rate is between 0 and 100 | warn |
| `obt_row_count_matches_bookings` | The wide table has the same row count as `silver_bookings` (joins add or drop no rows) | error |
| `fact_booking_id_unique` | Each booking appears once in `fact` | error |
| `dim_current_version_unique` | Each business key has exactly one current snapshot row | warn |

## Getting started

### Prerequisites

- Python 3.12 or later and [uv](https://docs.astral.sh/uv/)
- A Snowflake account with a warehouse, plus raw tables `listings`, `bookings` and `hosts` in `AIRBNB.STAGING`

### Setup

```bash
# Install dependencies
uv sync

# Configure the Snowflake connection (see below), then verify it
cd aws_dbt_snowflake_project
uv run dbt debug
```

### Connection profile

dbt reads credentials from `~/.dbt/profiles.yml`, which lives outside this repository so that no secrets are committed. This project uses key-pair authentication with a Snowflake service user:

```yaml
aws_dbt_snowflake_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_account_identifier>
      user: <SERVICE_USER_NAME>
      private_key_path: <path_to_private_key.p8>
      role: <your_role>
      warehouse: <your_warehouse>
      database: AIRBNB
      schema: dbt_schema
      threads: 1
```

### Run the pipeline

```bash
cd aws_dbt_snowflake_project

uv run dbt run --exclude fact   # build bronze, silver and the gold wide table
uv run dbt snapshot             # build the SCD Type 2 dimension tables
uv run dbt run --select fact    # build the fact table (it reads the dimensions)
uv run dbt test                 # run the data tests
```

`dbt run` does not execute snapshots, and `fact` reads the snapshot tables. On the first run, build everything except `fact`, then run `dbt snapshot`, then build `fact`. After that, a plain `dbt run` followed by `dbt snapshot` is enough.

## Notes and possible improvements

- `dim_bookings` uses the `timestamp` strategy on `CREATED_AT`. To detect status changes on existing bookings, switch to `strategy: check` with `check_cols: [BOOKING_STATUS]`.
- `fact` currently selects only keys and measures. Joining dimension attributes (such as city or host name) into it would complete the star schema.
- Add generic tests (`unique`, `not_null`, `relationships`) in YAML alongside the singular tests.

## Tech stack

dbt-core 1.12, dbt-snowflake 1.12, Snowflake, Python 3.12, uv
