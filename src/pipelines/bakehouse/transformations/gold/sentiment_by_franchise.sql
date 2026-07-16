-- Gold: review sentiment per franchise. Grain: one row per franchise with reviews.
--
-- ai_analyze_sentiment returns four labels, not three: 'mixed' is counted explicitly
-- alongside positive/negative/neutral, and rows the model could not score (NULL) are
-- counted too — so total_reviews always equals the sum of the buckets, and a franchise's
-- percentages never quietly drop reviews on the floor.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sentiment_by_franchise
COMMENT 'Review sentiment breakdown per franchise (positive/negative/neutral/mixed/unscored).'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  s.franchise_id,
  f.franchise_name,
  f.city,
  f.country,
  COUNT(*) AS total_reviews,
  COUNT_IF(s.sentiment = 'positive') AS positive_reviews,
  COUNT_IF(s.sentiment = 'negative') AS negative_reviews,
  COUNT_IF(s.sentiment = 'neutral') AS neutral_reviews,
  COUNT_IF(s.sentiment = 'mixed') AS mixed_reviews,
  COUNT_IF(s.sentiment IS NULL) AS unscored_reviews,
  ROUND(100.0 * COUNT_IF(s.sentiment = 'positive') / NULLIF(COUNT(*), 0), 2) AS positive_pct,
  ROUND(100.0 * COUNT_IF(s.sentiment = 'negative') / NULLIF(COUNT(*), 0), 2) AS negative_pct
FROM ${medallion_catalog}.${silver_schema}.reviews_sentiment s
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON s.franchise_id = f.franchise_id
GROUP BY s.franchise_id, f.franchise_name, f.city, f.country;
