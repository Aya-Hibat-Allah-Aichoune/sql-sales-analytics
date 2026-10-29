-- Which stores brought in the most net cash last calendar month?

-- date_trunc() on paid_at is not sargable, so payments_paid_at_idx cannot serve this filter.
WITH target AS (
  SELECT date_trunc('month', max(paid_at)) - interval '1 month' AS month_start
  FROM payments
)
SELECT
  s.region,
  s.store_name,
  round(sum(p.amount), 2) AS net_cash
FROM payments AS p
JOIN orders AS o ON o.order_id = p.order_id
JOIN stores AS s ON s.store_id = o.store_id
CROSS JOIN target AS t
WHERE date_trunc('month', p.paid_at) = t.month_start
GROUP BY s.region, s.store_id, s.store_name
ORDER BY net_cash DESC, s.store_name;

-- Same month as a half-open range. The predicate is sargable, so the planner bitmap-scans payments_paid_at_idx instead of reading every payment row.
WITH target AS (
  SELECT date_trunc('month', max(paid_at)) - interval '1 month' AS month_start
  FROM payments
)
SELECT
  s.region,
  s.store_name,
  round(sum(p.amount), 2) AS net_cash
FROM payments AS p
JOIN orders AS o ON o.order_id = p.order_id
JOIN stores AS s ON s.store_id = o.store_id
CROSS JOIN target AS t
WHERE p.paid_at >= t.month_start
  AND p.paid_at < t.month_start + interval '1 month'
GROUP BY s.region, s.store_id, s.store_name
ORDER BY net_cash DESC, s.store_name;
