from __future__ import annotations

import datetime as dt

import httpx
import pandas as pd

from .aggregation import aggregate_sources
from .markets import Market
from .schema import filter_by_date, normalize_daily_bars_frame
from .sources import Coinbase, CoinGecko, Fred, SourceAdapter


def make_source(name: str, client: httpx.Client | None = None) -> SourceAdapter:
    name = name.strip().lower()
    if name == "coinbase":
        return Coinbase(client=client)
    if name == "coingecko":
        return CoinGecko(client=client)
    if name == "fred":
        return Fred(client=client)
    raise ValueError(f"Unknown source: {name}")


def extract_market(
    *,
    market: Market,
    start: dt.date,
    end: dt.date,
    sources: list[str],
    aggregation_policy: str,
) -> pd.DataFrame:
    frames: list[pd.DataFrame] = []
    source_priority: list[str] = []

    for name in sources:
        adapter = make_source(name)
        df = adapter.fetch_daily_bars(market, start, end)
        if not df.empty:
            df = normalize_daily_bars_frame(df)
            df = filter_by_date(df, start, end)
        frames.append(df)
        source_priority.append(adapter.name)

    unified = aggregate_sources(
        frames,
        market,
        start,
        end,
        policy=aggregation_policy,
        source_priority=source_priority,
    )
    return unified
