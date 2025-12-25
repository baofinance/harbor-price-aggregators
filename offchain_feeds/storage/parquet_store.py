from __future__ import annotations

import json
import pathlib
from typing import Any

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

from ..schema import normalize_daily_bars_frame


class ParquetStore:
    def __init__(self, root: pathlib.Path):
        self.root = root

    def path_for_market(self, market_code: str) -> pathlib.Path:
        return self.root / "daily" / f"{market_code}.parquet"

    def write_market(self, market_code: str, df: pd.DataFrame, meta: dict[str, Any] | None = None) -> pathlib.Path:
        out = normalize_daily_bars_frame(df)
        path = self.path_for_market(market_code)
        path.parent.mkdir(parents=True, exist_ok=True)

        table = pa.Table.from_pandas(out, preserve_index=False)

        md = dict(table.schema.metadata or {})
        md[b"offchain_feeds.schema_version"] = b"1"
        if meta is not None:
            md[b"offchain_feeds.meta"] = json.dumps(meta, sort_keys=True, default=str).encode("utf-8")
        table = table.replace_schema_metadata(md)

        pq.write_table(table, path, compression="snappy")
        return path

    def read_market(self, market_code: str) -> pd.DataFrame:
        path = self.path_for_market(market_code)
        return pd.read_parquet(path)

    def read_market_metadata(self, market_code: str) -> dict[str, Any]:
        path = self.path_for_market(market_code)
        pf = pq.ParquetFile(path)
        schema = pf.schema_arrow
        md = dict(schema.metadata or {})

        raw = md.get(b"offchain_feeds.meta")
        if raw is None:
            return {}

        try:
            return json.loads(raw.decode("utf-8"))
        except Exception:
            return {"raw": raw.decode("utf-8", errors="replace")}
