{{ config(materialized="table") }}

select *
from {{ source("raw", "yellow_tripdata") }}
where rand() <= 0.01
