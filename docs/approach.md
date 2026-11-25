# How I approach an analytics question

Every case in this repo follows the same routine. It works whether I write the SQL myself or guide an AI assistant to write it.

## 1. Turn the business question into five answers

| Step | Ask | Example (Case 1) |
|---|---|---|
| **Grain** | What is one row of the answer? | One row per company size |
| **Everyone** | Who is in the denominator? | Advertisers eligible for Advantage+ |
| **Yes** | Who counts, or what value do I calculate? | Adopted Advantage+ Shopping |
| **Where** | Which table holds each piece, and how do they join? | `advertisers` LEFT JOIN `product_adoption` on `advertiser_id` |
| **Traps** | What could break the count? | Eligible advertisers with no adoption record |

Before writing anything, I say one sentence: *"The population is ___, the metric is ___, and the decision is ___."*

## 2. Check the data before the metric
- `DESCRIBE` or `\d table` to confirm columns and types
- `SELECT DISTINCT` on any text value I filter on (product names, event names)
- `MIN` and `MAX` of every date I use, so "last 3 months" means something
- Row counts per key, to know whether a join can multiply rows

## 3. Write the query (or the prompt) in the same order
**Goal → base table → joins → filters → grain → calculations → output**

Prompt template when using an AI assistant:
> "Goal: [business question and decision]. Start from [base table] where [population filters]. LEFT JOIN [table] on [key], with [joined-table filter] in the join. Calculate [metric definitions]. One row per [grain], sorted by [order]. [Dialect], short column names, table output."

## 4. Validate before interpreting
| Check | What it catches |
|---|---|
| Row count matches the grain | Missing or duplicated groups |
| Hand-check one row against the raw data | Wrong joins, wrong filters |
| Rates stay between 0% and 100% | Counting events instead of people |
| Totals reconcile across queries | Dropped rows |
| Experiment arms are balanced | Broken randomization |

## 5. Interpret: finding, caveat, next step
> "The data shows ___. One caveat is ___. Next, I'd ___."

## Mistakes this routine is designed to catch
Each one appears in at least one case:

| Mistake | Symptom | Fix | Case |
|---|---|---|---|
| Filter on the joined table in `WHERE` | Rate too high; non-matches vanish | Move it into `ON` | 1 |
| Wrong population in an experiment | Lift diluted | Restrict to who *could* convert | 2 |
| Comparing only exposed users | Program looks better than it is | Intent-to-treat | 3 |
| Sample ratio mismatch ignored | Biased comparison | Chi-square check first | 3 |
| Joining a many-rows table before summing | Spend multiplied | Aggregate per key first | 4 |
| "Last N months" from today's date | Empty result | Anchor to `MAX(date)` in the data | 4 |
| Counting events instead of entities | Inflated funnel | `COUNT(DISTINCT id)` | 5 |
| Filtering dates before `LAG` | First month has no comparison | Window first, filter after | 6 |
| Unobserved months shown as 0% | Fake retention collapse | Return NULL past the data edge | 6 |
| `AVG` silently skipping NULLs | Average too high | `AVG(COALESCE(x, 0))` when missing means zero | 4 |
