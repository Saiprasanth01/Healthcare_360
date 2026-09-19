{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart = "day",
        start_date = "cast('2015-01-01' as date)",
        end_date   = "cast('2035-12-31' as date)"
    ) }}
)

select
    to_number(to_char(date_day, 'YYYYMMDD'))                        as date_sk,
    date_day                                                         as full_date,
    day(date_day)                                                    as day,
    month(date_day)                                                  as month,
    monthname(date_day)                                              as month_name,
    quarter(date_day)                                                as quarter,
    year(date_day)                                                   as year,
    dayofweekiso(date_day)                                           as day_of_week,
    dayname(date_day)                                                as day_name,
    iff(dayofweek(date_day) in (0, 6), true, false)                  as is_weekend
from date_spine
