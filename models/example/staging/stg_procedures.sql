with source as (
    select * from {{ source('health_raw', 'procedures') }}
),

cleaned as (
    select
        encounter_id,
        procedure_code,
        procedure_description,
        procedure_date
    from source
)

select * from cleaned