{{ config(
    materialized='table',
    schema='mart'
) }}

-- Source provider data
with src as (
    select
        provider_id,
        npi,
        first_name,
        last_name,
        specialty,
        taxonomy_code,
        phone,
        email,
        address_line1,
        address_line2,
        city,
        state,
        postal_code,
        updated_at
    from {{ source('raw', 'providers') }}
),

-- Clean & standardize
cleaned as (
    select
        provider_id,
        npi,
        upper(first_name) as first_name,
        upper(last_name)  as last_name,
        upper(specialty)  as specialty,
        taxonomy_code,
        phone,
        lower(email) as email,

        -- Clean address fields
        initcap(address_line1) as address_line1,
        initcap(address_line2) as address_line2,
        initcap(city) as city,
        upper(state) as state,
        postal_code,

        updated_at
    from src
),

-- Add display fields
final as (
    select
        provider_id,
        npi,
        first_name,
        last_name,
        first_name || ' ' || last_name as provider_full_name,
        specialty,
        taxonomy_code,
        phone,
        email,
        address_line1,
        address_line2,
        city,
        state,
        postal_code,
        updated_at
    from cleaned
)

select * from final;
