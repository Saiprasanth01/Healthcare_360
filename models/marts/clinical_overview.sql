with encounters as (
    select * from {{ ref('fact_encounter') }}
),

patients as (
    select * from {{ ref('dim_patient') }}
),

providers as (
    select * from {{ ref('dim_provider') }}
),

facilities as (
    select * from {{ ref('dim_facility') }}
),

enc_date as (
    select date_sk, full_date from {{ ref('dim_date') }}
),

primary_diagnosis as (
    select
        fd.encounter_sk,
        dd.diagnosis_code,
        dd.description as diagnosis_description
    from {{ ref('fact_diagnosis') }} fd
    join {{ ref('dim_diagnosis') }} dd on fd.diagnosis_sk = dd.diagnosis_sk
    where fd.diagnosis_rank = 1
)

select
    e.encounter_id,
    p.patient_id,
    p.full_name                 as patient_name,
    p.dob,
    p.gender,
    pr.full_name                as provider_name,
    pr.specialty,
    f.facility_name,
    f.city,
    f.state,
    d.full_date                 as encounter_date,
    e.encounter_type,
    e.length_of_stay,
    pd.diagnosis_code,
    pd.diagnosis_description
from encounters e
left join patients    p  on e.patient_sk           = p.patient_sk
left join providers   pr on e.provider_sk          = pr.provider_sk
left join facilities  f  on e.facility_sk          = f.facility_sk
left join enc_date    d  on e.encounter_date_sk    = d.date_sk
left join primary_diagnosis pd on e.encounter_sk   = pd.encounter_sk
