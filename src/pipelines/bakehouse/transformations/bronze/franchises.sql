-- Bronze: raw franchise master data (48 franchises, 9 countries, incl. lat/long).
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.franchises
COMMENT 'Raw franchise master data ingested from ${source_catalog}.${source_schema}.sales_franchises.'
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  '${source_catalog}.${source_schema}.sales_franchises' AS _source_table
FROM STREAM ${source_catalog}.${source_schema}.sales_franchises;
