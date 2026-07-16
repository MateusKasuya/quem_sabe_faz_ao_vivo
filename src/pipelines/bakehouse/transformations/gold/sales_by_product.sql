-- Gold: product mix. Grain: one row per product.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_product
COMMENT 'Revenue and volume per product, with each product share of total revenue.'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  product,
  COUNT(*) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT franchise_id) AS selling_franchises,
  SUM(quantity) AS total_units,
  SUM(total_price) AS total_revenue,
  ROUND(AVG(total_price), 2) AS avg_ticket,
  ROUND(100.0 * SUM(total_price) / SUM(SUM(total_price)) OVER (), 2) AS revenue_pct
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY product;
