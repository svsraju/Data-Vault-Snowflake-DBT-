{{ config(materialized='incremental') }}

WITH src AS (
    SELECT
        {{ dv_generate_hash_key(['CAST(product_id AS STRING)']) }} AS product_hk,
        product_id  AS product_bk,
        current_timestamp() AS load_dt,
        'OMS' AS record_source
    FROM {{ ref('stg_products') }}
)

SELECT * FROM src
{% if is_incremental() %}
WHERE product_hk NOT IN (SELECT product_hk FROM {{ this }})
{% endif %}
