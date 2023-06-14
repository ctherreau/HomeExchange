{{ config(materialized='table')}}
WITH clean_exchanges AS (SELECT * FROM {{ ref('stg_exchanges') }} )
SELECT * 
FROM clean_exchanges