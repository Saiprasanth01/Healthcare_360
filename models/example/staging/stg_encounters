with source as (
    select * from {{ source('health_raw', 'encounters') }}
),

cleaned as (
    select
        encounter_id,
        patient_id,
        provider_id as doctor_id,   -- Maps provider_id to doctor_id
        facility_id,
        encounter_type as visit_type,
        encounter_date::timestamp_ntz as admission_date,
        discharge_date::timestamp_ntz as discharge_date,
        created_ts::timestamp_ntz as created_at
    from source
)

select * from cleaned