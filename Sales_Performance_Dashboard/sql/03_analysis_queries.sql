-- =============================================================
-- Sales Performance Dashboard | 03 - Business analysis queries
-- Each query answers one business question for the dashboard.
-- =============================================================

USE superstore_db;

-- Q1. Headline KPIs: revenue, profit, margin, orders, customers, average order value
SELECT
    ROUND(SUM(f.sales), 2)                                AS total_sales,
    ROUND(SUM(f.profit), 2)                               AS total_profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2)          AS profit_margin_pct,
    COUNT(DISTINCT f.order_id)                            AS total_orders,
    COUNT(DISTINCT f.customer_key)                        AS total_customers,
    ROUND(SUM(f.sales) / COUNT(DISTINCT f.order_id), 2)   AS avg_order_value
FROM fact_sales f;

-- Q2. Year-over-year growth in sales and profit (window function LAG)
WITH yearly AS (
    SELECT d.year_num,
           SUM(f.sales)  AS sales,
           SUM(f.profit) AS profit,
           COUNT(DISTINCT f.order_id) AS orders
    FROM fact_sales f
    JOIN dim_date d ON d.date_key = f.order_date_key
    GROUP BY d.year_num
)
SELECT year_num,
       ROUND(sales, 2)  AS sales,
       ROUND(profit, 2) AS profit,
       orders,
       ROUND(profit / sales * 100, 2) AS margin_pct,
       ROUND((sales - LAG(sales) OVER (ORDER BY year_num))
             / LAG(sales) OVER (ORDER BY year_num) * 100, 2) AS sales_yoy_pct
FROM yearly
ORDER BY year_num;

-- Q3. Performance by region
SELECT l.region,
       ROUND(SUM(f.sales), 2)  AS sales,
       ROUND(SUM(f.profit), 2) AS profit,
       ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS margin_pct,
       ROUND(SUM(f.sales) / (SELECT SUM(sales) FROM fact_sales) * 100, 1) AS share_of_sales_pct
FROM fact_sales f
JOIN dim_location l ON l.location_key = f.location_key
GROUP BY l.region
ORDER BY sales DESC;

-- Q4. Sub-category profitability ranked within each category (RANK window)
SELECT p.category,
       p.sub_category,
       ROUND(SUM(f.sales), 2)  AS sales,
       ROUND(SUM(f.profit), 2) AS profit,
       ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS margin_pct,
       RANK() OVER (PARTITION BY p.category ORDER BY SUM(f.profit) DESC) AS profit_rank_in_category
FROM fact_sales f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.category, p.sub_category
ORDER BY p.category, profit_rank_in_category;

-- Q5. Loss-making sub-categories and their average discount
SELECT p.sub_category,
       ROUND(SUM(f.sales), 2)  AS sales,
       ROUND(SUM(f.profit), 2) AS profit,
       ROUND(AVG(f.discount) * 100, 1) AS avg_discount_pct
FROM fact_sales f
JOIN dim_product p ON p.product_key = f.product_key
GROUP BY p.sub_category
HAVING SUM(f.profit) < 0
ORDER BY profit;

-- Q6. How discount level affects profit
SELECT
    CASE WHEN discount = 0     THEN '1) No discount'
         WHEN discount <= 0.20 THEN '2) 1-20%'
         WHEN discount <= 0.40 THEN '3) 21-40%'
         ELSE                       '4) Above 40%' END       AS discount_band,
    COUNT(*)                                                AS order_lines,
    ROUND(SUM(sales), 2)                                    AS sales,
    ROUND(SUM(profit), 2)                                   AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2)                AS margin_pct
FROM fact_sales
GROUP BY discount_band
ORDER BY discount_band;

-- Q7. Top 10 customers by sales (DENSE_RANK window)
WITH customer_sales AS (
    SELECT c.customer_name, c.segment,
           SUM(f.sales)  AS sales,
           SUM(f.profit) AS profit,
           COUNT(DISTINCT f.order_id) AS orders
    FROM fact_sales f
    JOIN dim_customer c ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.customer_name, c.segment
)
SELECT *
FROM (
    SELECT customer_name, segment, ROUND(sales, 2) AS sales, ROUND(profit, 2) AS profit, orders,
           DENSE_RANK() OVER (ORDER BY sales DESC) AS sales_rank
    FROM customer_sales
) ranked
WHERE sales_rank <= 10
ORDER BY sales_rank;

-- Q8. Monthly sales with running total inside each year (SUM OVER)
SELECT d.year_num, d.month_num, d.month_name,
       ROUND(SUM(f.sales), 2) AS monthly_sales,
       ROUND(SUM(SUM(f.sales)) OVER (PARTITION BY d.year_num ORDER BY d.month_num), 2) AS running_total_ytd
FROM fact_sales f
JOIN dim_date d ON d.date_key = f.order_date_key
GROUP BY d.year_num, d.month_num, d.month_name
ORDER BY d.year_num, d.month_num;

-- Q9. Segment contribution
SELECT c.segment,
       ROUND(SUM(f.sales), 2)  AS sales,
       ROUND(SUM(f.profit), 2) AS profit,
       ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_customer c ON c.customer_key = f.customer_key
GROUP BY c.segment
ORDER BY sales DESC;

-- Q10. Shipping speed by ship mode
SELECT ship_mode,
       COUNT(DISTINCT order_id)     AS orders,
       ROUND(AVG(days_to_ship), 2)  AS avg_days_to_ship
FROM fact_sales
GROUP BY ship_mode
ORDER BY avg_days_to_ship;
