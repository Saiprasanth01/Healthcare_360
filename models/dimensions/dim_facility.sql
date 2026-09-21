with stg as (
    select * from {{ ref('stg_facilities') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['facility_id']) }} as facility_sk,
    facility_id,
    facility_name,
    address,
    city,
    state
from stg
