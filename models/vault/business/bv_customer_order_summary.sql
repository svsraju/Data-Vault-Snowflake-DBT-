-- models/vault/bv/bv_customer_orders_summary.sql
{{ config(materialized='table') }}

WITH joined_data AS (
    SELECT
        c.customer_hk,
        sc.customer_name,
        sc.email,
        so.quantity,
        so.order_date
    FROM {{ ref('hub_customer') }} c
    JOIN {{ ref('sat_customer') }} sc
        ON c.customer_hk = sc.customer_hk
    JOIN {{ ref('link_order_customer_product') }} l
        ON c.customer_hk = l.customer_hk
    JOIN {{ ref('sat_order') }} so
        ON l.order_hk = so.order_hk
)

SELECT
    customer_hk,
    customer_name,
    email,
    COUNT(*) AS total_orders,
    SUM(quantity) AS total_quantity,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM joined_data
GROUP BY
    1,2,3
