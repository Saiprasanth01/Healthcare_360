with stg as (
    select distinct
        diagnosis_code,
        diagnosis_description
    from {{ ref('stg_diagnosis') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['diagnosis_code']) }} as diagnosis_sk,
    diagnosis_code,
    diagnosis_description                                       as description,
    'ICD-10'                                                    as icd_version
from stg
