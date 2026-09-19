with source as (
    select * from {{ source('health_raw', 'diagnosis_records') }}
),

cleaned as (
    select
        encounter_id,
        diagnosis_code,
        diagnosis_description,
        diagnosis_rank
    from source
)

select * from cleaned
