-- Which customers are champions, loyal, or at risk from recency, frequency, and net spend?

WITH as_of AS (
  SELECT current_timestamp AS ts
),
per_order AS (
  SELECT
    o.customer_id,
    o.order_id,
    o.ordered_at,
    coalesce(sum(p.amount), 0) AS net_amount
  FROM orders AS o
  LEFT JOIN payments AS p ON p.order_id = o.order_id
  GROUP BY o.customer_id, o.order_id, o.ordered_at
),
metrics AS (
  SELECT
    c.customer_id,
    c.full_name,
    c.region,
    a.ts::date - max(po.ordered_at)::date AS recency_days,
    count(po.order_id) AS frequency,
    round(sum(po.net_amount), 2) AS monetary
  FROM customers AS c
  JOIN per_order AS po ON po.customer_id = c.customer_id
  CROSS JOIN as_of AS a
  GROUP BY c.customer_id, c.full_name, c.region, a.ts
),
scored AS (
  SELECT
    customer_id,
    full_name,
    region,
    recency_days,
    frequency,
    monetary,
    (6 - ntile(5) OVER (ORDER BY recency_days ASC, customer_id))::int AS r_score,
    ntile(5) OVER (ORDER BY frequency ASC, customer_id) AS f_score,
    ntile(5) OVER (ORDER BY monetary ASC, customer_id) AS m_score
  FROM metrics
)
SELECT
  full_name,
  region,
  recency_days,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  r_score::text || f_score::text || m_score::text AS rfm,
  CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At risk'
    WHEN r_score <= 2 THEN 'Hibernating'
    WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent light buyers'
    WHEN f_score >= 4 OR m_score >= 4 THEN 'Loyal'
    ELSE 'Core'
  END AS segment
FROM scored
ORDER BY monetary DESC, customer_id;
