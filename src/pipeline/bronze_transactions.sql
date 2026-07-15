-- Bronze: raw ingestion of sales transactions from samples.bakehouse (read-only source).
CREATE OR REFRESH STREAMING TABLE bronze_transactions
COMMENT 'Raw sales transactions ingested from samples.bakehouse.sales_transactions'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_transactions' AS _source_table
FROM STREAM samples.bakehouse.sales_transactions;
