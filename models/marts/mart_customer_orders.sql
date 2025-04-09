{{ config(
    materialized='table'
) }}

SELECT
    customer_hk,
    customer_name,
    email,
    total_orders,
    total_quantity,
    first_order_date,
    last_order_date
FROM {{ ref('bv_customer_order_summary') }}


-- Explanation:

-- This is a straightforward “presentation” model.

-- The data is typically clean, aggregated, and ready for consumption.