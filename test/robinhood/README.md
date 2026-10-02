# Robinhood tests

Feed constants: `test/feeds/robinhood/RobinhoodUsdFeeds.t.sol` (standard proxy + 86400 heartbeat for every USD library, including USDG). That file does not mock and does not call the chain.

Wired unit tests: `Aggregator_<base>_<quote>_robinhood.t.sol` — these etch mocks at the documented addresses so CI can run without an RPC. They are not fork tests.

Fork tests (`*Fork.t.sol`) never mock: they read the documented Chainlink proxies on the live Robinhood fork. syrupUSDG/USD uses `SYRUPUSDG_USDG` (rate) × `USDG_USD` (price).

## Fork tests

Requires `ROBINHOOD_RPC_URL` in `.env` (`foundry.toml` alias `robinhood`). An unset URL fails the suite; it does not skip.

```bash
# All Robinhood fork suites (feeds + syrupUSDG aggregator)
forge test --match-path "test/robinhood/*Fork*.t.sol" -vv

# Equity + USDG Chainlink feeds only (reverts if a feed is stale)
forge test --match-path test/robinhood/RobinhoodUsdFeedsFork.t.sol -vv

# Live syrupUSDG/USD aggregator (Chainlink rate × USDG/USD)
forge test --match-path test/robinhood/Aggregator_syrupUSDG_USD_robinhoodFork.t.sol -vv
```

`--fork-url robinhood` is optional: `RobinhoodForkTest` reads `ROBINHOOD_RPC_URL` in `setUp` when the process is not already on chain 4663.
