from __future__ import annotations

import datetime as dt
import os

import pandas as pd
from httpx import HTTPStatusError

from ..markets import Market
from ..schema import filter_by_date, normalize_daily_bars_frame
from .base import SourceAdapter


class CoinGecko(SourceAdapter):
    name = "coingecko"

    _BASE_URL = "https://api.coingecko.com/api/v3"

    # CoinGecko's "Demo" API now commonly requires an API key.
    # We support supplying it via env var to keep CLI surface minimal.
    _ENV_API_KEY = "COINGECKO_API_KEY"

    # Minimal mappings for initial implementation; extend as needed.
    _COIN_ID_BY_MARKET: dict[str, str] = {
        "BTC-USD": "bitcoin",
        "ETH-USD": "ethereum",
        "USDC-USD": "usd-coin",
        "STETH-USD": "staked-ether",
    }

    def __init__(self, client=None):
        super().__init__(client=client)
        self._api_key = os.getenv(self._ENV_API_KEY)

    def _auth_params_and_headers(self) -> tuple[dict[str, str], dict[str, str]]:
        if not self._api_key:
            return {}, {}

        # CoinGecko docs show query param form for demo API.
        params = {"x_cg_demo_api_key": self._api_key}
        # Also send the header form for compatibility.
        headers = {"x-cg-demo-api-key": self._api_key}
        return params, headers

    def fetch_daily_bars(self, market: Market, start: dt.date, end: dt.date) -> pd.DataFrame:
        code = market.code

        if code == "MCAP-USD":
            return self._fetch_global_mcap_usd(start, end)

        coin_id = self._COIN_ID_BY_MARKET.get(code)
        if coin_id is None and code == "STETH-ETH":
            coin_id = "staked-ether"

        if coin_id is None:
            raise ValueError(f"CoinGecko does not support market {code}.")

        vs = market.quote.lower()

        # Use market_chart with daily interval for close-only.
        url = f"{self._BASE_URL}/coins/{coin_id}/market_chart"
        params = {
            "vs_currency": vs,
            "days": "max",
            "interval": "daily",
        }

        auth_params, auth_headers = self._auth_params_and_headers()
        params.update(auth_params)

        try:
            resp = self.client.get(url, params=params, headers=auth_headers or None)
            resp.raise_for_status()
        except HTTPStatusError as e:
            if e.response is not None and e.response.status_code == 401 and not self._api_key:
                raise ValueError(
                    "CoinGecko returned 401 Unauthorized. Set COINGECKO_API_KEY (CoinGecko Demo API key) and retry."
                ) from e
            raise
        payload = resp.json()

        prices = payload.get("prices") or []
        rows = []
        for ts_ms, price in prices:
            date = dt.datetime.fromtimestamp(int(ts_ms) / 1000, tz=dt.timezone.utc).date()
            rows.append(
                {
                    "date": date,
                    "open": pd.NA,
                    "high": pd.NA,
                    "low": pd.NA,
                    "close": price,
                    "volume": pd.NA,
                    "market": code,
                    "source": self.name,
                }
            )

        df = pd.DataFrame(rows)
        if df.empty:
            return df

        df = normalize_daily_bars_frame(df)
        df = filter_by_date(df, start, end)
        return df

    def _fetch_global_mcap_usd(self, start: dt.date, end: dt.date) -> pd.DataFrame:
        url = f"{self._BASE_URL}/global/market_cap_chart"
        params = {
            "days": "max",
        }

        auth_params, auth_headers = self._auth_params_and_headers()
        params.update(auth_params)

        try:
            resp = self.client.get(url, params=params, headers=auth_headers or None)
            resp.raise_for_status()
        except HTTPStatusError as e:
            if e.response is not None and e.response.status_code == 401 and not self._api_key:
                raise ValueError(
                    "CoinGecko returned 401 Unauthorized. Set COINGECKO_API_KEY (CoinGecko Demo API key) and retry."
                ) from e
            raise
        payload = resp.json()

        series = payload.get("market_cap") or payload.get("market_caps") or []
        rows = []
        for ts_ms, value in series:
            date = dt.datetime.fromtimestamp(int(ts_ms) / 1000, tz=dt.timezone.utc).date()
            rows.append(
                {
                    "date": date,
                    "open": pd.NA,
                    "high": pd.NA,
                    "low": pd.NA,
                    "close": value,
                    "volume": pd.NA,
                    "market": "MCAP-USD",
                    "source": self.name,
                }
            )

        df = pd.DataFrame(rows)
        if df.empty:
            return df

        df = normalize_daily_bars_frame(df)
        df = filter_by_date(df, start, end)
        return df
