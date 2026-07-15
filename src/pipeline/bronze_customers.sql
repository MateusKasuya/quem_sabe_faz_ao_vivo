-- Bronze: raw ingestion of customers from samples.bakehouse.
CREATE OR REFRESH STREAMING TABLE bronze_customers
COMMENT 'Raw customers ingested from samples.bakehouse.sales_customers'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_customers' AS _source_table
FROM STREAM samples.bakehouse.sales_customers;
