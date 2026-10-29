-- Which products produced the most gross margin, and how do they rank in their category?

WITH line_margin AS (
  SELECT
    pr.category,
    pr.sku,
    pr.product_name,
    sum(oi.quantity) AS units_sold,
    round(sum(oi.quantity * oi.unit_price), 2) AS gross_sales,
    round(sum(oi.quantity * (oi.unit_price - oi.unit_cost)), 2) AS gross_margin
  FROM order_items AS oi
  JOIN orders AS o ON o.order_id = oi.order_id
  JOIN products AS pr ON pr.product_id = oi.product_id
  WHERE o.status <> 'refunded'
  GROUP BY pr.product_id, pr.category, pr.sku, pr.product_name
),
ranked AS (
  SELECT
    category,
    sku,
    product_name,
    units_sold,
    gross_sales,
    gross_margin,
    round(gross_margin / nullif(gross_sales, 0), 3) AS margin_rate,
    rank() OVER (
      PARTITION BY category
      ORDER BY gross_margin DESC, sku
    ) AS category_rank
  FROM line_margin
)
SELECT
  category,
  category_rank,
  sku,
  product_name,
  units_sold,
  gross_sales,
  gross_margin,
  margin_rate
FROM ranked
WHERE category_rank <= 3
ORDER BY category, category_rank, sku;
