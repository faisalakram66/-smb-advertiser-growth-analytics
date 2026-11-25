# Case 6: Are advertisers sticking around, and can we spot who's about to leave?

**SQL:** [`sql/06_retention_and_risk.sql`](../sql/06_retention_and_risk.sql)

## Business questions
1. What does monthly retention look like by signup cohort?
2. Who stopped spending, and did our CRM lifecycle label see it coming?

## Part 1: Cohort retention
% of each signup cohort active 1, 2 and 3 months after signing up.

| Signup cohort | Size | Month 1 | Month 2 | Month 3 |
|---|---|---|---|---|
| Jun 2024 | 23 | 91.3% | 82.6% | 82.6% |
| Jul 2024 | 25 | 92.0% | 88.0% | 84.0% |
| Aug 2024 | 26 | 96.2% | 73.1% | 80.8% |
| Sep 2024 | 16 | 100.0% | 87.5% | 87.5% |
| Oct 2024 | 30 | 96.7% | 93.3% | *not yet observable* |

**The trap:** a naive query reports **0.0%** for the October cohort at month 3. That month (January 2025) simply isn't in the data yet. The query returns a blank instead of a misleading zero.

**Reading it:** retention is strong (above 80% at month 3 for every complete cohort). August dips at month 2 and then recovers, a sign that some advertisers pause and come back rather than leave.

## Part 2: Who went dark?
Advertisers whose spend fell 50% or more versus their own previous month.

| Month | Spending last month | Dropped 50%+ | Went to $0 | Drop rate |
|---|---|---|---|---|
| Sep 2024 | 66 | 6 | 6 | 9.1% |
| Oct 2024 | 82 | 13 | 13 | 15.9% |
| Nov 2024 | 102 | 11 | 11 | 10.8% |
| Dec 2024 | 105 | 13 | 13 | 12.4% |

Every drop in this data is a full stop to $0, not a gradual slowdown.

**SQL note:** `LAG` runs over the full history first, and the month filter is applied afterwards. Filtering first would leave September with no previous month to compare against, hiding its drops.

## Part 3: Did the lifecycle label predict December drop-offs?

| Lifecycle label | Spending in Nov | Dropped in Dec | Drop rate |
|---|---|---|---|
| **Growing** | 24 | **6** | **25.0%** |
| At Risk | 13 | 2 | 15.4% |
| Activated | 24 | 3 | 12.5% |
| New | 18 | 1 | 5.6% |
| Mature | 26 | 1 | 3.8% |

**Advertisers labeled "Growing" had the highest drop rate**, higher than "At Risk". The CRM label doesn't predict who stops spending, so it shouldn't be used alone to target retention outreach.

## Part 4: Do they come back?

| Went dark | Came back next month | Too recent to tell |
|---|---|---|
| 49 | **29** | 13 |

Of the 36 drops we can follow up on, **29 (81%) came back the next month.** Most "drops" are pauses, not churn.

## What it means
- A one-month drop is a weak churn signal: 4 out of 5 come back on their own.
- A better at-risk definition: **two consecutive months at $0**, or a drop combined with other signals (falling clicks, support contacts).
- The lifecycle label needs recalibrating against actual behavior.

## Next step
Build a behavior-based risk score, validate it on past months (did flagged advertisers actually leave?), and only then test a retention program against a holdout. Otherwise we'd spend effort on advertisers who were coming back anyway.
