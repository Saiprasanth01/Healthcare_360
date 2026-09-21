with stg as (
    select distinct
        procedure_code,
        procedure_description
    from {{ ref('stg_procedures') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['procedure_code']) }} as procedure_sk,
    procedure_code,
    procedure_description                                       as description
from stg
