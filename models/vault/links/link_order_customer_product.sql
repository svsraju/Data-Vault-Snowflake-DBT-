{{ config(materialized='incremental') }}

WITH lnk AS (
    SELECT
        {{ dv_generate_hash_key([
              'CAST(order_id    AS STRING)',
              'CAST(customer_id AS STRING)',
              'CAST(product_id  AS STRING)'
        ]) }} AS order_customer_product_hk,

        {{ dv_generate_hash_key(['CAST(order_id    AS STRING)']) }} AS order_hk,
        {{ dv_generate_hash_key(['CAST(customer_id AS STRING)']) }} AS customer_hk,
        {{ dv_generate_hash_key(['CAST(product_id  AS STRING)']) }} AS product_hk,

        current_timestamp() AS load_dt,
        'OMS' AS record_source
    FROM {{ ref('stg_orders') }}
)

SELECT * FROM lnk
{% if is_incremental() %}
WHERE order_customer_product_hk NOT IN (
    SELECT order_customer_product_hk FROM {{ this }}
)
{% endif %}
