{{ config(materialized='incremental') }}

WITH src AS (
    SELECT
        {{ dv_generate_hash_key(['CAST(customer_id AS STRING)']) }} AS customer_hk,
        customer_id  AS customer_bk,
        current_timestamp() AS load_dt,
        'OMS' AS record_source
    FROM {{ ref('stg_customers') }}
)

SELECT * FROM src
{% if is_incremental() %}
WHERE customer_hk NOT IN (SELECT customer_hk FROM {{ this }})
{% endif %}
