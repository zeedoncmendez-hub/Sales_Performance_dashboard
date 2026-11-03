-- =============================================================
-- Sales Performance Dashboard | 01 - Create database and schema
-- Author : Ashik Dev A S
-- Target : MySQL 8.0+ (also tested on MariaDB 10.11)
-- Builds a staging table for the raw CSV and a star schema
-- (1 fact table + 4 dimension tables) for reporting in Power BI.
-- =============================================================

CREATE DATABASE IF NOT EXISTS superstore_db
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE superstore_db;

DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_location;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS stg_orders;

-- ---------- Staging: one row per order line, exactly as in the CSV ----------
CREATE TABLE stg_orders (
    row_id         INT            NOT NULL,
    order_id       VARCHAR(20)    NOT NULL,
    order_date     DATE           NOT NULL,
    ship_date      DATE           NOT NULL,
    ship_mode      VARCHAR(20),
    customer_id    VARCHAR(12)    NOT NULL,
    customer_name  VARCHAR(60),
    segment        VARCHAR(20),
    country        VARCHAR(30),
    city           VARCHAR(40),
    state          VARCHAR(30),
    postal_code    VARCHAR(10),
    region         VARCHAR(10),
    product_id     VARCHAR(20)    NOT NULL,
    category       VARCHAR(20),
    sub_category   VARCHAR(20),
    product_name   VARCHAR(200),
    sales          DECIMAL(12,4),
    quantity       INT,
    discount       DECIMAL(4,2),
    profit         DECIMAL(12,4),
    PRIMARY KEY (row_id)
);

-- ---------- Dimensions ----------
CREATE TABLE dim_date (
    date_key      INT          PRIMARY KEY,      -- yyyymmdd
    full_date     DATE         NOT NULL UNIQUE,
    year_num      SMALLINT     NOT NULL,
    quarter_num   TINYINT      NOT NULL,
    month_num     TINYINT      NOT NULL,
    month_name    VARCHAR(10)  NOT NULL,
    day_name      VARCHAR(10)  NOT NULL
);

CREATE TABLE dim_customer (
    customer_key   INT AUTO_INCREMENT PRIMARY KEY,
    customer_id    VARCHAR(12)  NOT NULL UNIQUE,
    customer_name  VARCHAR(60),
    segment        VARCHAR(20)
);

-- Product ID is NOT unique in the raw data (32 IDs map to 2 product names),
-- so the dimension uses a surrogate key on (product_id, product_name).
CREATE TABLE dim_product (
    product_key    INT AUTO_INCREMENT PRIMARY KEY,
    product_id     VARCHAR(20)  NOT NULL,
    product_name   VARCHAR(200) NOT NULL,
    category       VARCHAR(20),
    sub_category   VARCHAR(20),
    UNIQUE KEY uq_product (product_id, product_name)
);

CREATE TABLE dim_location (
    location_key   INT AUTO_INCREMENT PRIMARY KEY,
    country        VARCHAR(30),
    region         VARCHAR(10),
    state          VARCHAR(30),
    city           VARCHAR(40),
    postal_code    VARCHAR(10),
    UNIQUE KEY uq_location (state, city, postal_code)
);

-- ---------- Fact ----------
CREATE TABLE fact_sales (
    sales_line_id   INT PRIMARY KEY,               -- original Row ID
    order_id        VARCHAR(20)   NOT NULL,
    order_date_key  INT           NOT NULL,
    ship_date_key   INT           NOT NULL,
    ship_mode       VARCHAR(20),
    customer_key    INT           NOT NULL,
    product_key     INT           NOT NULL,
    location_key    INT           NOT NULL,
    sales           DECIMAL(12,4) NOT NULL,
    quantity        INT           NOT NULL,
    discount        DECIMAL(4,2)  NOT NULL,
    profit          DECIMAL(12,4) NOT NULL,
    days_to_ship    INT           NOT NULL,
    FOREIGN KEY (order_date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (ship_date_key)  REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key)   REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key)    REFERENCES dim_product(product_key),
    FOREIGN KEY (location_key)   REFERENCES dim_location(location_key)
);
