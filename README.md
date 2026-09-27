# 🇧🇷 Olist E-Commerce Data Engineering & Analytics Project

End-to-end Data Engineering and Analytics project built using **Python, SQL Server, and Power BI** to clean, transform, model, and analyze over 100k Brazilian e-commerce orders.

> **Project Status:** Data Engineering and SQL layers completed. **Power BI reporting and dashboard development are currently in progress.**

---

## 📌 Project Overview

This project uses the Brazilian Olist E-Commerce dataset to build an end-to-end data pipeline starting from raw CSV files and progressing through data cleaning, transformation, optimization, SQL Server ingestion, relational modeling, and analytical views.

The project focuses primarily on building a reliable data preparation and database layer that can later be consumed by Power BI for business intelligence and reporting.

### Pipeline

**Raw CSV Files → Data Quality Checks → Data Cleaning → Data Transformation → Geolocation Optimization → SQL Server Staging → Relational Modeling → Analytical Views → Power BI**

---

## 🛠️ Tech Stack

* **Programming & Data Processing:** Python, Pandas
* **Database Connectivity:** PyODBC, SQLAlchemy
* **Database:** Microsoft SQL Server
* **Database Management:** SQL Server Management Studio (SSMS)
* **Data Modeling:** Primary Keys, Foreign Keys, Fact & Dimension Views
* **Analytics & Visualization:** Power BI *(Currently in Progress)*

---

# 🏗️ Project Architecture & Workflow

## Phase 1: Data Cleaning & Transformation — Python

The first stage of the project was implemented using Python and Pandas.

The Olist dataset contains multiple relational CSV files covering customers, orders, products, sellers, payments, reviews, order items, geolocation, and product-category translations.

### Datasets Used

The project processes the following datasets:

* Customers
* Orders
* Order Items
* Payments
* Products
* Product Category Translations
* Reviews
* Sellers
* Geolocation

The initial data inspection included:

* Dataset shape and row-count validation
* Duplicate record checks
* Missing-value analysis
* Data type inspection
* Datetime conversion
* Numeric datatype conversion
* Geolocation optimization

---

## 1. Data Quality Checks

Each dataset was loaded into Pandas and organized into a dictionary so that common validation operations could be performed systematically.

### Duplicate Check

Duplicate rows were checked across the datasets before further processing.

The project verified that the loaded datasets did not contain duplicate records requiring removal.

### Missing-Value Analysis

Missing values were analyzed independently for each dataset to understand where data cleaning was required.

The major missing-value cases were found in:

* Products
* Reviews
* Orders

---

## 2. Products Data Cleaning

The Products dataset contained missing values in product category information and physical/product-description attributes.

### Handling Missing Product Categories

Missing values in:

`product_category_name`

were replaced with:

`unknown`

This preserves the product records instead of removing them from the dataset.

### Handling Missing Product Attributes

Missing values in numerical product attributes were replaced with `0`.

The affected columns include:

* `product_name_lenght`
* `product_description_lenght`
* `product_photos_qty`
* `product_weight_g`
* `product_length_cm`
* `product_height_cm`
* `product_width_cm`

This allows the complete product dataset to be retained while providing consistent values for downstream processing.

---

## 3. Reviews Data Cleaning

The Reviews dataset contains a large number of missing textual comments.

Instead of removing these records, missing text values were replaced with standardized placeholders.

### Missing Review Titles

Replaced with:

`No Title`

### Missing Review Messages

Replaced with:

`No Message`

This preserves the review records and provides consistent text values for downstream analysis.

---

## 4. Datetime Transformation

Several columns were originally loaded as object/string values.

Relevant datetime columns were converted using Pandas `to_datetime()` with error handling.

### Orders

Converted:

* `order_purchase_timestamp`
* `order_approved_at`
* `order_delivered_carrier_date`
* `order_delivered_customer_date`
* `order_estimated_delivery_date`

### Reviews

Converted:

* `review_creation_date`
* `review_answer_timestamp`

### Order Items

Converted:

* `shipping_limit_date`

These transformations ensure that date-based operations can be performed correctly in SQL Server and later in Power BI.

---

## 5. Product Datatype Transformation

Product attributes such as:

