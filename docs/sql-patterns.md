# SQL pattern reference

The reusable patterns behind the case studies, in PostgreSQL. MySQL differences are listed at the end.

## Rate with everyone in the denominator
```sql
SELECT a.segment,
       COUNT(DISTINCT a.id)                                     AS eligible,
       COUNT(DISTINCT a.id) FILTER (WHERE p.adopted = 1)        AS adopters,
       ROUND(100.0 * COUNT(DISTINCT a.id) FILTER (WHERE p.adopted = 1)
             / NULLIF(COUNT(DISTINCT a.id), 0), 1)              AS adoption_pct
FROM accounts a
LEFT JOIN adoption p ON p.id = a.id AND p.product = 'X'   -- joined-table filter in ON
WHERE a.eligible = 1                                       -- base-table filter in WHERE
GROUP BY a.segment;
```

## "Never did X"
```sql
LEFT JOIN adoption p ON p.id = a.id AND p.product = 'X'
WHERE (p.id IS NULL OR p.adopted = 0)     -- no record, or a record without adoption
```

## Aggregate first, then join (avoid fan-out)
```sql
WITH per_account AS (
    SELECT id, AVG(spend) AS avg_spend
    FROM monthly
    GROUP BY id
)
SELECT ... FROM accounts a LEFT JOIN per_account s USING (id);
```

## Average that counts non-doers as zero
```sql
AVG(COALESCE(s.avg_spend, 0))
```

## Change vs. previous period
```sql
WITH w AS (
    SELECT id, month, spend,
           LAG(spend) OVER (PARTITION BY id ORDER BY month) AS prev_spend
    FROM monthly                         -- no date filter here
)
SELECT * FROM w
WHERE month >= '2024-09-01'              -- filter after the window
  AND prev_spend > 0 AND spend <= 0.5 * prev_spend;
```

## Top N within each group
```sql
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY segment ORDER BY total DESC) AS rn
    FROM totals
)
SELECT * FROM ranked WHERE rn <= 2;
```

## Experiment lift with a z-test
```sql
WITH a AS (
    SELECT COUNT(*) FILTER (WHERE variant = 't') AS n_t,
           SUM(y)   FILTER (WHERE variant = 't') AS x_t,
           COUNT(*) FILTER (WHERE variant = 'c') AS n_c,
           SUM(y)   FILTER (WHERE variant = 'c') AS x_c
    FROM experiment
), r AS (
    SELECT *, x_t::numeric/n_t AS p_t, x_c::numeric/n_c AS p_c,
           (x_t + x_c)::numeric/(n_t + n_c) AS p
    FROM a
)
SELECT p_t - p_c AS lift,
       (p_t - p_c) / SQRT(p * (1 - p) * (1.0/n_t + 1.0/n_c)) AS z
FROM r;
```

## Sample ratio check (50/50 design)
```sql
SELECT 2 * POWER(COUNT(*) FILTER (WHERE variant = 't') - COUNT(*)/2.0, 2)
         / (COUNT(*)/2.0) AS chi_square      -- above 3.84 fails at 5%
FROM experiment;
```

## Running share (concentration)
```sql
SUM(value) OVER (ORDER BY value DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
  / SUM(value) OVER () AS cumulative_share
```

## PostgreSQL to MySQL

| Task | PostgreSQL | MySQL 8 |
|---|---|---|
| Conditional count | `COUNT(*) FILTER (WHERE x)` | `SUM(CASE WHEN x THEN 1 ELSE 0 END)` |
| Last 3 months | `- INTERVAL '3 months'` | `- INTERVAL 3 MONTH` |
| Days between | `d2 - d1` | `DATEDIFF(d2, d1)` |
| Month start | `DATE_TRUNC('month', d)` | `DATE_FORMAT(d, '%Y-%m-01')` |
| Integer division | `3/5 = 0` (use `100.0 *`) | `3/5 = 0.6` |
| Median | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x)` | No built-in; use `ROW_NUMBER` |
