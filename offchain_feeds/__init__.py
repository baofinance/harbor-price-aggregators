"""Off-chain market data extractor + analytics.

Primary entrypoint is the CLI:

    python -m offchain_feeds --help
"""

from .markets import Market

__all__ = ["Market"]
