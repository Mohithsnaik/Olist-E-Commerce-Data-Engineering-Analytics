/*
# Olist E-Commerce Data Engineering & Analytics — SQL

## SQL Project Overview

This SQL script performs the database design, data validation, transformation, and
analytics-layer preparation for the Olist E-Commerce dataset in SQL Server.

### What is DONE in this SQL script:

- Connected to the `Olist_DB` database and validated the loaded staging tables.
- Added **Primary Keys** to the main staging tables.
- Created **Composite Primary Key** for `stg_order_items`.
- Added **Foreign Key constraints** to establish relationships between:
  - Customers and Orders
  - Orders and Order Items
  - Products and Order Items
  - Sellers and Order Items
  - Customers/Sellers and Geolocation
  - Orders and the Date Dimension
- Identified missing/orphan ZIP codes in the Customers and Sellers datasets.
- Inserted missing ZIP codes into the Geolocation table to maintain referential integrity.
- Created and populated a **Date Dimension (`dim_date`)** covering 2016–2018 using a Recursive CTE.
- Linked the Orders table with the Date Dimension.
- Created analytical **Dimension Views** for:
  - Products
  - Customers
  - Sellers
  - Geolocation
- Created analytical **Fact Views** for:
  - Orders
  - Order Items
  - Payments
  - Reviews
- Performed data type conversions and standardized column names within the analytical views.
- Joined product data with the translation table to provide **English product category names**.
- Performed final row-count validation for the staging tables and analytical views.

### Database Architecture

The SQL layer follows a **staging → dimensional/fact view** approach, preparing
the Olist data for analytical queries and BI reporting.

### Tools & Technologies

SQL Server | CTEs | Primary Keys | Foreign Keys | Views

### SQL Pipeline

Raw/Staging Tables
→ Data Validation
→ Primary & Foreign Keys
→ Referential Integrity
→ Date Dimension
→ Dimension & Fact Views
*/



CREATE DATABASE Olist_DB
USE Olist_DB
USE Olist_DB;
SELECT 'stg_customers' AS tbl, COUNT(*) AS n FROM stg_customers UNION ALL
SELECT 'stg_orders', COUNT(*) FROM stg_orders UNION ALL
SELECT 'stg_order_items', COUNT(*) FROM stg_order_items UNION ALL
SELECT 'stg_payments', COUNT(*) FROM stg_payments UNION ALL
SELECT 'stg_products', COUNT(*) FROM stg_products UNION ALL
SELECT 'stg_translations', COUNT(*) FROM stg_translations UNION ALL
SELECT 'stg_reviews', COUNT(*) FROM stg_reviews UNION ALL
SELECT 'stg_sellers', COUNT(*) FROM stg_sellers UNION ALL
SELECT 'stg_geolocation', COUNT(*) FROM stg_geolocation;



-- STEP 1: PRIMARY KEYS (DIMENSION TABLES)
ALTER TABLE stg_customers ALTER COLUMN customer_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_customers ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);

ALTER TABLE stg_products ALTER COLUMN product_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_products ADD CONSTRAINT PK_products PRIMARY KEY (product_id);

ALTER TABLE stg_sellers ALTER COLUMN seller_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_sellers ADD CONSTRAINT PK_sellers PRIMARY KEY (seller_id);

ALTER TABLE stg_geolocation ALTER COLUMN zip_code_prefix INT NOT NULL;
GO
ALTER TABLE stg_geolocation ADD CONSTRAINT PK_geolocation PRIMARY KEY (zip_code_prefix);
GO

-- STEP 2: PRIMARY KEYS FOR ORDERS & ORDER ITEMS
ALTER TABLE stg_orders ALTER COLUMN order_id VARCHAR(50) NOT NULL;
GO
ALTER TABLE stg_orders ADD CONSTRAINT PK_orders PRIMARY KEY (order_id);
GO

ALTER TABLE stg_order_items ALTER COLUMN order_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_order_items ALTER COLUMN order_item_id INT NOT NULL;
GO
ALTER TABLE stg_order_items ADD CONSTRAINT PK_order_items PRIMARY KEY (order_id, order_item_id);
GO




USE Olist_DB;

-- 1. Link stg_orders to stg_customers
ALTER TABLE stg_orders ALTER COLUMN customer_id VARCHAR(50) NOT NULL;
GO
ALTER TABLE stg_orders ADD CONSTRAINT FK_orders_customers 
FOREIGN KEY (customer_id) REFERENCES stg_customers(customer_id);
GO

