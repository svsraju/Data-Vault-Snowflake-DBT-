SELECT
  customer_id,
  INITCAP(customer_name) AS customer_name,
  LOWER(email) AS email,
  registration_date
FROM {{ source('raw', 'raw_customers') }}
