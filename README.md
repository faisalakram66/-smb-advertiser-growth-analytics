# SMB Advertiser Growth Analytics

**Six SQL case studies on how small businesses adopt, launch, and keep using ad products, from opportunity sizing to experiment readouts.**

Self-serve ad platforms serve millions of small businesses that never talk to a sales rep. Growing that base means answering the same questions over and over: *Who hasn't adopted the product yet? Did our program actually cause adoption? Where do advertisers get stuck? Who's about to leave?*

This project answers those questions on a synthetic dataset of 120 advertisers, using PostgreSQL. Each case starts from a business question, shows the SQL, reports real results, and ends with a recommendation and its caveats. Every case also highlights one analysis mistake that would have produced a confident but wrong answer.

> **Data note:** all data is synthetic and created for practice. Product names (Advantage+, Conversions API, click-to-WhatsApp) are used for realism; this project is not affiliated with or endorsed by any company.

---

## Headline findings

| # | Case | Question | Finding |
|---|---|---|---|
| 1 | [Adoption gap](cases/01_adoption_gap.md) | Where is Advantage+ adoption weakest? | True adoption is **32.7%**, not the **50.8%** a common join mistake reports. Large advertisers adopt least; Small advertisers mostly never engaged |
| 2 | [Experiment readout](cases/02_experiment_readout.md) | Did an education email cause adoption? | **+29.4 points** of 14-day adoption (41.2% vs 11.8%, z = 2.75), at about **$12 per incremental adopter**, with a 5.9% opt-out cost |
| 3 | [Experiment audit](cases/03_experiment_audit.md) | Can we trust three other tests? | One test fails a **sample ratio check** (chi-square 10.8): treatment enrollment stopped 12 days early and no Enterprise advertisers were treated |
| 4 | [Opportunity sizing](cases/04_opportunity_sizing.md) | How big is the rollout opportunity? | **68 non-adopters**, about **6 to 20** expected new adopters. **14 Large advertisers hold 46%** of the spend in scope |
| 5 | [Launch funnel](cases/05_launch_funnel.md) | Where do campaigns stall before launch? | **76%** of campaigns launch. Setup is the leakiest step, and **billing and payment** causes 37% of losses |
| 6 | [Retention and risk](cases/06_retention_and_risk.md) | Who's leaving, and can we predict it? | Retention is above 80% at month 3, but **81% of advertisers who went dark came back** the next month, and the "Growing" label had the highest drop rate |

## What this project demonstrates
- **Translating business questions into analysis:** defining the population, metric, and decision before writing SQL
- **Experimentation:** intent-to-treat readouts, lift with confidence intervals, sample ratio checks, covariate balance, guardrail metrics
- **Opportunity sizing:** combining audience size, spend, and measured lift into a planning range
- **Funnel and retention analysis:** step conversion, friction themes, cohort retention, churn signals
- **SQL:** CTEs, LEFT JOIN logic, conditional aggregation, window functions (`LAG`, `LEAD`, `ROW_NUMBER`, running totals), `ROLLUP`, percentiles
- **Validation:** reconciling totals across tables and catching the mistakes listed in [docs/approach.md](docs/approach.md)

## Repository structure
```
├── README.md
├── cases/                 # One write-up per case: question, approach, results, recommendation
├── sql/
│   ├── 00_schema.sql      # Table definitions (PostgreSQL)
│   └── 01-06_*.sql        # Case queries, commented
├── data/                  # Cleaned CSVs (11 tables)
├── scripts/
│   ├── clean_data.py      # Raw spreadsheet export -> clean CSVs
│   └── load_postgres.sh   # Create tables and load data
└── docs/
    ├── approach.md        # The routine behind every case, and mistakes it catches
    ├── sql-patterns.md    # Reusable SQL patterns, with MySQL differences
    └── data-dictionary.md # Tables, grain, and things to know before querying
```

## Run it yourself
Requires PostgreSQL 14+.

```bash
git clone https://github.com/YOUR-USERNAME/smb-advertiser-growth-analytics.git
cd smb-advertiser-growth-analytics
createdb smb_growth
bash scripts/load_postgres.sh smb_growth
psql -d smb_growth -f sql/01_adoption_gap.sql
```

## How each case is structured
1. **Business question:** what decision the analysis supports
2. **Framing:** grain, population, success definition, tables, and traps
3. **Results:** real query output
4. **What it means:** the finding in plain language
5. **Caveats:** what the data can't tell us
6. **Next step:** the test or action I'd recommend

## About me
I'm **Faisal Akram**, a growth marketing and measurement leader with 12+ years across agency, brand, and client-side advertising. I build measurement frameworks, run incrementality tests, and help businesses adopt new ad products with confidence.

[LinkedIn](https://www.linkedin.com/in/faisalakram7)
