from __future__ import annotations

import datetime as dt


def parse_date(value: str) -> dt.date:
    try:
        return dt.date.fromisoformat(value)
    except ValueError as exc:
        raise ValueError(f"Invalid date '{value}'. Expected YYYY-MM-DD.") from exc


def date_range_inclusive(start: dt.date, end: dt.date) -> tuple[dt.date, dt.date]:
    if end < start:
        raise ValueError(f"End date {end} is before start date {start}.")
    return start, end
