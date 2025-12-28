import datetime as dt
import pathlib

import numpy as np
import pandas as pd

from offchain_feeds.cli import main
from offchain_feeds.storage.parquet_store import ParquetStore


def test_cli_stats_return_fit_writes_plot_and_buckets(tmp_path: pathlib.Path, capsys) -> None:
    root = tmp_path / "root"
    store = ParquetStore(root)

    n = 220
    start = dt.date(2024, 1, 1)
    dates = [start + dt.timedelta(days=i) for i in range(n)]

    rng = np.random.default_rng(0)
    log_rets = rng.standard_normal(n) * 0.01
    closes = 100.0 * np.exp(np.cumsum(log_rets))

    df = pd.DataFrame(
        {
            "date": dates,
            "open": closes,
            "high": closes * 1.01,
            "low": closes * 0.99,
            "close": closes,
            "volume": np.full(n, 1.0),
            "market": ["AAA-BBB"] * n,
            "source": ["test"] * n,
        }
    )

    store.write_market("AAA-BBB", df, meta={"market": "AAA-BBB"})

    plot_path = root / "plots" / "aaa-bbb.png"
    rc = main(
        [
            "stats",
            "--market",
            "AAA-BBB",
            "--root",
            str(root),
            "--measure",
            "return_fit",
            "--top",
            "10",
            "--return-kind",
            "log",
            "--dist",
            "t",
            "--buckets",
            "-vv",
            "--side",
            "both",
            "--plot",
            str(plot_path),
        ]
    )
    assert rc == 0
    assert plot_path.exists()

    out = capsys.readouterr().out
    assert "MODEL PARAMETERS" in out
    assert "MOST SURPRISING DAYS" in out
    assert "GARCH(1,1)" in out
    assert "sigma" in out
    assert "p_two_sided" in out
    assert "COLUMN MEANINGS" in out
