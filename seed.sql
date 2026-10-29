-- Twelve calendar months of sample retail activity.
-- Customers 1-8 buy only in the oldest four months. Everyone else has a recent order.
-- The checks at the bottom abort the load if those counts drift.

SET timezone = 'UTC';

BEGIN;

INSERT INTO stores (store_name, city, region, opened_on) VALUES
  ('Harbor & Pine', 'Seattle', 'West', '2016-04-12'),
  ('Market Street Goods', 'San Francisco', 'West', '2018-09-03'),
  ('Rio Grande Outfitters', 'Austin', 'South', '2015-11-20'),
  ('Magnolia Home', 'Atlanta', 'South', '2019-02-14'),
  ('Lakeshore Supply', 'Chicago', 'Midwest', '2014-06-01'),
  ('Cuyahoga General', 'Cleveland', 'Midwest', '2017-08-22'),
  ('Hudson Mercantile', 'New York', 'Northeast', '2013-03-18'),
  ('Beacon Hill Dry Goods', 'Boston', 'Northeast', '2020-01-09');

INSERT INTO products (sku, product_name, category, unit_cost, list_price) VALUES
  ('APP-001', 'Merino Crewneck', 'Apparel', 28.00, 78.00),
  ('APP-002', 'Waxed Field Jacket', 'Apparel', 90.00, 240.00),
  ('APP-003', 'Selvedge Jeans', 'Apparel', 48.00, 128.00),
  ('APP-004', 'Linen Camp Shirt', 'Apparel', 22.00, 68.00),
  ('APP-005', 'Wool Beanie', 'Apparel', 6.00, 24.00),
  ('APP-006', 'Canvas Tote', 'Apparel', 8.00, 32.00),
  ('APP-007', 'Leather Belt', 'Apparel', 18.00, 58.00),
  ('APP-008', 'Trail Running Shorts', 'Apparel', 16.00, 54.00),
  ('HOM-001', 'Stoneware Mug', 'Home', 4.00, 18.00),
  ('HOM-002', 'Linen Throw', 'Home', 25.00, 72.00),
  ('HOM-003', 'Oak Cutting Board', 'Home', 18.00, 54.00),
  ('HOM-004', 'Ceramic Table Lamp', 'Home', 32.00, 96.00),
  ('HOM-005', 'Beeswax Candle Set', 'Home', 7.00, 26.00),
  ('HOM-006', 'Wool Area Rug', 'Home', 80.00, 220.00),
  ('HOM-007', 'Enamel Dutch Oven', 'Home', 45.00, 120.00),
  ('HOM-008', 'Cotton Sheet Set', 'Home', 28.00, 84.00),
  ('GRO-001', 'Single Origin Coffee', 'Grocery', 8.00, 16.00),
  ('GRO-002', 'Olive Oil 500ml', 'Grocery', 7.00, 18.00),
  ('GRO-003', 'Wildflower Honey', 'Grocery', 5.00, 14.00),
  ('GRO-004', 'Sea Salt Caramels', 'Grocery', 3.00, 9.00),
  ('GRO-005', 'Sourdough Loaf', 'Grocery', 2.00, 7.00),
  ('GRO-006', 'Aged Cheddar', 'Grocery', 4.00, 11.00),
  ('GRO-007', 'Sparkling Water 8pk', 'Grocery', 3.00, 8.00),
  ('GRO-008', 'Dark Chocolate Bar', 'Grocery', 2.00, 6.00),
  ('ELC-001', 'Wireless Earbuds', 'Electronics', 28.00, 79.00),
  ('ELC-002', 'USB-C Power Bank', 'Electronics', 14.00, 39.00),
  ('ELC-003', 'Mechanical Keyboard', 'Electronics', 45.00, 129.00),
  ('ELC-004', 'LED Desk Lamp', 'Electronics', 18.00, 48.00),
  ('ELC-005', 'Noise-Canceling Headphones', 'Electronics', 70.00, 199.00),
  ('ELC-006', 'Fitness Tracker', 'Electronics', 35.00, 99.00),
  ('ELC-007', 'Portable Speaker', 'Electronics', 22.00, 59.00),
  ('ELC-008', 'HD Webcam', 'Electronics', 25.00, 69.00),
  ('OUT-001', 'Daypack 20L', 'Outdoor', 24.00, 68.00),
  ('OUT-002', 'Insulated Bottle', 'Outdoor', 8.00, 28.00),
  ('OUT-003', 'Hiking Socks 2pk', 'Outdoor', 5.00, 18.00),
  ('OUT-004', 'Titanium Camp Mug', 'Outdoor', 12.00, 34.00),
  ('OUT-005', 'Rain Shell', 'Outdoor', 40.00, 110.00),
  ('OUT-006', 'Headlamp', 'Outdoor', 9.00, 29.00),
  ('OUT-007', 'Trekking Poles', 'Outdoor', 22.00, 64.00),
  ('OUT-008', 'Picnic Blanket', 'Outdoor', 11.00, 36.00);