* `product_name_lenght`
* `product_description_lenght`
* `product_photos_qty`

were converted from floating-point values to integer datatype after missing values were handled.

This ensures that these count-based attributes use an appropriate datatype before being loaded into SQL Server.

---

# 🌎 6. Geolocation Dataset Optimization

One of the major data-engineering tasks in the project was handling the large Olist geolocation dataset.

The original geolocation dataset contains:

**1,000,163 rows**

Many rows represent the same ZIP-code prefix with slightly different geographic coordinates.

Loading the complete dataset into SQL Server would introduce significant redundancy.

### Problem

The raw geolocation dataset contains repeated:

`geolocation_zip_code_prefix`

values along with multiple latitude and longitude records.

Instead of loading every raw coordinate record, the dataset was compressed by ZIP-code prefix.

### Engineering Solution

The geolocation dataset was grouped by:

`geolocation_zip_code_prefix`

The following transformations were applied:

* Average latitude calculated for each ZIP-code prefix
* Average longitude calculated for each ZIP-code prefix
* First associated city retained
* First associated state retained
* Columns renamed to standardized names

The resulting columns are:

* `zip_code_prefix`
* `lat`
* `lng`
* `city`
* `state`

### Compression Result

| Metric | Value |
|---|---:|
| Original Rows | 1,000,163 |
| Compressed Rows | 19,015 |
| Approximate Reduction | ~98% |

This significantly reduces the amount of spatial data that needs to be stored and processed downstream.

---

# 🔌 Phase 2: Python → SQL Server Data Pipeline

After cleaning and transformation, the processed Pandas DataFrames were prepared for SQL Server ingestion.

## SQL Server Connection

The project uses:

* **PyODBC**
* **SQLAlchemy**
* **ODBC Driver 17 for SQL Server**

A SQLAlchemy engine was created to establish the connection between Python and the `Olist_DB` SQL Server database.

---

## Bulk Data Loading

The cleaned datasets were consolidated into a Python dictionary and uploaded to SQL Server using Pandas `to_sql()`.

The staging tables created include:

* `stg_customers`
* `stg_orders`
* `stg_order_items`
* `stg_payments`
* `stg_products`
* `stg_translations`
* `stg_reviews`
* `stg_sellers`
* `stg_geolocation`

The upload process uses chunking with a chunk size of **5,000 rows** to make the bulk-loading process more manageable.

### Final Dataset Sizes

| Dataset | Rows |
|---|---:|
| Customers | 99,441 |
| Orders | 99,441 |
| Order Items | 112,650 |
| Payments | 103,886 |
| Products | 32,951 |
| Translations | 71 |
| Reviews | 99,224 |
| Sellers | 3,095 |
| Geolocation | 19,015 |

All nine processed datasets were successfully loaded into the SQL Server database.

---

# 🗄️ Phase 3: SQL Server Database Modeling

After the data was loaded into SQL Server, T-SQL was used to build the relational database layer.

The SQL layer performs:

* Data validation
* Primary key creation
* Composite primary key creation
* Foreign key relationships
* Referential integrity checks
* Orphan ZIP-code handling
* Date dimension creation
* Analytical view creation
* Data type standardization
* Final row-count validation

---

# 🔑 1. Primary Keys

Primary keys were added to the main staging tables.

Examples include:

* `stg_customers → customer_id`
* `stg_products → product_id`
* `stg_sellers → seller_id`
* `stg_orders → order_id`
* `stg_geolocation → zip_code_prefix`

### Composite Primary Key

The `stg_order_items` table uses a composite primary key:

```text
(order_id, order_item_id)
```

This reflects the line-item level of the order data.

---

# 🔗 2. Foreign Key Relationships

Foreign key constraints were created to establish relational integrity between the staging tables.

Major relationships include:

```text
Customers
    ↓
Orders
    ↓
Order Items
    ↓
Products
    ↓
Sellers
```

Additional relationships connect customers and sellers to the geolocation table.

These constraints help ensure that the relational structure of the Olist dataset is maintained inside SQL Server.

---

# 📍 3. Orphan ZIP-Code Handling

During the relational modeling process, ZIP codes were checked across the customer/seller tables and the geolocation table.

