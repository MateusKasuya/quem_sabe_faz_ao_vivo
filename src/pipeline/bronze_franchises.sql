-- Bronze: raw ingestion of franchises (with geo lat/long) from samples.bakehouse.
CREATE OR REFRESH STREAMING TABLE bronze_franchises
COMMENT 'Raw franchises ingested from samples.bakehouse.sales_franchises'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.sales_franchises' AS _source_table
FROM STREAM samples.bakehouse.sales_franchises;
