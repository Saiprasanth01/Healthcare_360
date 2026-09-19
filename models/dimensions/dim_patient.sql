with stg as (
    select * from {{ ref('stg_patients') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['patient_id']) }} as patient_sk,
    patient_id,
    full_name,
    dob,
    gender,
    race,
    city,
    state,
    zip,
    current_date()              as effective_start_dt,
    null::date                  as effective_end_dt,
    true                        as is_current
from stg
