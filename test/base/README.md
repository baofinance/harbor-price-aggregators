# Base

stETH/BOM5 was retired. A constituent Chainlink feed is dead, so `latestAnswer` reverts stale. Unit and fork tests were discarded with the aggregator; do not re-add a live-check that expects this market to price.
