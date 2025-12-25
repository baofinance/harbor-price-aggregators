import datetime as dt
import pathlib

import pandas as pd

from offchain_feeds.cli import main
from offchain_feeds.storage.parquet_store import ParquetStore


def test_parquet_embedded_metadata_roundtrips(tmp_path: pathlib.Path) -> None:
    root = tmp_path / "root"
    store = ParquetStore(root)

    df = pd.DataFrame(
        [
            {
                "date": dt.date(2025, 1, 1),
                "open": 1,
                "high": 2,
                "low": 0.5,
                "close": 1.5,
                "volume": 10,
                "market": "BTC-USD",
                "source": "coinbase",
            }
        ]
    )

    meta = {
        "market": "BTC-USD",
        "requested_start": "2025-01-01",
        "requested_end": "2025-01-01",
        "sources": ["coinbase"],
    }

    store.write_market("BTC-USD", df, meta=meta)
    got = store.read_market_metadata("BTC-USD")
    assert got["market"] == "BTC-USD"
    assert got["sources"] == ["coinbase"]


def test_cli_meta_reads_embedded_metadata(tmp_path: pathlib.Path) -> None:
    root = tmp_path / "root"
    store = ParquetStore(root)

    df = pd.DataFrame(
        [
            {
                "date": dt.date(2025, 1, 1),
                "open": 1,
                "high": 2,
                "low": 0.5,
                "close": 1.5,
                "volume": 10,
                "market": "BTC-USD",
                "source": "coinbase",
            }
        ]
    )
    store.write_market("BTC-USD", df, meta={"market": "BTC-USD", "sources": ["coinbase"]})

    rc = main(["meta", "--market", "BTC-USD", "--root", str(root)])
    assert rc == 0
