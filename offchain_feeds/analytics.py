from __future__ import annotations

import numpy as np
import pandas as pd


def require_ohlc(df: pd.DataFrame) -> None:
    missing = df[["high", "low"]].isna().any().any()
    if missing:
        raise ValueError("Requested metric requires high/low, but dataset is missing them.")


def close_to_close_returns(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy().sort_values(["date"], kind="stable")
    out["prev_close"] = out["close"].shift(1)
    out["return"] = out["close"] / out["prev_close"] - 1
    return out.dropna(subset=["return"]).reset_index(drop=True)


def close_to_close_log_returns(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy().sort_values(["date"], kind="stable")
    out["prev_close"] = out["close"].shift(1)
    ratio = out["close"] / out["prev_close"]
    out["log_return"] = np.log(ratio)
    return out.dropna(subset=["log_return"]).reset_index(drop=True)


def intraday_range(df: pd.DataFrame) -> pd.DataFrame:
    require_ohlc(df)
    out = df.copy().sort_values(["date"], kind="stable")
    out["range"] = out["high"] / out["low"] - 1
    return out.dropna(subset=["range"]).reset_index(drop=True)


def top_n_abs(df: pd.DataFrame, col: str, n: int) -> pd.DataFrame:
    if n <= 0:
        raise ValueError("n must be > 0")
    out = df.copy()
    out["abs"] = out[col].abs()
    out = out.sort_values(["abs"], ascending=False, kind="stable").head(n)
    return out.drop(columns=["abs"]).reset_index(drop=True)
