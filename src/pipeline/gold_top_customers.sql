-- Gold: top customers by total spend.
CREATE OR REFRESH MATERIALIZED VIEW gold_top_customers
COMMENT 'Customers ranked by total spend (gold)'
AS
SELECT
  t.customer_id,
  MAX(t.customer_first_name)                AS first_name,
  MAX(t.customer_last_name)                 AS last_name,
  MAX(t.customer_country)                   AS country,
  SUM(t.total_price)                        AS total_spend,
  COUNT(*)                                  AS orders,
  CAST(AVG(t.total_price) AS DECIMAL(10,2)) AS avg_ticket
FROM silver_transactions t
GROUP BY t.customer_id;
