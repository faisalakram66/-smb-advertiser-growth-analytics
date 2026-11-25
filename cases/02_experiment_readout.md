# Case 2: Did the Advantage+ education email work?

**SQL:** [`sql/02_experiment_readout.sql`](../sql/02_experiment_readout.sql)

## Business question
120 advertisers were randomly split: 60 received an Advantage+ education email (treatment), 60 received nothing (holdout). Did the email **cause** more advertisers to adopt Advantage+ within 14 days, and what did it cost in opt-outs and complaints?

## How I framed it

| Step | Answer |
|---|---|
| **Grain** | One row per variant |
| **Everyone** | Advertisers who were **eligible and had not already adopted** at baseline. Nobody else can adopt |
| **Yes** | `adopted_14d = 1` |
| **Primary metric** | 14-day adoption rate, intent-to-treat (everyone assigned, opened or not) |
| **Guardrails** | Opt-out rate, complaint rate |

## Validity checks before reading results
| Variant | Advertisers | Emails delivered |
|---|---|---|
| Holdout | 60 | 0 |
| Treatment | 60 | 59 |

Sample ratio chi-square: **0.00** (perfect 60/60). The holdout received nothing, and delivery in treatment was 98%. The test is clean enough to read.

## The population matters
| Population | Treatment | Holdout |
|---|---|---|
| All 120 advertisers | 23.3% | 6.7% |
| **Eligible non-adopters (68)** | **41.2%** | **11.8%** |

Including advertisers who were ineligible or had *already* adopted dilutes the result, because they could never adopt in the first place.

## Primary result

| | Treatment | Holdout |
|---|---|---|
| Advertisers | 34 | 34 |
| Adopted in 14 days | 14 | 4 |
| **Adoption rate** | **41.2%** | **11.8%** |

- **Lift: +29.4 percentage points** (about 3.5× the holdout rate, or +250% relative)
- **z = 2.75** (two-sided p ≈ 0.006)
- **95% confidence interval: +9.6 to +49.2 points**

## Guardrails and secondary outcomes

| Variant | Opt-out | Complaints | Active at day 60 | Active at day 90 | Avg pre-period spend | Avg spend change |
|---|---|---|---|---|---|---|
| Holdout | 0.0% | 0.0% | 11.8% | 11.8% | $9,732 | −$146 |
| Treatment | **5.9%** | 0.0% | 29.4% | 26.5% | $10,868 | +$26 |

## Economics
- **294 incremental adopters per 1,000 emails**
- At $3.50 per email, about **$11.90 per incremental adopter**

## What it means
The email clearly drove adoption: the effect is large, statistically significant, and still positive at the bottom of the confidence interval. It's also cheap. The cost is a **5.9% opt-out rate** (2 of 34 advertisers) versus none in the holdout. Losing the ability to email an advertiser has a long-term cost, so this needs watching as the program scales.

## Caveats
- **Wide interval.** With 34 advertisers per arm, the true lift could be anywhere from about 10 to 49 points. Use the low end for planning.
- **Spend started unbalanced.** Treatment advertisers spent about $1,100 more per month *before* the test, so I compare spend **changes**, not levels. Even then, the spend difference is small and noisy, so I don't claim a revenue effect.
- 14-day adoption is a leading indicator. Activity at day 60 and 90 is encouraging, but adoption that sticks is what matters.

## Recommendation
**Scale, carefully.** Roll out in stages with a 10% holdout kept permanently, keep opt-out rate as a guardrail with a threshold agreed in advance, and test a softer message to see if the lift holds with fewer opt-outs.
