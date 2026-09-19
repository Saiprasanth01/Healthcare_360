with diag as (
    select * from {{ ref('stg_diagnosis') }}
),

enc_sk as (
    select encounter_sk, encounter_id from {{ ref('fact_encounter') }}
),

dim_diag as (
    select diagnosis_sk, diagnosis_code from {{ ref('dim_diagnosis') }}
)

select
    e.encounter_sk,
    d.diagnosis_sk,
    diag.diagnosis_rank
from diag
left join enc_sk  e on diag.encounter_id  = e.encounter_id
left join dim_diag d on diag.diagnosis_code = d.diagnosis_code
