{{ config(materialized='incremental') }}

WITH sat AS (
    SELECT
        {{ dv_generate_hash_key(['CAST(product_id AS STRING)']) }} AS product_hk,
        product_name,
        product_category,
        price,
        current_timestamp() AS load_dt,
        'OMS' AS record_source
    FROM {{ ref('stg_products') }}
)

SELECT * FROM sat
{% if is_incremental() %}
WHERE product_hk NOT IN (SELECT product_hk FROM {{ this }})
{% endif %}
