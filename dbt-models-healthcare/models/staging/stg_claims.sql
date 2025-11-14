{{ config(
    materialized='view',
    schema='staging'
) }}

with source as (

    -- Raw claim feed
    select
        claim_id,
        patient_id,
        provider_id,
        claim_number,
        claim_type,
        service_date,
        billed_amount,
        paid_amount,
        status,
        diagnosis_code,
        procedure_code,
        created_at,
        updated_at
    from {{ source('raw', 'claims') }}

),

renamed as (

    select
        claim_id,
        patient_id,
        provider_id,
        claim_number,
        claim_type,
        service_date::date as service_date,
        billed_amount::float as billed_amount,
        paid_amount::float as paid_amount,
        upper(status) as claim_status,
        upper(diagnosis_code) as diagnosis_code,
        upper(procedure_code) as procedure_code,
        created_at,
        updated_at
    from source

),

cleaned as (

    select
        claim_id,
        patient_id,
        provider_id,
        claim_number,
        claim_type,
        service_date,
        billed_amount,
        paid_amount,
        claim_status,
        diagnosis_code,
        procedure_code,
        created_at,
        updated_at
    from renamed
)

select * from cleaned;
