with source as (
    select * from {{ source('health_raw', 'facilities') }}
),

cleaned as (
    select
        facility_id,
        facility_name,
        address,
        city,
        state
    from source
)

select * from cleaned