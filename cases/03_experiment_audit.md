# Case 3: Can we trust these three experiments?

**SQL:** [`sql/03_experiment_audit.sql`](../sql/03_experiment_audit.sql)

## Business question
A dashboard shows results for three product-education experiments. Before anyone acts on them, are the tests themselves valid?

## The dashboard view

| Experiment | Variant | Advertisers | Adoption | Avg "incremental" revenue | Opt-out |
|---|---|---|---|---|---|
| Advantage+ Education | Control | 17 | 17.6% | $2,541 | 0.0% |
| Advantage+ Education | Treatment | 18 | 27.8% | $3,538 | 0.0% |
| Business Messaging Nudge | Control | 22 | 40.9% | $3,729 | 0.0% |
| Business Messaging Nudge | Treatment | 14 | 14.3% | $2,416 | 0.0% |
| CAPI Onboarding | Control | 36 | 25.0% | $3,225 | 0.0% |
| CAPI Onboarding | Treatment | 13 | 15.4% | $4,185 | **15.4%** |

Taken at face value, two of three programs *hurt* adoption. The audit says to slow down.

## Check 1: Sample ratio mismatch
Each test was designed as 50/50.

| Experiment | Treatment | Control | Treatment share | Chi-square |
|---|---|---|---|---|
| **CAPI Onboarding** | 13 | 36 | **26.5%** | **10.80** |
| Business Messaging Nudge | 14 | 22 | 38.9% | 1.78 |
| Advantage+ Education | 18 | 17 | 51.4% | 0.03 |

A chi-square above 6.63 fails at the 1% level. **CAPI Onboarding fails badly** (p ≈ 0.001): something went wrong with assignment.

## Check 2: Where did the imbalance come from?

| Experiment | Variant | First assigned | Last assigned |
|---|---|---|---|
| CAPI Onboarding | Control | Sep 4 | **Oct 29** |
| CAPI Onboarding | Treatment | Sep 1 | **Oct 17** |

Treatment assignment **stopped 12 days before control**. Every advertiser who joined after Oct 17 went to control, which explains the imbalance.

## Check 3: Are the groups comparable?

| Account tier | Treatment | Control |
|---|---|---|
| Enterprise | **0** | 7 |
| Mid-Market | 3 | 9 |
| Scaled | 10 | 20 |

No Enterprise advertisers received the CAPI treatment. Any difference between arms is mixed up with the difference between account tiers.

## Check 4: The per-protocol trap

| Experiment | Treatment (everyone assigned) | Treatment (exposed only) | Control |
|---|---|---|---|
| Advantage+ Education | 27.8% | 29.4% | 17.6% |
| Business Messaging Nudge | 14.3% | 16.7% | 40.9% |
| CAPI Onboarding | 15.4% | 16.7% | 25.0% |

Dropping the few treatment advertisers who were never exposed makes every program look slightly better. The fair comparison is **everyone assigned** (intent-to-treat), because exposure isn't random.

## Verdict

| Experiment | Verdict | Why |
|---|---|---|
| Advantage+ Education | **Valid, but tiny** | Balanced; +10 points, but only ~17 per arm |
| Business Messaging Nudge | **Inconclusive, possibly harmful** | No SRM failure, but only 14 treated; worth a larger rerun |
| CAPI Onboarding | **Invalid, don't use** | SRM, assignment stopped early, no Enterprise advertisers in treatment |

## One more red flag
The control groups show **positive "incremental" revenue** ($2,541 to $3,729). By definition, a holdout's incremental revenue should be near zero. I'd confirm how this column is calculated before quoting it to anyone.

## Next step
Rerun CAPI Onboarding with assignment **stratified by account tier** and the same enrollment window for both arms, and set the sample size in advance from the smallest lift worth detecting.
