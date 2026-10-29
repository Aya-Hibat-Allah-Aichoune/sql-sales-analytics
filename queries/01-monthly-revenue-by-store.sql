-- What net revenue did each store book in each month?

SELECT
  date_trunc('month', o.ordered_at)::date AS order_month,
  s.region,
  s.store_name,
  count(DISTINCT o.order_id) AS orders,
  round(sum(p.amount), 2) AS net_revenue
FROM stores AS s
JOIN orders AS o ON o.store_id = s.store_id
JOIN payments AS p ON p.order_id = o.order_id
WHERE o.ordered_at >= date_trunc('month', current_timestamp) - interval '11 months'
GROUP BY 1, s.region, s.store_id, s.store_name
ORDER BY 1, s.region, net_revenue DESC;
