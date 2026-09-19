with stg as (
    select * from {{ ref('stg_doctors') }}
),

fac as (
    select facility_sk, facility_id
    from {{ ref('dim_facility') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['s.provider_id']) }} as provider_sk,
    s.provider_id,
    s.npi,
    s.full_name,
    s.specialty,
    s.department,
    f.facility_sk
from stg s
left join fac f on s.facility_id = f.facility_id
