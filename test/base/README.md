# Base

stETH/BOM5 was retired. A constituent Chainlink feed is dead, so `latestAnswer` reverts stale. The aggregator, its tests, and the leftover Base feed libraries were discarded; do not re-add a live-check that expects this market to price.
