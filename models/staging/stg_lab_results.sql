-- STG_LAB_RESULTS in RAW currently holds diagnosis columns.
-- Replace source table once actual lab results data is loaded.
with source as (
    select * from {{ source('health_raw', 'stg_lab_results') }}
),

cleaned as (
    select
        encounter_id,
        diagnosis_code      as test_name,
        diagnosis_description as test_result,
        null::varchar       as test_unit,
        null::varchar       as reference_range,
        null::varchar       as result_flag,
        null::date          as lab_date
    from source
)

select * from cleaned