INSERT INTO customers (customer_id, email, full_name, region, created_at)
OVERRIDING SYSTEM VALUE
SELECT
  i,
  'customer' || lpad(i::text, 2, '0') || '@example.com',
  firsts[1 + ((i - 1) % 20)]
    || ' ' || lasts[1 + ((((i - 1) % 20) + ((i - 1) / 20) * 5) % 20)],
  regions[1 + ((i - 1) % 4)],
  date_trunc('month', current_timestamp)
    - interval '11 months'
    - interval '90 days'
    + (i - 1) * interval '1 day'
FROM generate_series(1, 80) AS g(i)
CROSS JOIN (
  SELECT
    ARRAY[
      'Ava', 'Noah', 'Mia', 'Leo', 'Sofia', 'Ethan', 'Isla', 'Omar', 'Priya', 'Jonah',
      'Elena', 'Hugo', 'Nora', 'Caleb', 'Amira', 'Felix', 'Hana', 'Mateo', 'Ruby', 'Ivan'
    ] AS firsts,
    ARRAY[
      'Nguyen', 'Patel', 'Garcia', 'Cohen', 'Silva', 'Kim', 'Rossi', 'Novak', 'Ibrahim', 'Larsen',
      'Santos', 'Becker', 'Okonkwo', 'Duarte', 'Alvarez', 'Moreau', 'Petrov', 'Walsh', 'Tanaka', 'Berg'
    ] AS lasts,
    ARRAY['West', 'South', 'Midwest', 'Northeast'] AS regions
) AS names
ORDER BY i;

SELECT setval(
  pg_get_serial_sequence('customers', 'customer_id'),
  (SELECT max(customer_id) FROM customers)
);

WITH params AS (
  SELECT date_trunc('month', current_timestamp) - interval '11 months' AS month0
),
slots AS (
  SELECT 'early'::text AS slice, n
  FROM generate_series(1, 48) AS g(n)
  UNION ALL
  SELECT 'recent'::text, n
  FROM generate_series(1, 452) AS g(n)
),
assigned AS (
  SELECT
    s.slice,
    s.n,
    p.month0,
    CASE
      WHEN s.slice = 'early' THEN 1 + ((s.n - 1) % 8)
      WHEN s.n <= 72 THEN 8 + s.n
      WHEN (hashtextextended('whale-' || s.n::text, 42) & 9223372036854775807) % 100 < 40
        THEN 9 + ((hashtextextended('cust-' || s.n::text, 2) & 9223372036854775807) % 12)::int
      ELSE 21 + ((hashtextextended('cust-' || s.n::text, 2) & 9223372036854775807) % 60)::int
    END AS customer_id,
    CASE
      WHEN s.slice = 'early' THEN ((s.n - 1) / 8) % 4
      WHEN s.n <= 72 THEN 10 + ((s.n - 1) % 2)
      ELSE (s.n - 1) % 12
    END AS month_index,
    CASE (hashtextextended(s.slice || '-status-' || s.n::text, 11) & 9223372036854775807) % 20
      WHEN 0 THEN 'refunded'
      WHEN 1 THEN 'partially_refunded'
      WHEN 2 THEN 'partially_refunded'
      ELSE 'completed'
    END AS status
  FROM slots AS s
  CROSS JOIN params AS p
),
stamped AS (
  SELECT
    a.customer_id,
    a.status,
    a.slice,
    a.n,
    a.month0
      + a.month_index * interval '1 month'
      + (
          (hashtextextended(a.slice || '-dom-' || a.n::text, 12) & 9223372036854775807)
          % EXTRACT(DAY FROM (a.month0 + (a.month_index + 1) * interval '1 month' - interval '1 day'))::int
        ) * interval '1 day'
      + (9 + ((hashtextextended(a.slice || '-hr-' || a.n::text, 13) & 9223372036854775807) % 10)) * interval '1 hour'
      + ((hashtextextended(a.slice || '-min-' || a.n::text, 14) & 9223372036854775807) % 60) * interval '1 minute'
      AS raw_at
  FROM assigned AS a
),
timed AS (
  SELECT
    customer_id,
    status,
    slice,
    n,
    CASE
      WHEN raw_at > current_timestamp - interval '1 hour' THEN current_timestamp - interval '1 hour'
      ELSE raw_at
    END AS ordered_at
  FROM stamped
)
INSERT INTO orders (customer_id, store_id, ordered_at, status)
SELECT
  t.customer_id,
  st.store_id,
  t.ordered_at,
  t.status
