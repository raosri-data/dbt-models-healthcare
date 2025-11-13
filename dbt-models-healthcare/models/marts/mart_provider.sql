-- models/marts/mart_provider.sql
with prov as (
  select
    provider_id,
    max(last_update_date) as last_update_date
  from {{ ref('stg_claims') }}
  group by provider_id
)
select p.provider_id, p.last_update_date
from prov p;
