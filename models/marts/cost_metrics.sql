with claims as (
    select * from {{ ref('fact_claim') }}
),

encounters as (
    select * from {{ ref('fact_encounter') }}
),

patients as (
    select patient_sk, gender from {{ ref('dim_patient') }}
),

facilities as (
    select facility_sk, facility_name, state from {{ ref('dim_facility') }}
),

dim_d as (
    select date_sk, year, month, month_name from {{ ref('dim_date') }}
)

select
    f.facility_name,
    f.state,
    d.year,
    d.month,
    d.month_name,
    p.gender,
    count(distinct c.claim_id)                                                      as total_claims,
    count(distinct e.encounter_id)                                                  as total_encounters,
    sum(c.billed_amount)                                                            as total_billed,
    sum(c.allowed_amount)                                                           as total_allowed,
    sum(c.paid_amount)                                                              as total_paid,
    avg(c.billed_amount)                                                            as avg_billed_per_claim,
    sum(c.billed_amount - c.paid_amount)                                            as total_outstanding,
    count(case when c.claim_status = 'DENIED' then 1 end)                          as denied_claims,
    round(
        count(case when c.claim_status = 'DENIED' then 1 end) * 100.0
        / nullif(count(*), 0), 2
    )                                                                               as denial_rate_pct
from claims c
left join encounters e  on c.encounter_sk  = e.encounter_sk
left join patients   p  on e.patient_sk    = p.patient_sk
left join facilities f  on e.facility_sk   = f.facility_sk
left join dim_d      d  on c.claim_date_sk = d.date_sk
group by 1, 2, 3, 4, 5, 6
