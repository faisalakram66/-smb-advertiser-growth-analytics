"""Clean the raw practice spreadsheets into analysis-ready CSVs.

Usage:
    python scripts/clean_data.py <raw_dir> <out_dir>

The raw files are spreadsheet exports named like "Advertisers-Table_1.csv".
Cleaning steps:
  - drop the empty trailing column left by the spreadsheet export
  - convert money text ("$1,234.56") to plain numbers
  - convert month labels ("Nov-24") to the first day of the month (2024-11-01)
  - keep timestamps and dates as ISO text so any SQL engine can load them
"""
import re
import sys
from pathlib import Path

import pandas as pd

TABLES = {
    "Advertisers": "advertisers",
    "Monthly_Performance": "monthly_performance",
    "Product_Adoption": "product_adoption",
    "Product_Health": "product_health",
    "Experiments": "experiments",
    "Advertiser_Experiment": "advertiser_experiment",
    "Advertiser_Campaigns": "advertiser_campaigns",
    "Advertiser_Events": "advertiser_events",
    "Channel_Usage": "channel_usage",
    "Marketing_Touchpoints": "marketing_touchpoints",
    "Help_Center_Engagement": "help_center_engagement",
}

MONEY = re.compile(r"^-?\$-?[\d,]+(\.\d+)?$")
MONTH = re.compile(r"^[A-Z][a-z]{2}-\d{2}$")


def clean_money(series: pd.Series) -> pd.Series:
    text = series.astype("string").str.strip()
    filled = text.dropna()
    if len(filled) and filled.str.match(MONEY).all():
        return pd.to_numeric(text.str.replace(r"[$,]", "", regex=True))
    return series


def clean_month(series: pd.Series) -> pd.Series:
    text = series.astype("string").str.strip()
    filled = text.dropna()
    if len(filled) and filled.str.match(MONTH).all():
        return pd.to_datetime(text, format="%b-%y").dt.strftime("%Y-%m-%d")
    return series


def clean_table(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path, dtype=str, keep_default_na=False, na_values=[""])
    df = df.loc[:, [c for c in df.columns if c and not c.startswith("Unnamed")]]
    df.columns = [c.strip() for c in df.columns]
    for col in df.columns:
        df[col] = clean_money(df[col])
        df[col] = clean_month(df[col])
        # flags stored as money text ("$0.00" / "$1.00") become plain 0/1
        if pd.api.types.is_float_dtype(df[col]) and df[col].dropna().isin([0, 1]).all():
            df[col] = df[col].astype("Int64")
    return df


def main(raw_dir: str, out_dir: str) -> None:
    raw, out = Path(raw_dir), Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for source, target in TABLES.items():
        df = clean_table(raw / f"{source}-Table_1.csv")
        df.to_csv(out / f"{target}.csv", index=False)
        print(f"{target:<24} {len(df):>5} rows  {len(df.columns):>3} columns")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
