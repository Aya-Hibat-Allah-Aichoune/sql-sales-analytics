# Retail sales analytics

A PostgreSQL project for a small retail chain: eight stores, a year of orders, and the questions a merchandising lead asks. SQL only: schema, seed data, and analytical queries.

## What it shows

- A normalized model of customers, stores, products, orders, line items, and payments, with keys, checks, and indexes chosen for the queries below
- Window functions: `rank`, running `sum`, `lag`, and `ntile`
- Cohort retention and an RFM-style value segmentation
- A date filter the planner can serve from `payments_paid_at_idx`, beside the same question written so that index cannot be used

Sample scale: 8 stores, 40 products, 80 customers, 500 orders, plus line items and payments. Regions, categories, and refunds vary. Eight customers bought only in the oldest four months.

## Run it in under five minutes

Install Docker, then from this directory:

```bash
docker compose up --wait
```

That starts PostgreSQL 16 and, on the first boot, loads `schema.sql` then `seed.sql`. `--wait` returns when the server is accepting connections and all 500 orders are present. The database is `sales`, the user and password are `analytics`, and months are UTC. The password is a local demo credential.

Run a query:

```bash
docker compose exec -T db psql -v ON_ERROR_STOP=1 -U analytics -d sales -f /queries/01-monthly-revenue-by-store.sql
```

Run all six:

```bash
docker compose exec -T db bash -lc 'for f in /queries/*.sql; do echo "===== $f ====="; psql -v ON_ERROR_STOP=1 -U analytics -d sales -f "$f" || exit 1; done'
```

From the host:

```bash
psql "postgresql://analytics:analytics@localhost:5432/sales"
```

Init scripts run only on an empty data volume. To load again from scratch:

```bash
docker compose down -v
docker compose up --wait
```

If port 5432 is already taken, change the host side of `ports` in `docker-compose.yml`.

## Questions

### 1. Monthly revenue by store

`queries/01-monthly-revenue-by-store.sql`

Net revenue is the sum of payments on orders placed that month, so a refund reduces the sale month. Each row is one store in one month: compare stores in a region, then read down the months for a soft patch. A store with no orders that month is absent.

### 2. Top products by margin

`queries/02-top-products-by-margin.sql`

`rank()` over gross margin, `(unit price - unit cost) * quantity`, partitioned by category. Fully refunded orders are excluded because those units came back. Partial refunds stay in the product margin because a payment does not name the SKU that was returned. Rank 1 is the margin leader in that category. `margin_rate` sits beside it, so a high rate on a low rank is a profitable unit that has not sold enough to lead.

### 3. Running revenue and month-over-month change

`queries/03-running-revenue-and-mom.sql`

Cash is dated when the payment or refund posted. `running_cash` is the accumulated total. `mom_change_pct` is the percent change versus the prior month, and the first month has no comparison. A refund can land in a later month than the sale, which is why this series can move differently from question 1.

### 4. Customer cohort retention

`queries/04-customer-cohort-retention.sql`

Customers are grouped by the month of their first order. Each later row is the share of that cohort with an order that many months out. Offset 0 is 1.000, because the acquiring order counts. A drop after offset 0 is one-time buying. A cohort that stays well above zero is the repeat base.

### 5. RFM-style customer value

`queries/05-rfm-customer-segments.sql`

Recency, frequency, and net spend, each scored in quintiles where 5 is best, plus a segment label. Champions are recent, frequent, and high spend. At risk is a customer with real history who then went quiet, which is the shape of the eight customers with no orders in the last 90 days when their earlier spend still ranks. Hibernating is quiet and low value.

### Index rewrite

`queries/06-indexed-rewrite.sql` asks which stores brought in the most net cash last calendar month, twice. The first filter wraps `paid_at` in `date_trunc`, and the planner sequential-scans `payments`. The second writes that month as a half-open range on `paid_at`, and the planner bitmap-scans `payments_paid_at_idx`. The two result sets match.

## Layout

- `schema.sql` — tables, constraints, indexes
- `seed.sql` — deterministic sample for the trailing twelve calendar months
- `queries/` — the six analyses
- `docker-compose.yml` — Postgres 16 and the one-command load
