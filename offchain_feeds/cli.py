from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import sys

import pandas as pd

from .analytics import close_to_close_log_returns, close_to_close_returns, intraday_range, top_n_abs
from .engine import extract_market
from .market_inversion import invert_daily_bars
from .markets import Market
from .return_fit import fit_return_model
from .storage.exporters import export_csv, export_json
from .storage.parquet_store import ParquetStore
from .time import parse_date


def _read_market_with_inversion(store: ParquetStore, market: Market) -> tuple[pd.DataFrame, str]:
    try:
        return store.read_market(market.code), market.code
    except FileNotFoundError:
        inv = market.inverted()
        df = store.read_market(inv.code)
        return invert_daily_bars(df, inverted_market_code=market.code), inv.code


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
        choices=["close_return", "log_return", "intraday_range", "return_fit"],
        help="Statistic to compute",
    )
    sub.add_argument("--top", type=int, default=20, help="How many rows to show")
    sub.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Increase verbosity (-v, -vv, -vvv)",
    )

    # Options for return_fit
    sub.add_argument(
        "--return-kind",
        default="log",
        choices=["simple", "log"],
        help="Which return series to fit (default: log)",
    )
    sub.add_argument(
        "--dist",
        default="auto",
        choices=["auto", "t", "nig"],
        help="Innovation distribution to fit to GARCH standardized residuals",
    )
    sub.add_argument(
        "--bucket-width",
        type=float,
        default=0.01,
        help="Bucket width in simple-return units (default: 0.01 == 1%%)",
    )
    sub.add_argument(
        "--buckets",
        action="store_true",
        help="Print the fitted 1%%-bucket histogram (plus empirical frequencies)",
    )
    sub.add_argument(
        "--bucket-prob-lt",
        action="append",
        type=float,
        default=[],
        help="Show only buckets with fitted probability <= this value (repeatable). Implies --buckets.",
    )
    sub.add_argument(
        "--tail-mass",
        action="append",
        type=float,
        default=[],
        help="Print the central return interval that leaves this two-sided tail mass outside (repeatable).",
    )
    sub.add_argument(
        "--top-by",
        default="p_two_sided",
        choices=["p_two_sided", "p_one_sided", "abs_return", "abs_z"],
        help="How to rank the top table for return_fit (default: p_two_sided)",
    )
    sub.add_argument(
        "--side",
        default="both",
        choices=["both", "up", "down"],
        help="Filter return_fit top table by return sign (default: both)",
    )
    sub.add_argument(
        "--plot",
        default=None,
        help="Write a PNG plot to this path (histograms + fitted curve)",
    )


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
        df, _read_from = _read_market_with_inversion(store, market)

        df = df.loc[df["market"] == market.code].sort_values(["date"], kind="stable").reset_index(drop=True)
        if df.empty:
            raise SystemExit(f"No data for {market.code}.")

        if args.measure == "close_return":
            r = close_to_close_returns(df)
            top = top_n_abs(r, "return", int(args.top))
            print(f"MOST EXTREME DAYS (by |return|), market={market.code}")
            print(top[["date", "close", "return"]].to_string(index=False))
            return 0

        if args.measure == "log_return":
            r = close_to_close_log_returns(df)
            top = top_n_abs(r, "log_return", int(args.top))
            print(f"MOST EXTREME DAYS (by |log_return|), market={market.code}")
            print(top[["date", "close", "log_return"]].to_string(index=False))
            return 0

        if args.measure == "intraday_range":
            rng = intraday_range(df)
            top = top_n_abs(rng, "range", int(args.top))
            print(f"LARGEST INTRADAY RANGES (by |high/low-1|), market={market.code}")
            print(top[["date", "high", "low", "range"]].to_string(index=False))
            return 0

        if args.measure == "return_fit":
            plot_path = pathlib.Path(args.plot) if args.plot is not None else None

            show_buckets = bool(args.buckets) or (len(args.bucket_prob_lt) > 0)
            meta, top, buckets_df = fit_return_model(
                df,
                return_kind=str(args.return_kind),
                innovation_family=str(args.dist),
                bucket_width=float(args.bucket_width),
                top_n=int(args.top),
                plot_path=plot_path,
                print_buckets=show_buckets,
                tail_masses=list(args.tail_mass),
            )

            if int(args.verbose) >= 1:
                print(
                    "RETURN_FIT: fits GARCH(1,1) volatility, then fits a distribution to standardized residuals z = r_model / sigma."
                )
            if int(args.verbose) >= 2:
                print(
                    "COLUMN MEANINGS (one-liners):\n"
                    "- date: day of the move\n"
                    "- close: close price on that date\n"
                    "- return: simple close-to-close return (negative = drop for that market)\n"
                    "- sigma: model's conditional daily volatility estimate\n"
                    "- z: standardized move (roughly return_model/sigma)\n"
                    "- p_one_sided: tail probability on the side it occurred (smaller = rarer)\n"
                    "- p_two_sided: tail probability in either direction (smaller = more extreme)\n"
                    "- pdf_density: curve height at that return (density, not probability)\n"
                    "- bucket_low/high: 1% return bin bounds\n"
                    "- p_bucket: probability mass of that 1% bin for that day\n"
                    "\n"
                    "p_bucket vs bucket table: p_bucket is per-day (uses that day's sigma); the bucket table's prob_fitted is the average of per-day bucket probabilities across time (a mixture over volatility regimes)."
                )
            if int(args.verbose) >= 3:
                print(
                    "Note: pdf_density is not a probability; to get a probability you must integrate over an interval (e.g. 1% buckets). AIC is only meaningful when comparing candidates (lower is better) on the same data."
                )

            print(f"MODEL PARAMETERS (JSON), market={market.code}")
            print(json.dumps(meta, indent=2, sort_keys=True, default=str))

            if args.tail_mass:
                print("TWO-SIDED TAIL-MASS CUTOFFS (central interval in simple returns)")
                for item in meta.get("two_sided_tail_mass_intervals", []):
                    p = float(item["tail_mass"])
                    lo = float(item["lower_simple"])
                    hi = float(item["upper_simple"])
                    print(f"tail_mass={p:g}: [{lo:.6g}, {hi:.6g}]  (i.e. [{lo * 100:.3f}%, {hi * 100:.3f}%])")

            top_by = str(args.top_by)
            side = str(args.side)

            if side == "down":
                top = top.loc[top["return"] < 0, :].reset_index(drop=True)
            elif side == "up":
                top = top.loc[top["return"] > 0, :].reset_index(drop=True)
            elif side == "both":
                pass
            else:
                raise AssertionError("unreachable")

            if top.empty:
                raise SystemExit(f"No rows after filtering side={side} for {market.code}.")

            if top_by == "p_two_sided":
                top = top.sort_values(["p_two_sided"], ascending=True, kind="stable").head(int(args.top))
                top_header = "smallest p_two_sided"
            elif top_by == "p_one_sided":
                top = top.sort_values(["p_one_sided"], ascending=True, kind="stable").head(int(args.top))
                top_header = "smallest p_one_sided"
            elif top_by == "abs_return":
                top = (
                    top.assign(_abs=top["return"].abs())
                    .sort_values(["_abs"], ascending=False, kind="stable")
                    .drop(columns=["_abs"])
                )
                top = top.head(int(args.top))
                top_header = "largest |return|"
            elif top_by == "abs_z":
                top = (
                    top.assign(_abs=top["z"].abs())
                    .sort_values(["_abs"], ascending=False, kind="stable")
                    .drop(columns=["_abs"])
                )
                top = top.head(int(args.top))
                top_header = "largest |z|"
            else:
                raise AssertionError("unreachable")

            print(f"MOST SURPRISING DAYS UNDER FITTED MODEL (by {top_header}, side={side}), market={market.code}")
            print(
                top[
                    [
                        "date",
                        "close",
                        "return",
                        "sigma",
                        "z",
                        "p_one_sided",
                        "p_two_sided",
                        "pdf_density",
                        "bucket_low",
                        "bucket_high",
                        "p_bucket",
                    ]
                ].to_string(index=False)
            )

            if buckets_df is not None:
                print("FITTED 1% BUCKET HISTOGRAM (prob_fitted vs prob_empirical)")

                if args.bucket_prob_lt:
                    for thr in args.bucket_prob_lt:
                        print(f"BUCKETS WITH prob_fitted <= {thr}")
                        filtered = buckets_df.loc[buckets_df["prob_fitted"] <= float(thr), :].copy()
                        filtered = filtered.sort_values(["prob_fitted"], ascending=True, kind="stable")
                        if filtered.empty:
                            print("(none)")
                        else:
                            print(
                                filtered[["bucket_low", "bucket_high", "prob_fitted", "prob_empirical"]].to_string(
                                    index=False
                                )
                            )
                else:
                    print(
                        buckets_df[["bucket_low", "bucket_high", "prob_fitted", "prob_empirical"]].to_string(
                            index=False
                        )
                    )
            return 0

        raise AssertionError("unreachable")

    if args.command == "export":
        root = pathlib.Path(args.root)
        store = ParquetStore(root)

        formats = set(args.format)
        for m in args.market:
            market = Market.parse(m)
            df, _read_from = _read_market_with_inversion(store, market)
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
        try:
            meta = store.read_market_metadata(market.code)
        except FileNotFoundError:
            inv = market.inverted()
            meta = store.read_market_metadata(inv.code)
            meta = dict(meta)
            meta["derived_from_market"] = inv.code
            meta["derived_via"] = "invert"

        if args.pretty:
            print(json.dumps(meta, indent=2, sort_keys=True))
        else:
            print(json.dumps(meta, sort_keys=True))

        return 0

    raise AssertionError("unreachable")
