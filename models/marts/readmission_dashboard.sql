with encounters as (
    select * from {{ ref('fact_encounter') }}
),

patients as (
    select * from {{ ref('dim_patient') }}
),

dim_d as (
    select date_sk, full_date from {{ ref('dim_date') }}
),

-- attach real dates to each encounter
encounter_dates as (
    select
        e.encounter_sk,
        e.encounter_id,
        e.patient_sk,
        e.encounter_type,
        e.length_of_stay,
        d_adm.full_date as encounter_date,
        d_dis.full_date as discharge_date
    from encounters e
    left join dim_d d_adm on e.encounter_date_sk  = d_adm.date_sk
    left join dim_d d_dis on e.discharge_date_sk  = d_dis.date_sk
),

-- self-join to find next admission within 30 days of discharge
readmissions as (
    select
        a.encounter_sk,
        a.patient_sk,
        a.encounter_date,
        a.discharge_date,
        a.length_of_stay,
        b.encounter_date                                          as readmit_date,
        datediff('day', a.discharge_date, b.encounter_date)      as days_to_readmit
    from encounter_dates a
    join encounter_dates b
        on  a.patient_sk      = b.patient_sk
        and b.encounter_date  > a.discharge_date
        and datediff('day', a.discharge_date, b.encounter_date) <= 30
)

select
    p.patient_id,
    p.full_name,
    p.gender,
    p.dob,
    r.encounter_date,
    r.discharge_date,
    r.length_of_stay,
    r.readmit_date,
    r.days_to_readmit,
    true as is_30day_readmit
from readmissions r
left join patients p on r.patient_sk = p.patient_sk
