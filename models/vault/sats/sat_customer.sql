{{ config(materialized='incremental') }}

WITH sat AS (
    SELECT
        {{ dv_generate_hash_key(['CAST(customer_id AS STRING)']) }} AS customer_hk,
        customer_name,
        email,
        registration_date,
        current_timestamp() AS load_dt,
        'OMS' AS record_source
    FROM {{ ref('stg_customers') }}
)

SELECT * FROM sat
{% if is_incremental() %}
WHERE customer_hk NOT IN (SELECT customer_hk FROM {{ this }})
{% endif %}
