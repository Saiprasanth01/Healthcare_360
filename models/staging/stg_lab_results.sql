with source as (
    select * from {{ source('health_raw', 'lab_results') }}
),

cleaned as (
    select
        lab_result_id,
        encounter_id,
        patient_id,
        test_name,
        result_value::numeric(10,2) as result_value,
        units,
        normal_range,
        test_date::timestamp_ntz as test_date,
        created_ts::timestamp_ntz as created_at
    from source
)

select * from cleaned