-- 2. Link stg_order_items to stg_orders (Many-to-One)
ALTER TABLE stg_order_items ADD CONSTRAINT FK_items_orders 
FOREIGN KEY (order_id) REFERENCES stg_orders(order_id);
GO

-- 3. Link stg_order_items to stg_products
ALTER TABLE stg_order_items ALTER COLUMN product_id VARCHAR(50) NOT NULL;
GO
ALTER TABLE stg_order_items ADD CONSTRAINT FK_items_products 
FOREIGN KEY (product_id) REFERENCES stg_products(product_id);
GO

-- 4. Link stg_order_items to stg_sellers
ALTER TABLE stg_order_items ALTER COLUMN seller_id VARCHAR(50) NOT NULL;
GO
ALTER TABLE stg_order_items ADD CONSTRAINT FK_items_sellers 
FOREIGN KEY (seller_id) REFERENCES stg_sellers(seller_id);
GO




SELECT COUNT(DISTINCT customer_zip_code_prefix) AS orphan_customer_zips
FROM stg_customers
WHERE customer_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM stg_geolocation);

SELECT COUNT(DISTINCT seller_zip_code_prefix) AS orphan_seller_zips
FROM stg_sellers
WHERE seller_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM stg_geolocation);





-- 1. Insert missing ZIP codes from Customers into Geolocation table
INSERT INTO stg_geolocation (zip_code_prefix, lat, lng, city, state)
SELECT DISTINCT customer_zip_code_prefix, 0, 0, 'Unknown', 'Unknown'
FROM stg_customers
WHERE customer_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM stg_geolocation);
GO

-- 2. Insert missing ZIP codes from Sellers into Geolocation table
INSERT INTO stg_geolocation (zip_code_prefix, lat, lng, city, state)
SELECT DISTINCT seller_zip_code_prefix, 0, 0, 'Unknown', 'Unknown'
FROM stg_sellers
WHERE seller_zip_code_prefix NOT IN (SELECT zip_code_prefix FROM stg_geolocation);
GO




ALTER TABLE stg_customers ALTER COLUMN customer_zip_code_prefix INT NOT NULL;
GO
ALTER TABLE stg_customers ADD CONSTRAINT FK_customers_geolocation 
FOREIGN KEY (customer_zip_code_prefix) REFERENCES stg_geolocation(zip_code_prefix);
GO

ALTER TABLE stg_sellers ALTER COLUMN seller_zip_code_prefix INT NOT NULL;
GO
ALTER TABLE stg_sellers ADD CONSTRAINT FK_sellers_geolocation 
FOREIGN KEY (seller_zip_code_prefix) REFERENCES stg_geolocation(zip_code_prefix);
GO




SELECT COUNT(*) AS geo_rows FROM stg_geolocation;   -- 19015 + orphans inserted





-- 1. Create the dim_date table structure
CREATE TABLE dim_date (
    date_key DATE PRIMARY KEY,
    calendar_year INT,
    calendar_quarter INT,
    calendar_month INT,
    month_name VARCHAR(15),
    calendar_day INT,
    day_name VARCHAR(15),
    is_weekend BIT
);
GO

-- 2. Populate the table using a Recursive CTE (covers 2016 to 2018, the Olist data range)
DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate DATE = '2018-12-31';

WITH DateSequence AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < @EndDate
)
INSERT INTO dim_date (date_key, calendar_year, calendar_quarter, calendar_month, month_name, calendar_day, day_name, is_weekend)
SELECT 
    DateValue AS date_key,
    YEAR(DateValue) AS calendar_year,
    DATEPART(QUARTER, DateValue) AS calendar_quarter,
    MONTH(DateValue) AS calendar_month,
    DATENAME(MONTH, DateValue) AS month_name,
    DAY(DateValue) AS calendar_day,
    DATENAME(WEEKDAY, DateValue) AS day_name,
    CASE WHEN DATENAME(WEEKDAY, DateValue) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END AS is_weekend
FROM DateSequence
OPTION (MAXRECURSION 0);
GO



SELECT COUNT(*) AS date_rows, MIN(date_key) AS first_day, MAX(date_key) AS last_day FROM dim_date;




