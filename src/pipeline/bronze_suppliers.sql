-- Bronze: raw ingestion of suppliers/ingredients from samples.bakehouse.
CREATE OR REFRESH STREAMING TABLE bronze_suppliers
COMMENT 'Raw suppliers ingested from samples.bakehouse.sales_suppliers'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_suppliers' AS _source_table
FROM STREAM samples.bakehouse.sales_suppliers;
