import datetime as dt
import pathlib

import pandas as pd
import pytest

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


    def test_cli_export_inverts_when_requested_market_missing(tmp_path: pathlib.Path) -> None:
        root = tmp_path / "root"
        store = ParquetStore(root)

        df = pd.DataFrame(
            [
                {
                    "date": dt.date(2025, 1, 1),
                    "open": 2.0,
                    "high": 4.0,
                    "low": 1.0,
                    "close": 2.0,
                    "volume": 10.0,
                    "market": "ETH-BTC",
                    "source": "test",
                }
            ]
        )
        store.write_market("ETH-BTC", df, meta={"market": "ETH-BTC"})

        rc = main(
            [
                "export",
                "--market",
                "BTC-ETH",
                "--root",
                str(root),
                "--format",
                "csv",
            ]
        )
        assert rc == 0

        out_csv = root / "exports" / "csv" / "BTC-ETH.csv"
        assert out_csv.exists()

        exported = pd.read_csv(out_csv)
        assert exported.iloc[0]["market"] == "BTC-ETH"
        assert float(exported.iloc[0]["close"]) == pytest.approx(0.5)