Some ZIP codes existed in customer or seller records but were not present in the compressed geolocation dataset.

Instead of removing those customer or seller records, missing ZIP codes were inserted into `stg_geolocation` using placeholder values:

```text
Latitude  → 0
Longitude → 0
City      → Unknown
State     → Unknown
```

This allows the foreign-key relationships to be established without losing the corresponding customer or seller records.

---

# 📅 4. Date Dimension

A dedicated `dim_date` table was created for time-based analysis.

The date dimension covers:

**2016-01-01 → 2018-12-31**

The table contains:

* `date_key`
* `calendar_year`
* `calendar_quarter`
* `calendar_month`
* `month_name`
* `calendar_day`
* `day_name`
* `is_weekend`

A recursive CTE was used to generate the complete date sequence.

This prepares the database for time-based reporting and future Power BI time-intelligence analysis.

---

# 👁️ 5. Analytical Dimension & Fact Views

Instead of directly exposing the raw staging tables to the reporting layer, analytical SQL views were created.

## Dimension Views

### `v_dim_products`

Provides cleaned product information and joins the product category translation table to expose English product category names.

### `v_dim_customers`

Provides customer identifiers and geographical attributes.

### `v_dim_sellers`

Provides seller identifiers and geographical attributes.

### `v_dim_geolocation`

Provides the compressed ZIP-code-level geographic information.

---

## Fact Views

### `v_fact_orders`

Contains order-level transactional and fulfillment information.

### `v_fact_order_items`

Contains product-level order information including:

* Product
* Seller
* Price
* Freight value
* Shipping limit date

### `v_fact_payments`

Contains:

* Payment type
* Installments
* Payment value

### `v_fact_reviews`

Contains:

* Review score
* Review comments
* Review creation timestamp
* Review answer timestamp

---

# ⭐ Data Model Architecture

The SQL layer follows a **staging → analytical views** architecture.

### Staging Layer

```text
stg_customers
stg_orders
stg_order_items
stg_payments
stg_products
stg_translations
stg_reviews
stg_sellers
stg_geolocation
```

### Analytical Layer

```text
                    ┌─────────────────┐
                    │  v_dim_customers │
                    └────────┬────────┘
                             │
                             ▼
                       v_fact_orders
                             │
                    ┌────────┴─────────┐
                    ▼                  ▼
          v_fact_order_items    v_fact_payments
             │          │
             ▼          ▼
       v_dim_products  v_dim_sellers

              v_fact_reviews
                    │
                    ▼
                dim_date

          v_dim_geolocation
```

The analytical views provide a structured layer for downstream reporting and Power BI development.

---

# 🧩 SQL Engineering Challenges & Solutions

## 1. Geolocation Primary Key Metadata Issue

### Problem

SQL Server requires a primary-key column to be non-nullable.

The compressed geolocation table initially had the ZIP-code column configured as nullable.

### Solution

The column was explicitly changed to:

```sql
INT NOT NULL
```

before applying the primary key constraint.

`GO` batch separators were used to ensure the structural changes were committed before adding the constraint.

---

## 2. Referential Integrity and Missing ZIP Codes

### Problem

Customer and seller ZIP codes were found that did not exist in the compressed geolocation table.

This prevented foreign-key constraints from being established.

### Solution

The missing ZIP codes were identified using SQL queries and inserted into the geolocation table with placeholder geographic values.

This allowed the relationships to be created while retaining the original customer and seller records.

---

## 3. Cross-Table Datatype Alignment

Relational key columns uploaded from Python did not always have matching SQL Server datatypes.

For example, ZIP-code columns required alignment between customer/seller tables and the geolocation table.

Targeted `ALTER COLUMN` statements were used to standardize these datatypes before creating the relationships.

---

# 📊 Phase 4: Power BI Reporting — Currently In Progress

The Power BI layer is **currently being developed**.

The SQL Server analytical views created in the previous phase will serve as the primary data source for the Power BI reporting layer.

The planned reporting layer will focus on areas such as:

### Sales & Marketplace Analysis

* Sales performance
* Order volume
* Product categories
* Customer distribution
* Seller distribution

### Logistics & Delivery Analysis

