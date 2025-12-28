from __future__ import annotations

import abc
import datetime as dt

import httpx
import pandas as pd

from ..markets import Market


class SourceAdapter(abc.ABC):
    """Provider adapter interface."""

    name: str

    def __init__(self, client: httpx.Client | None = None):
        self._client = client or httpx.Client(timeout=30)

    @property
    def client(self) -> httpx.Client:
        return self._client

    @abc.abstractmethod
    def fetch_daily_bars(self, market: Market, start: dt.date, end: dt.date) -> pd.DataFrame:
        """Fetch and return daily bars (possibly close-only).

        Returned frame must contain canonical columns:
            date, open, high, low, close, volume, market, source

        High/low may be NaN if the provider only supplies a close series.
        """

        raise NotImplementedError
