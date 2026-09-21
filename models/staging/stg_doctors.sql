-- STG_DOCTORS in RAW currently holds facility columns.
-- Replace source table once actual doctor/provider data is loaded.
with source as (
    select * from {{ source('health_raw', 'stg_doctors') }}
),

cleaned as (
    select
        facility_id::varchar  as provider_id,
        facility_name         as full_name,
        null::varchar         as npi,
        null::varchar         as specialty,
        null::varchar         as department,
        facility_id::varchar  as facility_id
    from source
)

select * from cleaned
