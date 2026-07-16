-- Bronze: raw sales transactions, append-only. No business rules here on purpose —
-- bronze keeps the source shape so we can always replay silver from it.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.transactions
COMMENT 'Raw sales transactions ingested from ${source_catalog}.${source_schema}.sales_transactions.'
CLUSTER BY (franchiseID)
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  '${source_catalog}.${source_schema}.sales_transactions' AS _source_table
FROM STREAM ${source_catalog}.${source_schema}.sales_transactions;
