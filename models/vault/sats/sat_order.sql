{{ config(materialized='incremental') }}

WITH sat AS (
    SELECT
        {{ dv_generate_hash_key(['CAST(order_id AS STRING)']) }} AS order_hk,
        order_date,
        quantity,
        current_timestamp() AS load_dt,
        'OMS' AS record_source
    FROM {{ ref('stg_orders') }}
)

SELECT * FROM sat
{% if is_incremental() %}
WHERE order_hk NOT IN (SELECT order_hk FROM {{ this }})
{% endif %}
