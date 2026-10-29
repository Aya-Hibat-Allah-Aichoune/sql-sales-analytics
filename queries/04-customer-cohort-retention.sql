-- Of the customers first seen each month, what share ordered again in each later month?

WITH first_order AS (
  SELECT
    customer_id,
    date_trunc('month', min(ordered_at))::date AS cohort_month
  FROM orders
  GROUP BY customer_id
),
activity AS (
  SELECT DISTINCT
    f.customer_id,
    f.cohort_month,
    date_trunc('month', o.ordered_at)::date AS active_month
  FROM first_order AS f
  JOIN orders AS o ON o.customer_id = f.customer_id
),
offsets AS (
  SELECT
    cohort_month,
    (
      (EXTRACT(YEAR FROM active_month) - EXTRACT(YEAR FROM cohort_month)) * 12
      + (EXTRACT(MONTH FROM active_month) - EXTRACT(MONTH FROM cohort_month))
    )::int AS month_offset,
    count(*) AS active_customers
  FROM activity
  GROUP BY cohort_month, active_month
),
sizes AS (
  SELECT cohort_month, count(*) AS cohort_size
  FROM first_order
  GROUP BY cohort_month
)
SELECT
  o.cohort_month,
  s.cohort_size,
  o.month_offset,
  o.active_customers,
  round(o.active_customers::numeric / s.cohort_size, 3) AS retention_rate
FROM offsets AS o
JOIN sizes AS s USING (cohort_month)
ORDER BY o.cohort_month, o.month_offset;
