import datetime as dt
import pathlib

import pandas as pd

from offchain_feeds.cli import main
from offchain_feeds.storage.parquet_store import ParquetStore


def test_cli_export_from_parquet(tmp_path: pathlib.Path) -> None:
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
            },
        ]
    )
    store.write_market("BTC-USD", df)

    rc = main(
        [
            "export",
            "--market",
            "BTC-USD",
            "--root",
            str(root),
            "--format",
            "csv",
            "--format",
            "json",
        ]
    )
    assert rc == 0

    assert (root / "exports" / "csv" / "BTC-USD.csv").exists()
    assert (root / "exports" / "json" / "BTC-USD.json").exists()
