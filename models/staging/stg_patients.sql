with source as (
    select * from {{ source('health_raw', 'patients') }}
)

select * from source