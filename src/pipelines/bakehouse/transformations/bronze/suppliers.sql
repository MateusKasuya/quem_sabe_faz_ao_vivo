-- Bronze: raw supplier master data (27 suppliers).
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.suppliers
COMMENT 'Raw supplier master data ingested from ${source_catalog}.${source_schema}.sales_suppliers.'
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  '${source_catalog}.${source_schema}.sales_suppliers' AS _source_table
FROM STREAM ${source_catalog}.${source_schema}.sales_suppliers;
