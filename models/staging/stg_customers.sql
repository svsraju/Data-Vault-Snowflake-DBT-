SELECT
    customer_id,
    initcap(customer_name) AS customer_name,
    lower(email)           AS email,
    registration_date
FROM {{ source('raw', 'raw_customers') }}