FROM timed AS t
JOIN customers AS c ON c.customer_id = t.customer_id
CROSS JOIN LATERAL (
  SELECT s.store_id
  FROM stores AS s
  WHERE CASE
    WHEN (hashtextextended(t.slice || '-travel-' || t.n::text, 42) & 9223372036854775807) % 100 < 75
      THEN s.region = c.region
    ELSE s.region <> c.region
  END
  ORDER BY hashtextextended(t.slice || '-store-' || t.n::text || '-' || s.store_id::text, 6)
  LIMIT 1
) AS st;

INSERT INTO order_items (order_id, product_id, quantity, unit_price, unit_cost)
SELECT
  o.order_id,
  picked.product_id,
  1 + ((hashtextextended(o.order_id::text || ':' || picked.product_id::text, 21) & 9223372036854775807) % 3)::int,
  CASE
    WHEN (hashtextextended(o.order_id::text || ':disc:' || picked.product_id::text, 22) & 9223372036854775807) % 5 = 0
      THEN round(picked.list_price * 0.90, 2)
    ELSE picked.list_price
  END,
  picked.unit_cost
FROM orders AS o
CROSS JOIN LATERAL (
  SELECT pr.product_id, pr.list_price, pr.unit_cost
  FROM products AS pr
  ORDER BY hashtextextended(o.order_id::text || ':' || pr.product_id::text, 20)
  LIMIT 1 + ((hashtextextended(o.order_id::text, 19) & 9223372036854775807) % 3)::int
) AS picked;

INSERT INTO payments (order_id, paid_at, amount, method, kind)
SELECT
  o.order_id,
  o.ordered_at + interval '8 minutes',
  totals.gross,
  (ARRAY['card', 'card', 'card', 'card', 'cash', 'gift_card'])[
    1 + ((hashtextextended(o.order_id::text, 30) & 9223372036854775807) % 6)::int
  ],
  'charge'
FROM orders AS o
JOIN (
  SELECT order_id, round(sum(quantity * unit_price), 2) AS gross
  FROM order_items
  GROUP BY order_id
) AS totals ON totals.order_id = o.order_id;

INSERT INTO payments (order_id, paid_at, amount, method, kind)
SELECT
  o.order_id,
  LEAST(
    o.ordered_at + (10 + ((hashtextextended(o.order_id::text, 31) & 9223372036854775807) % 18)) * interval '1 day',
    current_timestamp
  ),
  CASE
    WHEN o.status = 'refunded' THEN -totals.gross
    ELSE -round(
      totals.gross * (
        0.25 + ((hashtextextended(o.order_id::text, 32) & 9223372036854775807) % 3)::numeric * 0.10
      ),
      2
    )
  END,
  'card',
  'refund'
FROM orders AS o
JOIN (
  SELECT order_id, round(sum(quantity * unit_price), 2) AS gross
  FROM order_items
  GROUP BY order_id
) AS totals ON totals.order_id = o.order_id
WHERE o.status IN ('refunded', 'partially_refunded');

