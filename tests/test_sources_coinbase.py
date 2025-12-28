import datetime as dt
import json

import httpx
import pytest

from offchain_feeds.markets import Market
from offchain_feeds.sources.coinbase import Coinbase


def test_coinbase_parses_daily_candles() -> None:
    market = Market.parse("ETH-USD")

    # Coinbase candles: [time, low, high, open, close, volume]
    payload = [
        [1735689600, 90, 110, 95, 105, 123],
        [1735603200, 80, 120, 100, 100, 456],
    ]

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/products/ETH-USD/candles")
        body = json.dumps(payload).encode()
        return httpx.Response(200, content=body, headers={"Content-Type": "application/json"})

    transport = httpx.MockTransport(handler)
    client = httpx.Client(transport=transport)
    src = Coinbase(client=client)

    df = src.fetch_daily_bars(market, dt.date(2024, 12, 31), dt.date(2025, 1, 2))
    assert list(df.columns)
    assert df.iloc[0]["market"] == "ETH-USD"
    assert df.iloc[0]["source"] == "coinbase"
    assert len(df) == 2
    # Ensure sorted ascending by date
    assert df.iloc[0]["date"] < df.iloc[1]["date"]


def test_coinbase_pages_long_ranges() -> None:
    market = Market.parse("BTC-USD")

    # Force chunking: >300 days.
    start = dt.date(2020, 1, 1)
    end = dt.date(2021, 2, 5)  # 402 days inclusive

    calls: list[tuple[str, str]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/products/BTC-USD/candles")
        qs = request.url.params
        calls.append((qs.get("start", ""), qs.get("end", "")))

        # Return one candle per request with distinct days.
        if len(calls) == 1:
            payload = [[1577836800, 1, 2, 1.5, 1.7, 10]]  # 2020-01-01
        else:
            payload = [[1612483200, 3, 4, 3.2, 3.8, 20]]  # 2021-02-05

        body = json.dumps(payload).encode()
        return httpx.Response(200, content=body, headers={"Content-Type": "application/json"})

    transport = httpx.MockTransport(handler)
    client = httpx.Client(transport=transport)
    src = Coinbase(client=client)

    df = src.fetch_daily_bars(market, start, end)
    assert len(calls) >= 2
    assert len(df) == 2
    assert df.iloc[0]["date"] < df.iloc[1]["date"]


def test_coinbase_404_has_actionable_error() -> None:
    market = Market.parse("FOO-BAR")

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path.endswith("/products/FOO-BAR/candles") or request.url.path.endswith("/products/BAR-FOO/candles")
        return httpx.Response(404, content=b"not found")

    transport = httpx.MockTransport(handler)
    client = httpx.Client(transport=transport)
    src = Coinbase(client=client)

    with pytest.raises(RuntimeError, match=r"BASE-QUOTE"):
        src.fetch_daily_bars(market, dt.date(2025, 1, 1), dt.date(2025, 1, 2))


def test_coinbase_inverts_market_when_only_inverse_exists() -> None:
    market = Market.parse("BTC-ETH")

    # BTC-ETH missing, ETH-BTC exists.
    payload = [
        # time, low, high, open, close, volume (volume in base units, here ETH)
        [1735689600, 0.01, 0.02, 0.0125, 0.015, 100],
    ]

    calls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.url.path)
        if request.url.path.endswith("/products/BTC-ETH/candles"):
            return httpx.Response(404, content=b"not found")
        if request.url.path.endswith("/products/ETH-BTC/candles"):
            return httpx.Response(200, json=payload)
        return httpx.Response(500)

    transport = httpx.MockTransport(handler)
    client = httpx.Client(transport=transport)
    src = Coinbase(client=client)

    df = src.fetch_daily_bars(market, dt.date(2025, 1, 1), dt.date(2025, 1, 1))
    assert calls[0].endswith("/products/BTC-ETH/candles")
    assert any(p.endswith("/products/ETH-BTC/candles") for p in calls)

    row = df.iloc[0]
    assert row["market"] == "BTC-ETH"
    assert row["close"] == pytest.approx(1.0 / 0.015)
    # Inversion must flip high/low
    assert row["high"] == pytest.approx(1.0 / 0.01)
    assert row["low"] == pytest.approx(1.0 / 0.02)
