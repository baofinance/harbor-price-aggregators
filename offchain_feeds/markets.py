from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Market:
    """Normalized market identifier.

    Example:
        base="ETH", quote="USD" -> "ETH-USD"

    The intent is to keep this independent of any provider's symbol scheme.
    """

    base: str
    quote: str

    @property
    def code(self) -> str:
        return f"{self.base.upper()}-{self.quote.upper()}"

    def inverted(self) -> "Market":
        return Market(base=self.quote, quote=self.base)

    @staticmethod
    def parse(value: str) -> "Market":
        value = value.strip()
        if "-" not in value:
            raise ValueError(f"Invalid market '{value}'. Expected like 'ETH-USD'.")
        base, quote = value.split("-", 1)
        base = base.strip().upper()
        quote = quote.strip().upper()
        if not base or not quote:
            raise ValueError(f"Invalid market '{value}'. Expected like 'ETH-USD'.")
        return Market(base=base, quote=quote)
