-- Gold: review sentiment counts per franchise.
-- ai_analyze_sentiment yields positive/negative/neutral/mixed — ALL FOUR are counted
-- ('mixed' is common in this dataset; omitting it drops ~1/3 of reviews).
CREATE OR REFRESH MATERIALIZED VIEW gold_sentiment_by_franchise
COMMENT 'Review sentiment counts per franchise (gold)'
AS
SELECT
  s.franchise_id,
  f.franchise_name,
  f.franchise_country,
  COUNT(*)                                                          AS total_reviews,
  SUM(CASE WHEN s.sentiment = 'positive' THEN 1 ELSE 0 END)         AS positive_reviews,
  SUM(CASE WHEN s.sentiment = 'negative' THEN 1 ELSE 0 END)         AS negative_reviews,
  SUM(CASE WHEN s.sentiment = 'neutral'  THEN 1 ELSE 0 END)         AS neutral_reviews,
  SUM(CASE WHEN s.sentiment = 'mixed'    THEN 1 ELSE 0 END)         AS mixed_reviews
FROM silver_reviews_sentiment s
LEFT JOIN (
  SELECT DISTINCT franchise_id, franchise_name, franchise_country
  FROM gold_franchise_performance
) f ON s.franchise_id = f.franchise_id
GROUP BY s.franchise_id, f.franchise_name, f.franchise_country;
