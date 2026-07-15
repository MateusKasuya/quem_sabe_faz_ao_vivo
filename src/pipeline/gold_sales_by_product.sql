-- Gold: revenue/orders/units per product.
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_by_product
COMMENT 'Revenue, orders and units per product (gold)'
AS
SELECT
  product,
  SUM(total_price)                       AS revenue,
  COUNT(*)                               AS orders,
  SUM(quantity)                          AS units_sold,
  CAST(AVG(total_price) AS DECIMAL(10,2)) AS avg_ticket
FROM silver_transactions
GROUP BY product;
