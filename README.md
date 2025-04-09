# 🏛️ OMS Data Vault Project (dbt + Snowflake)

This repository implements a full Data Vault 2.0 model using dbt and Snowflake. Below is a breakdown of every component in the project with its purpose, use case, and relevant SQL logic.

---

## 📁 Project Structure

```
macros/
  └── dv_generate_hash_key.sql

models/
├── example/
├── marts/
│   └── mart_customer_orders.sql
├── staging/
│   ├── source.yml
│   ├── stg_customers.sql
│   ├── stg_orders.sql
│   └── stg_products.sql
├── vault/
│   ├── business/
│   │   └── bv_customer_order_summary.sql
│   ├── hubs/
│   │   ├── hub_customer.sql
│   │   ├── hub_order.sql
│   │   └── hub_product.sql
│   ├── links/
│   │   └── link_order_customer_product.sql
│   └── sats/
│       ├── sat_customer.sql
│       ├── sat_order.sql
│       └── sat_product.sql
```

---

## 🔧 `macros/dv_generate_hash_key.sql`

### ✅ Purpose:
Reusable macro for generating MD5 hash keys from business key columns.

Stable, deterministic 32‑byte surrogate keys; avoids natural‑key collisions and keeps joins narrow.

### 💡 Use Case:
Keeps key generation consistent across hubs, links, and satellites.

```jinja
{% macro dv_generate_hash_key(cols) %}
    md5(
        concat_ws(
            '|',
            {%- for c in cols -%}
                coalesce({{ c }}, '¬'){% if not loop.last %}, {% endif %}
            {%- endfor -%}
        )
    )
{% endmacro %}
```

---

## 🔹 Staging Layer (`models/staging/`)

### ✅ Purpose:
Clean and standardize raw data before loading it into the vault layer.

Minimal cleansing / type casting; no business logic — keeps vault loads deterministic.

#### `stg_customers.sql`
- Capitalizes names
- Normalizes email
```jinja
SELECT
  customer_id,
  INITCAP(customer_name) AS customer_name,
  LOWER(email) AS email,
  registration_date
FROM {{ source('raw', 'raw_customers') }}
```

#### `stg_orders.sql`
- Casts numeric fields and formats dates
```jinja
SELECT
  order_id,
  customer_id,
  product_id,
  order_date,
  quantity
FROM {{ source('raw', 'raw_orders') }}
```

#### `stg_products.sql`
```jinja
SELECT
  product_id,
  INITCAP(product_name) AS product_name,
  cast(price AS decimal(10,2)) AS price
FROM {{ source('raw', 'raw_products') }}
```

---

## 🧱 Hubs (`models/vault/hubs/`)

### ✅ Purpose:
Store immutable business keys.

A Hub row is immutable: once a business key appears, it never changes. The hash key becomes the anchor for all future Satellites and Links.

#### `hub_customer.sql`
```jinja
SELECT
  {{ dv_generate_hash_key(['CAST(customer_id AS STRING)']) }} AS customer_hk,
  customer_id AS customer_bk,
  current_timestamp() AS load_dt,
  'OMS' AS record_source
FROM {{ ref('stg_customers') }}
```

#### `hub_order.sql`
```jinja
SELECT
  {{ dv_generate_hash_key(['CAST(order_id AS STRING)']) }} AS order_hk,
  order_id AS order_bk,
  current_timestamp() AS load_dt,
  'OMS' AS record_source
FROM {{ ref('stg_orders') }}
```

#### `hub_product.sql`
```jinja
SELECT
  {{ dv_generate_hash_key(['CAST(product_id AS STRING)']) }} AS product_hk,
  product_id AS product_bk,
  current_timestamp() AS load_dt,
  'OMS' AS record_source
FROM {{ ref('stg_products') }}
```

---

## 🔗 Links (`models/vault/links/`)

### ✅ Purpose:
Track many-to-many relationships between hubs.
Links decouple relationships from descriptive data. You can add new Satellites to either hub without altering the link table.

#### `link_order_customer_product.sql`
```jinja
SELECT
  {{ dv_generate_hash_key(['CAST(order_id AS STRING)', 'CAST(customer_id AS STRING)', 'CAST(product_id AS STRING)']) }} AS order_customer_product_hk,
  {{ dv_generate_hash_key(['CAST(order_id AS STRING)']) }} AS order_hk,
  {{ dv_generate_hash_key(['CAST(customer_id AS STRING)']) }} AS customer_hk,
  {{ dv_generate_hash_key(['CAST(product_id AS STRING)']) }} AS product_hk,
  current_timestamp() AS load_dt,
  'OMS' AS record_source
FROM {{ ref('stg_orders') }}
```

---

## 🛰️ Satellites (`models/vault/sats/`)

### ✅ Purpose:
Track attributes and historical changes for Hubs/Links.

Satellites hold change‑tracked attributes. You can implement Type‑2 history by comparing a hashdiff and inserting new rows when any attribute changes.

#### `sat_customer.sql`
```jinja
SELECT
  {{ dv_generate_hash_key(['CAST(customer_id AS STRING)']) }} AS customer_hk,
  customer_name,
  email,
  registration_date,
  current_timestamp() AS load_dt,
  'OMS' AS record_source
FROM {{ ref('stg_customers') }}
```

#### `sat_order.sql`
```jinja
SELECT
  {{ dv_generate_hash_key(['CAST(order_id AS STRING)']) }} AS order_hk,
  order_date,
  quantity,
  total_amount,
  current_timestamp() AS load_dt,
  'OMS' AS record_source
FROM {{ ref('stg_orders') }}
```

#### `sat_product.sql`
```jinja
SELECT
  {{ dv_generate_hash_key(['CAST(product_id AS STRING)']) }} AS product_hk,
  product_name,
  product_category,
  price,
  current_timestamp() AS load_dt,
  'OMS' AS record_source
FROM {{ ref('stg_products') }}
```

---

## 📊 Business Vault (`models/vault/business/`)

### ✅ Purpose:
Create analytics-ready vault layer using PIT tables or aggregated satellites.

#### `bv_customer_order_summary.sql`
```jinja
SELECT
  o.order_id,
  c.customer_name,
  p.product_name,
  o.order_date,
  o.total_amount
FROM {{ ref('stg_orders') }} o
JOIN {{ ref('stg_customers') }} c USING (customer_id)
JOIN {{ ref('stg_products') }} p USING (product_id)
```

---

## 📈 Marts (`models/marts/`)

### ✅ Purpose:
Final star schema outputs for dashboards or downstream apps.

#### `mart_customer_orders.sql`
```jinja
SELECT *
FROM {{ ref('bv_customer_order_summary') }}
```

---

## ✅ Summary

| Layer        | Folder                     | Purpose                                       |
|--------------|----------------------------|-----------------------------------------------|
| Macros       | `macros/`                  | Shared logic for keys                         |
| Staging      | `models/staging/`          | Clean raw tables                              |
| Hubs         | `models/vault/hubs/`       | Immutable business keys                       |
| Links        | `models/vault/links/`      | Many-to-many hub relationships                |
| Satellites   | `models/vault/sats/`       | Descriptive and historical context            |
| BusinessVault| `models/vault/business/`   | Reporting layer using PITs/aggregates         |
| Marts        | `models/marts/`            | Final star schema for reporting               |

---

Let’s build something vault-y! 🚀