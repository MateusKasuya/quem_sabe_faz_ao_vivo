-- Bronze: raw customer master data (300 customers).
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.customers
COMMENT 'Raw customer master data ingested from ${source_catalog}.${source_schema}.sales_customers.'
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  '${source_catalog}.${source_schema}.sales_customers' AS _source_table
FROM STREAM ${source_catalog}.${source_schema}.sales_customers;
