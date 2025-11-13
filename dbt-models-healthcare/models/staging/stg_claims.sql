-- models/staging/stg_claims.sql
with src as (
    select
      claim_id,
      patient_id,
      provider_id,
      claim_amount,
      last_update_date
    from {{ source('raw', 'claims') }}
)
select * from src;
