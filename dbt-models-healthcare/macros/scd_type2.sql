{{ config(
    materialized='incremental',
    unique_key='patient_id',
    incremental_strategy='merge'  -- dbt will use MERGE for supported adapters
) }}

-- Target table: {{ this }}
-- Source table (incoming current snapshot): replace with your actual source
with source_data as (
    select
      patient_id,
      first_name,
      last_name,
      date_of_birth,
      gender,
      address_line1,
      address_line2,
      city,
      state,
      postal_code,
      phone_number,
      email,
      updated_at
    from {{ source('raw','patients') }} -- change as needed
),

-- compute a hash so we can easily detect changes
hashed_source as (
  select
    *,
    md5(
      concat(
        coalesce(first_name,''),'|',
        coalesce(last_name,''),'|',
        coalesce(date_of_birth::text,''),'|',
        coalesce(gender,''),'|',
        coalesce(address_line1,''),'|',
        coalesce(address_line2,''),'|',
        coalesce(city,''),'|',
        coalesce(state,''),'|',
        coalesce(postal_code,''),'|',
        coalesce(phone_number,''),'|',
        coalesce(email,'')
      )
    ) as row_hash
  from source_data
)

-- The incremental/merge behavior: when running full-refresh, create table with current flags
{% if not is_incremental() %}

select
  patient_id,
  first_name,
  last_name,
  date_of_birth,
  gender,
  address_line1,
  address_line2,
  city,
  state,
  postal_code,
  phone_number,
  email,
  row_hash,
  updated_at as source_updated_at,
  current_timestamp() as effective_from,
  null as effective_to,
  true as is_current
from hashed_source

{% else %}

-- MERGE-based incremental update
-- Note: dbt's `is_incremental()` branch runs MERGE on existing table `{{ this }}`
-- The MERGE below is written in a generic way, but may need small adapter tweaks.

merge into {{ this }} as target
using hashed_source as source
on target.patient_id = source.patient_id
when matched and target.is_current = true and target.row_hash <> source.row_hash then
  -- existing current record changed -> close old record and insert new row
  update set
    effective_to = current_timestamp(),
    is_current = false
  ;
-- Some warehouses (Snowflake/BigQuery) do not allow multiple statements in MERGE.
-- So we implement the SCD2 "close + insert" using a single MERGE that updates existing row and inserts new row in the WHEN NOT MATCHED THEN INSERT.
-- The exact syntax differs between warehouses. Below are two patterns (Snowflake-style and generic pseudo).
{% if target.type == 'snowflake' %}

merge into {{ this }} target
using (
  select * from hashed_source
) source
on target.patient_id = source.patient_id
-- Condition: existing current row changed -> close it
when matched and target.is_current = true and target.row_hash <> source.row_hash then
  update set
    effective_to = current_timestamp(),
    is_current = false
when not matched then
  insert (
    patient_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, state, postal_code,
    phone_number, email, row_hash, source_updated_at, effective_from, effective_to, is_current
  )
  values (
    source.patient_id, source.first_name, source.last_name, source.date_of_birth, source.gender,
    source.address_line1, source.address_line2, source.city, source.state, source.postal_code,
    source.phone_number, source.email, source.row_hash, source.updated_at, current_timestamp(), null, true
  );

{% else %}

-- Generic pattern for adapters that support MERGE with WHEN MATCHED UPDATE and WHEN NOT MATCHED INSERT:
merge into {{ this }} as target
using hashed_source as source
on target.patient_id = source.patient_id and target.is_current = true
when matched and target.row_hash <> source.row_hash then
  update set
    effective_to = current_timestamp(),
    is_current = false
when not matched by target then
  insert (
    patient_id, first_name, last_name, date_of_birth, gender,
    address_line1, address_line2, city, state, postal_code,
    phone_number, email, row_hash, source_updated_at, effective_from, effective_to, is_current
  )
  values (
    source.patient_id, source.first_name, source.last_name, source.date_of_birth, source.gender,
    source.address_line1, source.address_line2, source.city, source.state, source.postal_code,
    source.phone_number, source.email, source.row_hash, source.updated_at, current_timestamp(), null, true
  );

{% endif %}
{% endif %}
