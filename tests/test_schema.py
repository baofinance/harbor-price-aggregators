import pandas as pd

from offchain_feeds.schema import normalize_daily_bars_frame


def test_normalize_daily_bars_frame_coerces_types() -> None:
    df = pd.DataFrame(
        [
            {
                "date": "2025-01-01",
                "open": "1",
                "high": "2",
                "low": "0.5",
                "close": "1.5",
                "volume": "10",
                "market": "ETH-USD",
                "source": "coinbase",
            }
        ]
    )

    out = normalize_daily_bars_frame(df)
    assert out.iloc[0]["date"].isoformat() == "2025-01-01"
    assert float(out.iloc[0]["close"]) == 1.5
