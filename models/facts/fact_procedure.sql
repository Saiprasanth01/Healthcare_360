with proc as (
    select * from {{ ref('stg_procedures') }}
),

enc_sk as (
    select encounter_sk, encounter_id from {{ ref('fact_encounter') }}
),

dim_proc as (
    select procedure_sk, procedure_code from {{ ref('dim_procedure') }}
),

dim_d as (
    select date_sk, full_date from {{ ref('dim_date') }}
)

select
    e.encounter_sk,
    p.procedure_sk,
    d.date_sk   as procedure_date_sk,
    proc.procedure_date
from proc
left join enc_sk  e on proc.encounter_id   = e.encounter_id
left join dim_proc p on proc.procedure_code = p.procedure_code
left join dim_d    d on proc.procedure_date  = d.full_date
