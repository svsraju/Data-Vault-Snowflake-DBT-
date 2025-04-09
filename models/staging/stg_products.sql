SELECT
    product_id,
    initcap(product_name) AS product_name,
    CATEGORY AS product_category,
    cast(price AS decimal(10,2)) AS price
FROM {{ source('raw', 'raw_products') }}
