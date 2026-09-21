with enc as (
    select * from {{ ref('stg_encounters') }}
),

dim_pat  as (select patient_sk,  patient_id  from {{ ref('dim_patient') }}),
dim_prov as (select provider_sk, provider_id from {{ ref('dim_provider') }}),
dim_fac  as (select facility_sk, facility_id from {{ ref('dim_facility') }}),
dim_d    as (select date_sk,     full_date   from {{ ref('dim_date') }})

select
    {{ dbt_utils.generate_surrogate_key(['enc.encounter_id']) }}  as encounter_sk,
    enc.encounter_id,
    dp.patient_sk,
    dpr.provider_sk,
    df.facility_sk,
    dd_adm.date_sk                                                as encounter_date_sk,
    dd_dis.date_sk                                                as discharge_date_sk,
    enc.visit_type                                                as encounter_type,
    datediff('day',
        enc.admission_date::date,
        enc.discharge_date::date)                                 as length_of_stay
from enc
left join dim_pat  dp  on enc.patient_id   = dp.patient_id
left join dim_prov dpr on enc.doctor_id    = dpr.provider_id
left join dim_fac  df  on enc.facility_id  = df.facility_id
left join dim_d    dd_adm on enc.admission_date::date  = dd_adm.full_date
left join dim_d    dd_dis on enc.discharge_date::date  = dd_dis.full_date
