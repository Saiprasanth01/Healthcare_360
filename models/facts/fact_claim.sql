with bills as (
    select * from {{ ref('stg_patient_bills') }}
),

enc_sk as (
    select encounter_sk, encounter_id from {{ ref('fact_encounter') }}
),

dim_d as (
    select date_sk, full_date from {{ ref('dim_date') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['bills.claim_id']) }} as claim_sk,
    bills.claim_id,
    e.encounter_sk,
    bills.insurer,
    d.date_sk                                                  as claim_date_sk,
    bills.billed_amount,
    bills.allowed_amount,
    bills.paid_amount,
    bills.claim_status
from bills
left join enc_sk e on bills.encounter_id = e.encounter_id
left join dim_d  d on bills.claim_date   = d.full_date
