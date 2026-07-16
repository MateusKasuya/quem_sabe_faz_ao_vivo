-- Gold: customer value mart. Grain: one row per customer, ranked by revenue.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.top_customers
COMMENT 'Per-customer spend, ranked by total revenue.'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  customer_id,
  customer_name,
  customer_country AS country,
  customer_gender AS gender,
  COUNT(*) AS total_orders,
  COUNT(DISTINCT franchise_id) AS franchises_visited,
  COUNT(DISTINCT product) AS distinct_products,
  SUM(quantity) AS total_units,
  SUM(total_price) AS total_revenue,
  ROUND(AVG(total_price), 2) AS avg_ticket,
  MIN(transaction_date) AS first_purchase_date,
  MAX(transaction_date) AS last_purchase_date,
  DENSE_RANK() OVER (ORDER BY SUM(total_price) DESC) AS revenue_rank
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY customer_id, customer_name, customer_country, customer_gender;
