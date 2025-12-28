from __future__ import annotations

import pandas as pd

from .schema import normalize_daily_bars_frame


def invert_daily_bars(df: pd.DataFrame, *, inverted_market_code: str) -> pd.DataFrame:
    """Invert an OHLCV series.

    If the input series is QUOTE per BASE (e.g., BTC per ETH for ETH-BTC),
    the inverted series is BASE per QUOTE (e.g., ETH per BTC for BTC-ETH).

    Inversion rules:
    - price: p' = 1 / p
    - OHLC: open' = 1/open, close' = 1/close, high' = 1/low, low' = 1/high
    - volume: approximate base volume for inverted market as volume' = volume * close
      (Coinbase candle volume is in base units of the original market.)
    """

    out = normalize_daily_bars_frame(df)

    inv = out.copy()

    inv_open = 1.0 / inv["open"]
    inv_close = 1.0 / inv["close"]
    inv_high = 1.0 / inv["low"]
    inv_low = 1.0 / inv["high"]

    inv["open"] = inv_open
    inv["close"] = inv_close
    inv["high"] = inv_high
    inv["low"] = inv_low

    inv["volume"] = inv["volume"] * out["close"]
    inv["market"] = inverted_market_code

    inv = normalize_daily_bars_frame(inv)
    inv = inv.sort_values(["market", "date", "source"], kind="stable").reset_index(drop=True)
    return inv
