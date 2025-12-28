from __future__ import annotations

import datetime as dt

import pandas as pd

from .markets import Market
from .schema import filter_by_date, normalize_daily_bars_frame


def aggregate_sources(
    frames: list[pd.DataFrame],
    market: Market,
    start: dt.date,
    end: dt.date,
    *,
    policy: str,
    source_priority: list[str],
) -> pd.DataFrame:
    """Unify multiple provider series into one series.

    The core of the application consumes the unified output as if it were a single source.

    Policies:
      - "priority": for each date, take the first non-null close in source_priority order.
      - "median_close": for each date, take the median close across available sources.

    Notes:
      - This intentionally operates primarily on the `close` field.
      - For `priority`, if a chosen source has OHLC, those fields are carried through.
      - For `median_close`, `open/high/low` are left as NaN unless exactly one source supplies them.
    """

    if not frames:
        return pd.DataFrame(columns=["date", "open", "high", "low", "close", "volume", "market", "source"])

    all_df = pd.concat([f for f in frames if not f.empty], ignore_index=True)
    if all_df.empty:
        return all_df

    all_df = normalize_daily_bars_frame(all_df)
    all_df = filter_by_date(all_df, start, end)

    market_code = market.code
    all_df = all_df.loc[all_df["market"] == market_code].copy()

    if policy == "priority":
        # Pivot by source, select by priority.
        by_date = []
        for date, group in all_df.groupby("date", sort=True):
            chosen = None
            for src in source_priority:
                cand = group.loc[group["source"] == src]
                if cand.empty:
                    continue
                close = cand.iloc[0]["close"]
                if pd.isna(close):
                    continue
                chosen = cand.iloc[0]
                break
            if chosen is None:
                continue
            by_date.append(
                {
                    "date": date,
                    "open": chosen["open"],
                    "high": chosen["high"],
                    "low": chosen["low"],
                    "close": chosen["close"],
                    "volume": chosen["volume"],
                    "market": market_code,
                    "source": f"agg({policy})",
                }
            )
        out = pd.DataFrame(by_date)
        return normalize_daily_bars_frame(out) if not out.empty else out

    if policy == "median_close":
        by_date = []
        for date, group in all_df.groupby("date", sort=True):
            closes = pd.to_numeric(group["close"], errors="coerce").dropna()
            if closes.empty:
                continue
            close = float(closes.median())

            # If exactly one row has non-null OHLC, carry it through.
            ohlc_non_null = group.dropna(subset=["open", "high", "low"])  # type: ignore[arg-type]
            if len(ohlc_non_null) == 1:
                row = ohlc_non_null.iloc[0]
                open_ = row["open"]
                high = row["high"]
                low = row["low"]
            else:
                open_ = pd.NA
                high = pd.NA
                low = pd.NA

            by_date.append(
                {
                    "date": date,
                    "open": open_,
                    "high": high,
                    "low": low,
                    "close": close,
                    "volume": pd.NA,
                    "market": market_code,
                    "source": f"agg({policy})",
                }
            )
        out = pd.DataFrame(by_date)
        return normalize_daily_bars_frame(out) if not out.empty else out

    raise ValueError(f"Unknown aggregation policy: {policy}")