* Delivery timelines
* Shipping performance
* Freight costs
* Order fulfillment
* Delivery status

### Customer & Review Analysis

* Review scores
* Customer satisfaction
* Order and review trends

> **Note:** Power BI dashboards, DAX measures, report pages, and final visualizations are currently under development and are not yet included as completed parts of this repository.

---

# 🚧 Project Status

| Component | Status |
|---|---|
| Dataset Loading | ✅ Completed |
| Data Quality Checks | ✅ Completed |
| Missing Value Handling | ✅ Completed |
| Datetime Transformation | ✅ Completed |
| Product Datatype Transformation | ✅ Completed |
| Geolocation Optimization | ✅ Completed |
| Python → SQL Server Pipeline | ✅ Completed |
| SQL Staging Tables | ✅ Completed |
| Primary Keys | ✅ Completed |
| Foreign Keys | ✅ Completed |
| Referential Integrity Handling | ✅ Completed |
| Date Dimension | ✅ Completed |
| Analytical SQL Views | ✅ Completed |
| Power BI Data Modeling | 🚧 In Progress |
| DAX Measures | 🚧 In Progress |
| Power BI Dashboards | 🚧 In Progress |

---

# 📁 Project Structure

```text
Olist-E-Commerce-Data-Engineering/
│
├── Dataset/
│   ├── olist_customers_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   └── product_category_name_translation.csv
│
├── notebooks/
│   └── Olist_EndtoEnd_Pipeline.ipynb
│
├── sql/
│   └── SQL_Warehouse_Modeling.sql
│
└── README.md
```

---

# 🔄 End-to-End Pipeline

The current implementation can be summarized as:

```text
                    RAW OLIST DATASETS
                           │
                           ▼
                    Python / Pandas
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       Data Quality Checks       Data Transformations
              │                         │
              │              ┌──────────┴──────────┐
              │              │                     │
              ▼              ▼                     ▼
       Duplicate Checks   Missing Values     Datatype Conversion
              │
              └──────────────┬──────────────┘
                             │
                             ▼
                  Geolocation Optimization
                             │
                  1,000,163 → 19,015 rows
                             │
                             ▼
                    SQLAlchemy / PyODBC
                             │
                             ▼
                       SQL Server
                             │
                             ▼
                    Staging Tables
                             │
                             ▼
                 PK / FK & Data Integrity
                             │
                             ▼
                      Date Dimension
                             │
                             ▼
                  Analytical SQL Views
                             │
                             ▼
                         Power BI
                    🚧 IN PROGRESS
```

---

# 🎯 Key Learning Outcomes

Through this project, the following practical concepts were implemented:

* Loading and inspecting relational datasets using Pandas
* Data quality validation
* Missing-value handling
* Duplicate detection
* Datetime conversion
* Datatype standardization
* Large dataset optimization
* GroupBy-based data aggregation
* Geolocation data compression
* Python-to-SQL Server connectivity
* SQLAlchemy database engines
* Bulk data loading with `to_sql()`
* SQL Server staging architecture
* Primary and composite keys
* Foreign key relationships
* Referential integrity
* Orphan-record handling
* Recursive CTEs
* Date dimension creation
* SQL analytical views
* Fact and dimension modeling
* Preparing a database layer for Power BI reporting

---

# 🚀 Future Development

The next stage of the project is focused on completing the Power BI layer.

Planned work includes:

* Connecting Power BI to the analytical SQL views
* Building the Power BI data model
* Creating DAX measures
* Developing KPI cards
* Creating sales and marketplace dashboards
* Developing logistics and delivery analysis
* Building customer/review analysis
* Adding interactive filters and drill-through functionality
* Finalizing dashboard design and documentation

---

# 📌 Conclusion

This project demonstrates an end-to-end approach to preparing an e-commerce dataset for analytics.

The implementation starts with raw Olist CSV files, performs data quality checks and transformations using Python, optimizes the large geolocation dataset, loads the processed data into SQL Server, establishes relational integrity, creates a date dimension, and exposes cleaned fact and dimension views for analytical consumption.

The **Power BI reporting layer is currently under development**, and will complete the final visualization and business intelligence stage of the project.
