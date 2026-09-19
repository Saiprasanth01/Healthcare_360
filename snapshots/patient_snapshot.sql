{% snapshot patient_snapshot %}

{{
    config(
        target_schema = 'SNAPSHOTS',
        unique_key    = 'patient_id',
        strategy      = 'check',
        check_cols    = ['first_name', 'last_name', 'address', 'city', 'state', 'zip']
    )
}}

select
    patient_id,
    first_name,
    last_name,
    full_name,
    dob,
    gender,
    race,
    address,
    city,
    state,
    zip,
    created_at
from {{ ref('stg_patients') }}

{% endsnapshot %}
