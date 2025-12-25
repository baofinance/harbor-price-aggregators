import datetime as dt
import json

import httpx
import pytest

from offchain_feeds.markets import Market
from offchain_feeds.sources.coingecko import CoinGecko


def test_coingecko_parses_prices_close_only() -> None:
    market = Market.parse("ETH-USD")

    payload = {
        "prices": [
            [1735689600000, 3500.0],
            [1735776000000, 3600.0],
        ]
    }

    def handler(request: httpx.Request) -> httpx.Response:
        assert "/coins/ethereum/market_chart" in str(request.url)
        return httpx.Response(200, content=json.dumps(payload).encode(), headers={"Content-Type": "application/json"})

    client = httpx.Client(transport=httpx.MockTransport(handler))
    src = CoinGecko(client=client)

    df = src.fetch_daily_bars(market, dt.date(2025, 1, 1), dt.date(2025, 1, 3))
    assert len(df) == 2
    assert df.iloc[0]["market"] == "ETH-USD"
    assert df.iloc[0]["source"] == "coingecko"
    assert df["close"].notna().all()


def test_coingecko_mcap_uses_market_cap_chart() -> None:
    market = Market.parse("MCAP-USD")

    payload = {
        "market_cap": [
            [1735689600000, 1.0e12],
            [1735776000000, 1.1e12],
        ]
    }

    def handler(request: httpx.Request) -> httpx.Response:
        assert "/global/market_cap_chart" in str(request.url)
        return httpx.Response(200, content=json.dumps(payload).encode(), headers={"Content-Type": "application/json"})

    client = httpx.Client(transport=httpx.MockTransport(handler))
    src = CoinGecko(client=client)

    df = src.fetch_daily_bars(market, dt.date(2025, 1, 1), dt.date(2025, 1, 2))
    assert len(df) == 2
    assert df.iloc[0]["market"] == "MCAP-USD"


def test_coingecko_includes_api_key_when_set(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("COINGECKO_API_KEY", "demo-key")
    market = Market.parse("BTC-USD")

    payload = {
        "prices": [
            [1735689600000, 42000.0],
        ]
    }

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.params.get("x_cg_demo_api_key") == "demo-key"
        return httpx.Response(200, content=json.dumps(payload).encode(), headers={"Content-Type": "application/json"})

    client = httpx.Client(transport=httpx.MockTransport(handler))
    src = CoinGecko(client=client)
    df = src.fetch_daily_bars(market, dt.date(2025, 1, 1), dt.date(2025, 1, 1))
    assert len(df) == 1
