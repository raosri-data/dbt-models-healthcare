{{ config(materialized='view') }}

select 
    CLAIM_ID,
    STATUS,
    DIAGNOSIS_CODE,
    PROCEDURE_CODE,
    UPDATED_AT
from {{ source('raw', 'claims') }}
