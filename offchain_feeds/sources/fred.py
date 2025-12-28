from __future__ import annotations

import datetime as dt
import io

import pandas as pd

from ..markets import Market
from ..schema import filter_by_date, normalize_daily_bars_frame
from .base import SourceAdapter


class Fred(SourceAdapter):
    name = "fred"

    _BASE_URL = "https://fred.stlouisfed.org/graph/fredgraph.csv"

    _SERIES_BY_MARKET: dict[str, str] = {
        # EURUSD (USD per 1 EUR)
        "EUR-USD": "DEXUSEU",
        # Gold price (USD per troy ounce), effectively XAUUSD close-only
        "XAU-USD": "GOLDAMGBD228NLBM",
    }

    def fetch_daily_bars(self, market: Market, start: dt.date, end: dt.date) -> pd.DataFrame:
        series_id = self._SERIES_BY_MARKET.get(market.code)
        if series_id is None:
            raise ValueError(f"FRED does not support market {market.code}.")

        resp = self.client.get(self._BASE_URL, params={"id": series_id})
        resp.raise_for_status()

        # CSV: DATE,VALUE
        raw = pd.read_csv(io.StringIO(resp.text))
        raw.columns = [c.strip().lower() for c in raw.columns]
        if "date" not in raw.columns or series_id.lower() not in raw.columns:
            # Some exports name the value column as the series id.
            pass

        # Determine value column.
        value_col = None
        for col in raw.columns:
            if col == "date":
                continue
            value_col = col
            break
        if value_col is None:
            raise ValueError(f"Unexpected FRED CSV format for series {series_id}.")

        df = pd.DataFrame(
            {
                "date": raw["date"],
                "open": pd.NA,
                "high": pd.NA,
                "low": pd.NA,
                "close": raw[value_col],
                "volume": pd.NA,
                "market": market.code,
                "source": self.name,
            }
        )

        df = normalize_daily_bars_frame(df)
        df = filter_by_date(df, start, end)
        return df
