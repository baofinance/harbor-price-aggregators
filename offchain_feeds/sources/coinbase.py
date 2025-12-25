from __future__ import annotations

import datetime as dt

import httpx
import pandas as pd

from ..markets import Market
from ..schema import filter_by_date, normalize_daily_bars_frame
from .base import SourceAdapter


class Coinbase(SourceAdapter):
    name = "coinbase"

    _BASE_URL = "https://api.exchange.coinbase.com"
    _MAX_CANDLES_PER_REQUEST = 300
    _GRANULARITY_SECONDS = 86400

    @staticmethod
    def _rfc3339(ts: dt.datetime) -> str:
        # Coinbase expects RFC3339; avoid microseconds.
        return ts.astimezone(dt.timezone.utc).replace(microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")

    def fetch_daily_bars(self, market: Market, start: dt.date, end: dt.date) -> pd.DataFrame:
        product_id = market.code

        url = f"{self._BASE_URL}/products/{product_id}/candles"

        # Coinbase candles endpoint returns a maximum number of rows per request.
        # With daily granularity, we page in ~300-day chunks.
        start_dt = dt.datetime.combine(start, dt.time.min, tzinfo=dt.timezone.utc)
        end_dt = dt.datetime.combine(end, dt.time.max, tzinfo=dt.timezone.utc)

        frames: list[pd.DataFrame] = []
        cursor = start_dt
        max_span = dt.timedelta(days=self._MAX_CANDLES_PER_REQUEST - 1)

        while cursor <= end_dt:
            chunk_end = min(cursor + max_span, end_dt)
            params = {
                "granularity": self._GRANULARITY_SECONDS,
                "start": self._rfc3339(cursor),
                "end": self._rfc3339(chunk_end),
            }

            resp = self.client.get(url, params=params)
            try:
                resp.raise_for_status()
            except httpx.HTTPStatusError as e:
                if e.response is not None and e.response.status_code == 404:
                    raise RuntimeError(
                        "Coinbase Exchange product not found: "
                        f"{product_id}. Coinbase uses BASE-QUOTE ids (example: ETH-BTC, not BTC-ETH)."
                    ) from e
                raise
            data = resp.json()

            # Each row: [time, low, high, open, close, volume]
            rows = []
            for item in data:
                if not isinstance(item, list) or len(item) < 6:
                    continue
                ts_s, low, high, open_, close, volume = item[:6]
                date = dt.datetime.fromtimestamp(int(ts_s), tz=dt.timezone.utc).date()
                rows.append(
                    {
                        "date": date,
                        "open": open_,
                        "high": high,
                        "low": low,
                        "close": close,
                        "volume": volume,
                        "market": market.code,
                        "source": self.name,
                    }
                )

            chunk = pd.DataFrame(rows)
            if not chunk.empty:
                chunk = normalize_daily_bars_frame(chunk)
                frames.append(chunk)

            cursor = chunk_end + dt.timedelta(seconds=1)

        if not frames:
            return pd.DataFrame([])

        df = pd.concat(frames, ignore_index=True)
        df = df.drop_duplicates(subset=["market", "date", "source"], keep="last").reset_index(drop=True)

        df = normalize_daily_bars_frame(df)
        df = filter_by_date(df, start, end)

        # Coinbase tends to return newest-first. Ensure ascending.
        df = df.sort_values(["date"], kind="stable").reset_index(drop=True)
        return df
