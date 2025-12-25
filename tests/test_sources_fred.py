import datetime as dt

import httpx

from offchain_feeds.markets import Market
from offchain_feeds.sources.fred import Fred


def test_fred_parses_csv_close_only() -> None:
    market = Market.parse("EUR-USD")

    csv = "DATE,DEXUSEU\n2025-01-01,1.10\n2025-01-02,1.11\n"

    def handler(request: httpx.Request) -> httpx.Response:
        assert "fredgraph.csv" in str(request.url)
        return httpx.Response(200, content=csv.encode(), headers={"Content-Type": "text/csv"})

    client = httpx.Client(transport=httpx.MockTransport(handler))
    src = Fred(client=client)

    df = src.fetch_daily_bars(market, dt.date(2025, 1, 1), dt.date(2025, 1, 2))
    assert len(df) == 2
    assert df.iloc[0]["market"] == "EUR-USD"
    assert df.iloc[0]["source"] == "fred"
    assert df["close"].notna().all()