DO $$
DECLARE
  n_stores int;
  n_products int;
  n_customers int;
  n_orders int;
  n_items int;
  n_payments int;
  n_dormant int;
  n_months int;
BEGIN
  SELECT count(*) INTO n_stores FROM stores;
  SELECT count(*) INTO n_products FROM products;
  SELECT count(*) INTO n_customers FROM customers;
  SELECT count(*) INTO n_orders FROM orders;
  SELECT count(*) INTO n_items FROM order_items;
  SELECT count(*) INTO n_payments FROM payments;

  IF n_stores <> 8 OR n_products <> 40 OR n_customers <> 80 OR n_orders <> 500 THEN
    RAISE EXCEPTION 'unexpected dimensions stores=% products=% customers=% orders=%',
      n_stores, n_products, n_customers, n_orders;
  END IF;

  IF n_items < n_orders OR n_payments < n_orders THEN
    RAISE EXCEPTION 'missing line items or payments items=% payments=%', n_items, n_payments;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE NOT EXISTS (SELECT 1 FROM order_items AS i WHERE i.order_id = o.order_id)
       OR NOT EXISTS (
         SELECT 1 FROM payments AS p
         WHERE p.order_id = o.order_id AND p.kind = 'charge'
       )
  ) THEN
    RAISE EXCEPTION 'an order is missing a line or a charge';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM orders AS o
    JOIN (
      SELECT order_id, round(sum(quantity * unit_price), 2)::numeric(12, 2) AS gross
      FROM order_items
      GROUP BY order_id
    ) AS i USING (order_id)
    JOIN payments AS p ON p.order_id = o.order_id AND p.kind = 'charge'
    WHERE p.amount <> i.gross
  ) THEN
    RAISE EXCEPTION 'a charge does not match its line total';
  END IF;

  IF EXISTS (
    SELECT 1 FROM payments GROUP BY order_id HAVING sum(amount) < 0
  ) THEN
    RAISE EXCEPTION 'an order nets below zero';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.status = 'completed'
      AND EXISTS (
        SELECT 1 FROM payments AS p
        WHERE p.order_id = o.order_id AND p.kind = 'refund'
      )
  ) OR EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.status IN ('refunded', 'partially_refunded')
      AND NOT EXISTS (
        SELECT 1 FROM payments AS p
        WHERE p.order_id = o.order_id AND p.kind = 'refund'
      )
  ) THEN
    RAISE EXCEPTION 'order status does not match refund rows';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM orders WHERE status = 'refunded')
     OR NOT EXISTS (SELECT 1 FROM orders WHERE status = 'partially_refunded') THEN
    RAISE EXCEPTION 'expected both full and partial refunds';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM customers AS c
    WHERE NOT EXISTS (SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id)
  ) THEN
    RAISE EXCEPTION 'a customer has no orders';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM customers AS c
    JOIN orders AS o ON o.customer_id = c.customer_id
    WHERE c.customer_id <= 8
      AND o.ordered_at >= current_timestamp - interval '90 days'
  ) OR EXISTS (
    SELECT 1
    FROM customers AS c
    WHERE c.customer_id <= 8
      AND NOT EXISTS (SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id)
  ) THEN
    RAISE EXCEPTION 'customers 1-8 should have history and no recent orders';
  END IF;

  SELECT count(*) INTO n_dormant
  FROM customers AS c
  WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.customer_id
      AND o.ordered_at >= current_timestamp - interval '90 days'
  );

  IF n_dormant <> 8 THEN
    RAISE EXCEPTION 'expected 8 customers with no recent orders, found %', n_dormant;
  END IF;

  SELECT count(*) INTO n_months
  FROM (
    SELECT date_trunc('month', ordered_at) AS m
    FROM orders
    GROUP BY 1
  ) AS months;

  IF n_months <> 12 THEN
    RAISE EXCEPTION 'expected orders in 12 months, found %', n_months;
  END IF;

  RAISE NOTICE 'seed ok stores=% products=% customers=% orders=% items=% payments=% dormant=% months=%',
    n_stores, n_products, n_customers, n_orders, n_items, n_payments, n_dormant, n_months;
END $$;

ANALYZE customers, stores, products, orders, order_items, payments;

COMMIT;
