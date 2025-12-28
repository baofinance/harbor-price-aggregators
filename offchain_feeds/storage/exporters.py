from __future__ import annotations

import json
import pathlib

import pandas as pd

from ..schema import normalize_daily_bars_frame


def export_csv(path: pathlib.Path, df: pd.DataFrame) -> pathlib.Path:
    out = normalize_daily_bars_frame(df)
    path.parent.mkdir(parents=True, exist_ok=True)
    out.to_csv(path, index=False)
    return path


def export_json(path: pathlib.Path, df: pd.DataFrame) -> pathlib.Path:
    out = normalize_daily_bars_frame(df)
    path.parent.mkdir(parents=True, exist_ok=True)
    records = out.to_dict(orient="records")
    path.write_text(json.dumps(records, indent=2, default=str) + "\n")
    return path
