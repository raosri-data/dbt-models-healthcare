# dbt-models-healthcare

Sample dbt project demonstrating staging, intermediate, and mart layers,
with tests and an SCD Type 2 pattern for patient/provider records.

Structure:
- models/
  - staging/
  - marts/
- macros/
- seeds/ (optional samples)
- schema.yml includes tests and descriptions

Run locally:
- Install dbt (core) and configure profiles.yml for your Snowflake project.
- `dbt run` and `dbt test`
