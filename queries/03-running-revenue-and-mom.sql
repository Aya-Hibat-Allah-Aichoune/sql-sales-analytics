-- How has cash collected accumulated, and how did each month change versus the prior month?

WITH monthly AS (
  SELECT
    date_trunc('month', paid_at)::date AS cash_month,
    round(sum(amount), 2) AS net_cash
  FROM payments
  GROUP BY 1
),
windowed AS (
  SELECT
    cash_month,
    net_cash,
    round(sum(net_cash) OVER w, 2) AS running_cash,
    lag(net_cash) OVER w AS prior_month_cash
  FROM monthly
  WINDOW w AS (ORDER BY cash_month)
)
SELECT
  cash_month,
  net_cash,
  running_cash,
  prior_month_cash,
  round(
    100.0 * (net_cash - prior_month_cash) / nullif(prior_month_cash, 0),
    1
  ) AS mom_change_pct
FROM windowed
ORDER BY cash_month;
