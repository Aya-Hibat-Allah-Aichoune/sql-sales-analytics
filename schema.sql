-- Retail sales: customers shop stores, orders hold line items, payments move the cash.

CREATE TABLE customers (
  customer_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email        text NOT NULL UNIQUE,
  full_name    text NOT NULL,
  region       text NOT NULL CHECK (region IN ('West', 'South', 'Midwest', 'Northeast')),
  created_at   timestamptz NOT NULL
);

CREATE TABLE stores (
  store_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  store_name  text NOT NULL UNIQUE,
  city        text NOT NULL,
  region      text NOT NULL CHECK (region IN ('West', 'South', 'Midwest', 'Northeast')),
  opened_on   date NOT NULL
);

CREATE TABLE products (
  product_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku           text NOT NULL UNIQUE,
  product_name  text NOT NULL,
  category      text NOT NULL CHECK (category IN ('Apparel', 'Home', 'Grocery', 'Electronics', 'Outdoor')),
  unit_cost     numeric(10, 2) NOT NULL CHECK (unit_cost >= 0),
  list_price    numeric(10, 2) NOT NULL CHECK (list_price >= unit_cost)
);

CREATE TABLE orders (
  order_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id  bigint NOT NULL REFERENCES customers (customer_id),
  store_id     bigint NOT NULL REFERENCES stores (store_id),
  ordered_at   timestamptz NOT NULL,
  status       text NOT NULL CHECK (status IN ('completed', 'partially_refunded', 'refunded'))
);

CREATE TABLE order_items (
  order_item_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id       bigint NOT NULL REFERENCES orders (order_id),
  product_id     bigint NOT NULL REFERENCES products (product_id),
  quantity       integer NOT NULL CHECK (quantity > 0),
  unit_price     numeric(10, 2) NOT NULL CHECK (unit_price >= 0),
  -- Cost at the time of sale, so a later catalog cost change does not rewrite margin.
  unit_cost      numeric(10, 2) NOT NULL CHECK (unit_cost >= 0),
  UNIQUE (order_id, product_id)
);

CREATE TABLE payments (
  payment_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id    bigint NOT NULL REFERENCES orders (order_id),
  paid_at     timestamptz NOT NULL,
  -- A refund is its own row. amount is negative only when kind = 'refund'.
  amount      numeric(12, 2) NOT NULL CHECK (amount <> 0),
  method      text NOT NULL CHECK (method IN ('card', 'cash', 'gift_card')),
  kind        text NOT NULL CHECK (kind IN ('charge', 'refund')),
  CONSTRAINT payments_amount_sign CHECK (
    (kind = 'charge' AND amount > 0)
    OR (kind = 'refund' AND amount < 0)
  )
);

CREATE INDEX orders_store_ordered_at_idx ON orders (store_id, ordered_at);
CREATE INDEX orders_customer_ordered_at_idx ON orders (customer_id, ordered_at);
CREATE INDEX order_items_product_id_idx ON order_items (product_id);
CREATE INDEX payments_order_id_idx ON payments (order_id);
CREATE INDEX payments_paid_at_idx ON payments (paid_at);

-- Docker names this database sales. New sessions then bucket months in UTC.
ALTER DATABASE sales SET timezone TO 'UTC';
