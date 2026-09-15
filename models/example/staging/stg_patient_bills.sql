with source as (
    select * from {{ source('health_raw', 'patient_bills') }}
),

cleaned as (
    select
        claim_id,
        encounter_id,
        billed_amount,
        allowed_amount,
        paid_amount,
        insurer,
        claim_status,
        claim_date,
    from source
)

select * from cleaned