-- 1. Change order_purchase_timestamp data type to DATE to match dim_date(date_key)
ALTER TABLE stg_orders ALTER COLUMN order_purchase_timestamp DATE NOT NULL;
GO

-- 2. Add the Foreign Key constraint to link Orders to dim_date
ALTER TABLE stg_orders ADD CONSTRAINT FK_orders_date 
FOREIGN KEY (order_purchase_timestamp) REFERENCES dim_date(date_key);
GO




USE Olist_DB;
GO

-- 1. Clean View for Products (with English category names)
CREATE VIEW v_dim_products AS
SELECT 
    p.product_id,
    ISNULL(t.product_category_name_english, p.product_category_name) AS product_category,
    CAST(p.product_name_lenght AS INT) AS product_name_length,
    CAST(p.product_description_lenght AS INT) AS product_description_length,
    CAST(p.product_photos_qty AS INT) AS product_photos_count,
    CAST(p.product_weight_g AS FLOAT) AS product_weight_g,
    CAST(p.product_length_cm AS FLOAT) AS product_length_cm,
    CAST(p.product_height_cm AS FLOAT) AS product_height_cm,
    CAST(p.product_width_cm AS FLOAT) AS product_width_cm
FROM stg_products p
LEFT JOIN stg_translations t 
    ON p.product_category_name = t.product_category_name;
GO

-- 2. Clean View for Customers
CREATE VIEW v_dim_customers AS
SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix AS zip_code,
    customer_city AS city,
    customer_state AS state
FROM stg_customers;
GO

-- 3. Clean View for Sellers
CREATE VIEW v_dim_sellers AS
SELECT 
    seller_id,
    seller_zip_code_prefix AS zip_code,
    seller_city AS city,
    seller_state AS state
FROM stg_sellers;
GO

-- 4. Clean View for Geolocation
CREATE VIEW v_dim_geolocation AS
SELECT 
    zip_code_prefix AS zip_code,
    lat,
    lng,
    city,
    state
FROM stg_geolocation;
GO

-- 5. Clean View for Orders (Fact Table 1)
CREATE VIEW v_fact_orders AS
SELECT 
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp AS purchase_date,
    CAST(order_approved_at AS DATETIME) AS approved_at,
    CAST(order_delivered_carrier_date AS DATETIME) AS delivered_to_carrier_at,
    CAST(order_delivered_customer_date AS DATETIME) AS delivered_to_customer_at,
    CAST(order_estimated_delivery_date AS DATETIME) AS estimated_delivery_at
FROM stg_orders;
GO

-- 6. Clean View for Order Items (Fact Table 2)
CREATE VIEW v_fact_order_items AS
SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    CAST(shipping_limit_date AS DATETIME) AS shipping_limit_date,
    CAST(price AS FLOAT) AS price,
    CAST(freight_value AS FLOAT) AS freight_value
FROM stg_order_items;
GO

-- 7. Clean View for Payments
CREATE VIEW v_fact_payments AS
SELECT 
    order_id,
    payment_sequential,
    payment_type,
    CAST(payment_installments AS INT) AS installments,
    CAST(payment_value AS FLOAT) AS payment_value
FROM stg_payments;
GO

-- 8. Clean View for Reviews
CREATE VIEW v_fact_reviews AS
SELECT 
    review_id,
    order_id,
    CAST(review_score AS INT) AS review_score,
    review_comment_title AS comment_title,
    review_comment_message AS comment_message,
    CAST(review_creation_date AS DATETIME) AS created_at,
    CAST(review_answer_timestamp AS DATETIME) AS answered_at
FROM stg_reviews;
GO




SELECT 'v_dim_products' AS view_name, COUNT(*) AS n FROM v_dim_products UNION ALL
SELECT 'v_dim_customers', COUNT(*) FROM v_dim_customers UNION ALL
SELECT 'v_dim_sellers', COUNT(*) FROM v_dim_sellers UNION ALL
SELECT 'v_dim_geolocation', COUNT(*) FROM v_dim_geolocation UNION ALL
SELECT 'v_fact_orders', COUNT(*) FROM v_fact_orders UNION ALL
SELECT 'v_fact_order_items', COUNT(*) FROM v_fact_order_items UNION ALL
SELECT 'v_fact_payments', COUNT(*) FROM v_fact_payments UNION ALL
SELECT 'v_fact_reviews', COUNT(*) FROM v_fact_reviews;