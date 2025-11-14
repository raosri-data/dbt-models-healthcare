{{ config(materialized='table') }}

select
    CLAIM_ID,
    STATUS,
    DIAGNOSIS_CODE,
    PROCEDURE_CODE,
    UPDATED_AT
from {{ ref('stg_claims') }}
