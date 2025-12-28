from __future__ import annotations

import datetime as dt

import pandas as pd

REQUIRED_COLUMNS = [
    "date",
    "open",
    "high",
    "low",
    "close",
    "volume",
    "market",
    "source",
]


def empty_daily_bars() -> pd.DataFrame:
    return pd.DataFrame(columns=REQUIRED_COLUMNS)


def normalize_daily_bars_frame(df: pd.DataFrame) -> pd.DataFrame:
    """Normalize a daily bars DataFrame to the canonical schema.

    - Ensures required columns exist.
    - Coerces `date` to Python `datetime.date`.
    - Sorts by date.
    """

    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    out = df.copy()

    # Ensure python dates.
    out["date"] = pd.to_datetime(out["date"], utc=True, errors="raise").dt.date

    for col in ["open", "high", "low", "close", "volume"]:
        out[col] = pd.to_numeric(out[col], errors="coerce")

    out["market"] = out["market"].astype(str)
    out["source"] = out["source"].astype(str)

    out = out.sort_values(["market", "date", "source"], kind="stable").reset_index(drop=True)

    return out


def filter_by_date(df: pd.DataFrame, start: dt.date, end: dt.date) -> pd.DataFrame:
    if df.empty:
        return df

    mask = (df["date"] >= start) & (df["date"] <= end)
    return df.loc[mask, :].reset_index(drop=True)
