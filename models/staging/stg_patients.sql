with source as (
    select * from {{ source('health_raw', 'patients') }}
),

cleaned as (
    select
        patient_id,
        first_name,
        last_name,
        first_name || ' ' || last_name   as full_name,
        dob::date                         as dob,
        gender,
        race,
        address,
        city,
        state,
        zip,
        created_ts::timestamp_ntz         as created_at
    from source
)

select * from cleaned
