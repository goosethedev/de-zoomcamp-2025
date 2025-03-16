# Module 4 Homework: Analytics Engineering

- [Summary](#summary)
- [Prerequisites](#prerequisites)
- [Homework answers](#homework-answers)

## Summary

The goal for this module was getting familiar with `dbt` as an ELT solution for managing transformations within a data warehousing solution.

For that, a prerequisite was having the [NYC Taxi dataset](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) including the Yellow Taxi, Green Taxi and For-Hire Vehicle data for the years 2019-2020 extracted and loaded into a BigQuery dataset.

Then, `dbt` would handle the creation of dimension and fact tables with clean data, ready to query using tools like Looker Studio, Tableau, etc.

**BONUS** Again, I created a [bash script](./data-loader/load-taxi-data.sh) to manage the data ingestion. [dlt](https://github.com/dlt-hub/dlt) could be used but, it was overkill for this use-case.

## Prerequisites

### Extracting and loading the Taxi data

Go to [Google Cloud Console](https://console.cloud.google.com) and click on the top right shell icon (or press `G` + `S`).

Click on _Open Editor_ and create an new file named `upload-taxi-data.sh`. In that file, copy and paste [the bash script](./data-loader/load-taxi-data.sh) to upload the data.

**IMPORTANT**: Ensure to modify the names of the GCS bucket and BigQuery dataset to be unique.

Open a shell within the editor, to add execution permissions and run it the script:

```bash
chmod +x upload-taxi-data.sh
bash upload-taxi.data.sh
```

Check that the GCS bucket has been created and it contains three directories with CSV files (24 for Yellow and Green, 12 for FHV data). Then proceed to BigQuery Studio to check if the dataset was created.

### Setting up dbt locally

You can use [dbt Cloud](https://www.getdbt.com/product/dbt-cloud) to create and deploy the pipeline. I decided to use a local setup, using [uv](https://github.com/astral-sh/uv) to manage the Python project, and the [gcloud](https://cloud.google.com/sdk/docs/install) CLI tool for Google Cloud authentication.

```bash
# Clone the repo
git clone https://github.com/goosethedev/de-zoomcamp-2025
cd de-zoompcamp-2025/04-analytics-engineering/taxi_rides_ny

# Setup the environment (with uv in my case)
uv venv --python 3.12.8
uv pip install dbt-core dbt-bigquery

# (Optional) Formatter files in VSCode with dbt power user ext
uv tool install 'shandy-sqlfmt[jinjafmt]'

# Login into your GCloud project
gcloud auth application-default login

# Activate the environment
source .venv/bin/activate
```

Then, you can run dbt commands.

```bash
# Check if connection is OK
dbt debug

# Run all the project objects (dev mode)
dbt run

# Deploy all to production
dbt run --var '{"is_test_run": "false"}'
```

## Homework answers

### Q1: Understanding dbt model resolution

Provided you've got the following sources.yaml

```yml
version: 2

sources:
  - name: raw_nyc_tripdata
    database: "{{ env_var('DBT_BIGQUERY_PROJECT', 'dtc_zoomcamp_2025') }}"
    schema: "{{ env_var('DBT_BIGQUERY_SOURCE_DATASET', 'raw_nyc_tripdata') }}"
    tables:
      - name: ext_green_taxi
      - name: ext_yellow_taxi
```

with the following env variables setup where dbt runs:

```bash
export DBT_BIGQUERY_PROJECT=myproject
export DBT_BIGQUERY_DATASET=my_nyc_tripdata
```

What does this `.sql` model compile to?

```sql
select *
from {{ source('raw_nyc_tripdata', 'ext_green_taxi' ) }}
```

- `select * from dtc_zoomcamp_2025.raw_nyc_tripdata.ext_green_taxi`
- `select * from dtc_zoomcamp_2025.my_nyc_tripdata.ext_green_taxi`
- **`select * from myproject.raw_nyc_tripdata.ext_green_taxi` << CORRECT**
- `select * from myproject.my_nyc_tripdata.ext_green_taxi`
- `select * from dtc_zoomcamp_2025.raw_nyc_tripdata.green_taxi`

The `DBT_BIGQUERY_PROJECT` env var is set, so it is used. `DBT_BIGQUERY_SOURCE_DATASET` is not, so the default value is used.

### Q2. dbt Variables & Dynamic Models

Say you have to modify the following dbt_model (`fct_recent_taxi_trips.sql`) to enable Analytics Engineers to dynamically control the date range.

- In development, you want to process only the last 7 days of trips.
- In production, you need to process the last 30 days for analytics.

```sql
select *
from {{ ref('fact_taxi_trips') }}
where pickup_datetime >= CURRENT_DATE - INTERVAL '30' DAY
```

What would you change to accomplish that in a such way that command line arguments takes precedence over ENV_VARs, which takes precedence over DEFAULT value?

- Add `ORDER BY pickup_datetime DESC` and `LIMIT {{ var("days_back", 30) }}`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", 30) }}' DAY`
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ env_var("DAYS_BACK", "30") }}' DAY`
- **Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ var("days_back", env_var("DAYS_BACK", "30")) }}' DAY` << CORRECT**
- Update the WHERE clause to `pickup_datetime >= CURRENT_DATE - INTERVAL '{{ env_var("DAYS_BACK", var("days_back", "30")) }}' DAY`

`var()` takes arguments from the command line, and `env_var()` from environment variables. The former should have precedence.

### Q3. dbt Data Lineage and Execution

Considering the [data lineage graph](https://github.com/DataTalksClub/data-engineering-zoomcamp/raw/main/cohorts/2025/04-analytics-engineering/homework_q2.png) **and** that `taxi_zone_lookup` is the only materialization build (from a .csv seed file)

Select the option that does NOT apply for materializing fct_taxi_monthly_zone_revenue:

- `dbt run`
- `dbt run --select +models/core/dim_taxi_trips.sql+ --target prod`
- `dbt run --select +models/core/fct_taxi_monthly_zone_revenue.sql`
- `dbt run --select +models/core/`
- **`dbt run --select models/staging/+` << CORRECT**

With `dbt run --select models/staging/+` all staging models (and their descendants) get materialized. However, the `dim_taxi_trips` (dependency of `fct_taxi_monthly_zone_revenue`) lack its `dim_zone_lookup` dependency, so is not built.

### Q4. dbt Macros and Jinja

Consider you're dealing with sensitive data (e.g.: PII), that is **only available to your team and very selected few individuals**, in the `raw layer` of your DWH (e.g: a specific BigQuery dataset or PostgreSQL schema),

- Among other things, you decide to obfuscate/masquerade that data through your staging models, and make it available in a different schema (a `staging layer`) for other Data/Analytics Engineers to explore
- And optionally, yet another layer (`service layer`), where you'll build your dimension (`dim_`) and fact (`fct_`) tables (assuming the Star Schema dimensional modeling) for Dashboarding and for Tech Product Owners/Managers

You decide to make a macro to wrap a logic around it:

```sql
{% macro resolve_schema_for(model_type) -%}

    {%- set target_env_var = 'DBT_BIGQUERY_TARGET_DATASET'  -%}
    {%- set stging_env_var = 'DBT_BIGQUERY_STAGING_DATASET' -%}

    {%- if model_type == 'core' -%} {{- env_var(target_env_var) -}}
    {%- else -%}                    {{- env_var(stging_env_var, env_var(target_env_var)) -}}
    {%- endif -%}

{%- endmacro %}
```

And use on your staging, `dim_` and `fact_` models as:

```sql
{{ config(
    schema=resolve_schema_for('core'),
) }}
```

That all being said, regarding macro above, select all statements that are true to the models using it:

- Setting a value for `DBT_BIGQUERY_TARGET_DATASET` env var is mandatory, or it'll fail to compile **TRUE**
- Setting a value for `DBT_BIGQUERY_STAGING_DATASET` env var is mandatory, or it'll fail to compile **FALSE**
- When using `core`, it materializes in the dataset defined in `DBT_BIGQUERY_TARGET_DATASET` **TRUE**
- When using `stg`, it materializes in the dataset defined in `DBT_BIGQUERY_STAGING_DATASET`, or defaults to `DBT_BIGQUERY_TARGET_DATASET` **TRUE**
- When using `staging`, it materializes in the dataset defined in `DBT_BIGQUERY_STAGING_DATASET`, or defaults to `DBT_BIGQUERY_TARGET_DATASET` **TRUE**

The only mandatory variable is `DBT_BIGQUERY_TARGET_DATASET`. When using `core`, `DBT_BIGQUERY_TARGET_DATASET`. If any other value is used, then `DBT_BIGQUERY_STAGING_DATASET` is used if set, or defaults to `DBT_BIGQUERY_TARGET_DATASET`.

### Q5.
