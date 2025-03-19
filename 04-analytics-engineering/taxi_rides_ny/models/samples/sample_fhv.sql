{{ config(materialized="table") }}

select *
from {{ source("raw", "fhv_tripdata") }}
where rand() <= 0.01
