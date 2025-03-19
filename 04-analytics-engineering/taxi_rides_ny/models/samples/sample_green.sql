{{ config(materialized="table") }}

select *
from {{ source("raw", "green_tripdata") }}
where rand() <= 0.05
