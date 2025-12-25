from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import sys

import pandas as pd

from .analytics import close_to_close_returns, intraday_range, top_n_abs
from .engine import extract_market
from .markets import Market
from .storage.exporters import export_csv, export_json
from .storage.parquet_store import ParquetStore
from .time import parse_date


def _add_extract(sub: argparse.ArgumentParser) -> None:
    sub.add_argument("--market", action="append", required=True, help="Market like ETH-USD")
    sub.add_argument(
        "--source",
        action="append",
        required=True,
        help="Source name (repeatable). Example: --source coinbase --source coingecko",
    )
    sub.add_argument("--start", required=True, help="YYYY-MM-DD")
    sub.add_argument("--end", required=True, help="YYYY-MM-DD")
    sub.add_argument(
        "--aggregation",
        default="priority",
        choices=["priority", "median_close"],
        help="How to unify multiple sources",
    )
    sub.add_argument(
        "--root",
        default="data/offchain",
        help="Data root directory (default: data/offchain)",
    )
    sub.add_argument(
        "--export",
        action="append",
        default=[],
        choices=["parquet", "csv", "json"],
        help="Optional export formats in addition to parquet (repeatable)",
    )


def _add_stats(sub: argparse.ArgumentParser) -> None:
    sub.add_argument("--market", required=True, help="Market like ETH-USD")
    sub.add_argument(
        "--root",
        default="data/offchain",
        help="Data root directory (default: data/offchain)",
    )
    sub.add_argument(
        "--measure",
        required=True,
        choices=["close_return", "intraday_range"],
        help="Statistic to compute",
    )
    sub.add_argument("--top", type=int, default=20, help="How many rows to show")


def _add_export(sub: argparse.ArgumentParser) -> None:
    sub.add_argument("--market", action="append", required=True, help="Market like ETH-USD")
    sub.add_argument("--root", default="data/offchain", help="Data root directory (default: data/offchain)")
    sub.add_argument(
        "--format",
        action="append",
        required=True,
        choices=["csv", "json"],
        help="Export format (repeatable)",
    )


def _add_meta(sub: argparse.ArgumentParser) -> None:
    sub.add_argument("--market", required=True, help="Market like ETH-USD")
    sub.add_argument("--root", default="data/offchain", help="Data root directory (default: data/offchain)")
    sub.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print JSON metadata",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="offchain-feeds")
    sub = parser.add_subparsers(dest="command", required=True)

    extract = sub.add_parser("extract", help="Download + normalize + store")
    _add_extract(extract)

    stats = sub.add_parser("stats", help="Compute basic statistics")
    _add_stats(stats)

    export = sub.add_parser("export", help="Export from stored parquet (no network)")
    _add_export(export)

    meta = sub.add_parser("meta", help="Show embedded parquet metadata")
    _add_meta(meta)

    args = parser.parse_args(argv)

    if args.command == "extract":
        start: dt.date = parse_date(args.start)
        end: dt.date = parse_date(args.end)

        root = pathlib.Path(args.root)
        store = ParquetStore(root)

        extracted_at = dt.datetime.now(tz=dt.timezone.utc).replace(microsecond=0).isoformat()

        base_meta = {
            "extracted_at_utc": extracted_at,
            "requested_start": start.isoformat(),
            "requested_end": end.isoformat(),
            "aggregation_policy": str(args.aggregation),
            "sources": list(args.source),
            "python": sys.version.split()[0],
        }

        for m in args.market:
            market = Market.parse(m)
            df = extract_market(
                market=market,
                start=start,
                end=end,
                sources=list(args.source),
                aggregation_policy=str(args.aggregation),
            )

            if df.empty:
                raise SystemExit(f"No data for {market.code}.")

            meta_for_market = dict(base_meta)
            meta_for_market["market"] = market.code
            parquet_path = store.write_market(market.code, df, meta=meta_for_market)
            print(parquet_path)

            exports = set(args.export)
            if "csv" in exports:
                export_csv(root / "exports" / "csv" / f"{market.code}.csv", df)
            if "json" in exports:
                export_json(root / "exports" / "json" / f"{market.code}.json", df)

        return 0

    if args.command == "stats":
        market = Market.parse(args.market)
        store = ParquetStore(pathlib.Path(args.root))
        df = store.read_market(market.code)

        df = df.loc[df["market"] == market.code].sort_values(["date"], kind="stable").reset_index(drop=True)
        if df.empty:
            raise SystemExit(f"No data for {market.code}.")

        if args.measure == "close_return":
            r = close_to_close_returns(df)
            top = top_n_abs(r, "return", int(args.top))
            print(top[["date", "close", "return"]].to_string(index=False))
            return 0

        if args.measure == "intraday_range":
            rng = intraday_range(df)
            top = top_n_abs(rng, "range", int(args.top))
            print(top[["date", "high", "low", "range"]].to_string(index=False))
            return 0

        raise AssertionError("unreachable")

    if args.command == "export":
        root = pathlib.Path(args.root)
        store = ParquetStore(root)

        formats = set(args.format)
        for m in args.market:
            market = Market.parse(m)
            df = store.read_market(market.code)
            df = df.loc[df["market"] == market.code].sort_values(["date"], kind="stable").reset_index(drop=True)
            if df.empty:
                raise SystemExit(f"No data for {market.code}.")

            if "csv" in formats:
                path = export_csv(root / "exports" / "csv" / f"{market.code}.csv", df)
                print(path)
            if "json" in formats:
                path = export_json(root / "exports" / "json" / f"{market.code}.json", df)
                print(path)

        return 0

    if args.command == "meta":
        market = Market.parse(args.market)
        store = ParquetStore(pathlib.Path(args.root))
        meta = store.read_market_metadata(market.code)

        if args.pretty:
            print(json.dumps(meta, indent=2, sort_keys=True))
        else:
            print(json.dumps(meta, sort_keys=True))

        return 0

    raise AssertionError("unreachable")
