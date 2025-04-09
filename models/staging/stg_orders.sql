SELECT
    order_id,
    customer_id,
    product_id,
    order_date,
    quantity
FROM {{ source('raw', 'raw_orders') }}
