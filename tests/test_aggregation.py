import datetime as dt

import pandas as pd

from offchain_feeds.aggregation import aggregate_sources
from offchain_feeds.markets import Market


def _df(rows: list[dict]) -> pd.DataFrame:
    return pd.DataFrame(rows)


def test_aggregate_priority_picks_first_available() -> None:
    market = Market.parse("ETH-USD")
    start = dt.date(2025, 1, 1)
    end = dt.date(2025, 1, 2)

    a = _df(
        [
            {
                "date": "2025-01-01",
                "open": 1,
                "high": 2,
                "low": 1,
                "close": 1.5,
                "volume": 10,
                "market": "ETH-USD",
                "source": "a",
            }
        ]
    )
    b = _df(
        [
            {
                "date": "2025-01-01",
                "open": 9,
                "high": 9,
                "low": 9,
                "close": 9,
                "volume": 9,
                "market": "ETH-USD",
                "source": "b",
            }
        ]
    )

    out = aggregate_sources([a, b], market, start, end, policy="priority", source_priority=["a", "b"])
    assert len(out) == 1
    assert float(out.iloc[0]["close"]) == 1.5


def test_aggregate_median_close() -> None:
    market = Market.parse("ETH-USD")
    start = dt.date(2025, 1, 1)
    end = dt.date(2025, 1, 1)

    a = _df(
        [
            {
                "date": "2025-01-01",
                "open": pd.NA,
                "high": pd.NA,
                "low": pd.NA,
                "close": 1.0,
                "volume": pd.NA,
                "market": "ETH-USD",
                "source": "a",
            }
        ]
    )
    b = _df(
        [
            {
                "date": "2025-01-01",
                "open": pd.NA,
                "high": pd.NA,
                "low": pd.NA,
                "close": 3.0,
                "volume": pd.NA,
                "market": "ETH-USD",
                "source": "b",
            }
        ]
    )

    out = aggregate_sources([a, b], market, start, end, policy="median_close", source_priority=["a", "b"])
    assert len(out) == 1
    assert float(out.iloc[0]["close"]) == 2.0
