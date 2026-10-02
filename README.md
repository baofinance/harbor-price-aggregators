<p align="center">
  <a href="https://www.harborfinance.io/">
    <img src="https://github.com/baofinance/harbor-app/raw/main/public/logo.svg"
         alt="Harbor Protocol - A Safer Harbor For Leverage, Uncharted Waters For Yield"
         width="480"
         style="max-width:100%; height:auto;">
  </a>
</p>

<p align="center">
  <br>
  <i>A Safer Harbor For Leverage, Uncharted Waters For Yield.</i><br>
</p>

<br>

# Harbor Price Aggregators

Price oracle aggregators for Harbor Protocol.

## Overview

The v3 aggregators use an immutable architecture: each aggregator is a concrete contract with configuration baked in at construction time. Network-specific "wiring" files (`src/Aggregator_*_mainnet.sol`) extend formula contracts (`src/aggregators/Aggregator_*.sol`) and pass chain-specific feed addresses and heartbeats to the constructor.

**Architecture highlights:**

- **Immutable configuration**: Feed addresses, heartbeats, and rate sources are constructor parameters (no `initialize()` or storage slots)
- **Heartbeat validation**: `ChainlinkFeedLib` validates feed freshness with a 42-second tolerance to account for block timing variance
- **UUPS Upgradeable**: Proxy pattern via BaoFactory with fixed owner

To add a new aggregator, see [doc/v3-aggregator-authoring-guide.md](doc/v3-aggregator-authoring-guide.md).

## Mainnet v3 Aggregators

| Pair         | Oracle | Rate Source                 | Feeds |
| ------------ | ------ | --------------------------- | ----- |
| fxUSD/ETH    | fxSAVE | ETH/USD (inverted)          |
| fxUSD/BTC    | fxSAVE | BTC/USD                     |
| fxUSD/EUR    | fxSAVE | EUR/USD (inverted)          |
| fxUSD/GOLD   | fxSAVE | XAU/USD                     |
| fxUSD/MCAP   | fxSAVE | MCAP/USD                    |
| fxUSD/SILVER | fxSAVE | XAG/USD                     |
| fxUSD/STRC   | fxSAVE | STRC/USD (inverted)         |
| fxUSD/SPCX   | fxSAVE | SPCX/USD (inverted)         |
| stETH/BTC    | wstETH | stETH/USD, BTC/USD          |
| stETH/EUR    | wstETH | stETH/USD, EUR/USD          |
| stETH/GOLD   | wstETH | stETH/USD, XAU/USD          |
| stETH/MCAP   | wstETH | stETH/USD, MCAP/USD         |
| stETH/SILVER | wstETH | stETH/USD, XAG/USD          |
| stETH/STRC   | wstETH | stETH/USD, STRC/USD         |
| stETH/SPCX   | wstETH | stETH/USD, SPCX/USD         |

**GOLD / SILVER vs XAU / XAG:** We use **GOLD** and **SILVER** for external naming (oracle names, mainnet wiring in `src/mainnet`, deploy scripts). The formula contracts in `src/aggregators/mainnet` and Chainlink feeds stay as **XAU** (gold) and **XAG** (silver); mainnet contracts extend those and expose the quote as GOLD or SILVER. No duplicate XAU/XAG mainnet wiring—only GOLD and SILVER are deployed.

### Leveraged token oracles: output in USD vs BTC

Single-feed leveraged token oracles (e.g. **hsfxUSD-BTC/USD**) use the same formula contract for both USD- and BTC-denominated output. Only the constructor’s last argument (**invert**) changes:

| `invert` | Output                                                                 |
| -------- | ---------------------------------------------------------------------- |
| `false`  | **Price in USD** — `output = rate × BTC/USD`                           |
| `true`   | **Price in BTC** (leverage terms) — `output = rate × (1e18 / BTC/USD)` |

No other code changes are required: same formula contract, same mainnet contract type; wire a separate mainnet deployment with `invert = true` if you want a feed in BTC instead of USD.

**Current mainnet deployments** expose the **USD price** (`invert = false`). Integrators should use these feeds when consuming the leveraged token oracles (hsfxUSD-_, hsstETH-_).

## Arbitrum v3 Oracles

| Oracle         | Rate Source              | Feeds                                                        |
| -------------- | ------------------------ | ------------------------------------------------------------ |
| USDE/AAPL      | sUSDE/USDE (Chainlink)   | USDE/USD, AAPL/USD                                           |
| USDE/AMZN      | sUSDE/USDE (Chainlink)   | USDE/USD, AMZN/USD                                           |
| USDE/GOOGL     | sUSDE/USDE (Chainlink)   | USDE/USD, GOOGL/USD                                          |
| USDE/META      | sUSDE/USDE (Chainlink)   | USDE/USD, META/USD                                           |
| USDE/MSFT      | sUSDE/USDE (Chainlink)   | USDE/USD, MSFT/USD                                           |
| USDE/NVDA      | sUSDE/USDE (Chainlink)   | USDE/USD, NVDA/USD                                           |
| USDE/SPY       | sUSDE/USDE (Chainlink)   | USDE/USD, SPY/USD                                            |
| USDE/TSLA      | sUSDE/USDE (Chainlink)   | USDE/USD, TSLA/USD                                           |
| USDE/MAG7      | sUSDE/USDE (Chainlink)   | USDE/USD, (AAPL+MSFT+TSLA+GOOGL+META+AMZN+NVDA)/7            |
| USDE/MAG7.i26  | sUSDE/USDE (Chainlink)   | USDE/USD, (AAPL+MSFT+TSLA+GOOGL+META+AMZN+NVDA)/index_price  |
| stETH/AAPL     | wstETH/stETH (Chainlink) | stETH/USD, AAPL/USD                                          |
| stETH/AMZN     | wstETH/stETH (Chainlink) | stETH/USD, AMZN/USD                                          |
| stETH/GOOGL    | wstETH/stETH (Chainlink) | stETH/USD, GOOGL/USD                                         |
| stETH/META     | wstETH/stETH (Chainlink) | stETH/USD, META/USD                                          |
| stETH/MSFT     | wstETH/stETH (Chainlink) | stETH/USD, MSFT/USD                                          |
| stETH/NVDA     | wstETH/stETH (Chainlink) | stETH/USD, NVDA/USD                                          |
| stETH/SPY      | wstETH/stETH (Chainlink) | stETH/USD, SPY/USD                                           |
| stETH/TSLA     | wstETH/stETH (Chainlink) | stETH/USD, TSLA/USD                                          |
| stETH/MAG7     | wstETH/stETH (Chainlink) | stETH/USD, (AAPL+MSFT+TSLA+GOOGL+META+AMZN+NVDA)/7           |
| stETH/MAG7.i26 | wstETH/stETH (Chainlink) | stETH/USD, (AAPL+MSFT+TSLA+GOOGL+META+AMZN+NVDA)/index_price |

## Base v3 Oracles

stETH/BOM5 is retired. A constituent Chainlink feed is dead, so the aggregator and its tests were discarded.

## Robinhood v3 Oracles

| Pair | Rate Source | Feeds |
| ---- | ----------- | ----- |
| syrupUSDG/USD | syrupUSDG/USDG (Chainlink) | USDG/USD |

## Installation

```bash
# Install Foundry if not already installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install

yarn

uv sync

```

## Testing

Run all tests:

```bash
yarn test

```

GitHub Actions omits the live fork suites (`*Fork.t.sol` under `test/arbitrum`, `test/robinhood`, and `test/mainnet`) because shared RPCs 429 there. Local `yarn test` still runs them. `yarn gas` and `yarn coverage` omit them everywhere so `regression/gas.txt` and `regression/coverage.txt` match GitHub. The `ForkTest` unit suite always runs.

Run tests for specific chains:

```bash
# Mainnet unit tests
forge test --match-path "test/oracles/*.t.sol"

# Arbitrum unit tests
forge test --match-path "test/arbitrum/Aggregator_*.t.sol"

# Base unit tests
forge test --match-path "test/base/Aggregator_*.t.sol"
```

See `test/arbitrum/README.md` and `test/base/README.md` for detailed testing information. Live `latestAnswer` checks on deployed proxies are in `script/*/verify/`.

## Deployment

For deploying and verifying aggregator implementations and proxies, see [script/README.md](script/README.md).

## Off-chain market data (offchain_feeds)

The repo includes a small Python tool, `offchain_feeds`, that downloads and stores **daily** time series (UTC day boundaries) and computes basic stats.

### Setup

```bash
yarn uv
```

If you use CoinGecko sources, you may need a (free) Demo API key:

```bash
export COINGECKO_API_KEY=your_coingecko_demo_key
```

### CLI entrypoints (through Yarn)

- Extract to `<ROOT>/daily/<MARKET>.parquet` (default `<ROOT>` is `data/offchain`):
  - `yarn offchain:extract --market <MARKET> --source <SOURCE> --start <YYYY-MM-DD> --end <YYYY-MM-DD> [--root <ROOT>]`
- Compute extremes from the stored parquet:
  - `yarn offchain:stats --market <MARKET> --measure close_return --top 20 [--root <ROOT>]`
  - `yarn offchain:stats --market <MARKET> --measure intraday_range --top 20 [--root <ROOT>]`
- Show embedded parquet metadata:
  - `yarn offchain:meta --market <MARKET> [--root <ROOT>] [--pretty]`

Notes:

- `intraday_range` requires `high/low` and will fail for close-only datasets.
- Sources are **market-specific** in the current implementation (a source errors if it doesn’t support a market), so run separate extract commands per market.

#### Return distributions (GARCH + fitted curve)

There is an additional stats mode that treats the close-to-close returns as a random variable, fits a volatility model (GARCH), then fits a parametric curve to the **standardized** returns.

Example:

```bash
yarn offchain:stats --market ETH-BTC --measure return_fit --top 10 --return-kind log --dist auto --buckets --plot results/eth-btc-return-fit.png
```

What it prints:

- A JSON block describing the fitted model parameters.
- A `--top` table of the most “surprising” days under the fitted model.
- (Optional) a “fitted histogram” in 1% buckets, plus empirical frequencies.

Return kind:

- **simple** return: $r = C_t / C_{t-1} - 1$ (this is the existing `close_return` measure)
- **log** return: $\ell = \ln(C_t / C_{t-1})$ (often more statistically convenient)

Probability / score columns (layman descriptions):

- **Two-sided tail probability** (`p_two_sided`): “how extreme is this move (up or down) compared to the model?”
  - Smaller means more extreme.
  - It’s a p-value style score: $p = 2\min(F(z), 1-F(z))$ where $z$ is the standardized return.
- **One-sided tail probability** (`p_one_sided`): “how extreme is this move in the direction it occurred?”
  - Smaller means a rarer move on that side.
- **PDF density** (`pdf_density`): “how concentrated the fitted curve is at exactly this return value.”
  - This is a density, not a probability; higher usually means more ‘typical’.
- **1% bucket probability** (`p_bucket`): “what is the model probability that the return lands in this 1% bin?”
  - This is a true probability mass for the interval (e.g. [1%, 2%)).
  - Useful when you want histogram-style probabilities.

#### Market inversion (BTC-ETH vs ETH-BTC)

Some providers only list one direction of a market (e.g. Coinbase has `ETH-BTC` but not `BTC-ETH`).

- `extract`: if the requested market 404s but the inverse exists, the tool will fetch the inverse and mathematically invert OHLC (e.g. `close' = 1/close`, and `high/low` swap accordingly).
- `stats` / `export` / `meta`: if `<ROOT>/daily/<MARKET>.parquet` is missing but the inverse parquet exists, the tool will read the inverse and invert it on the fly.

### 9 mainnet v3 feeds: what to extract and how to run stats

These 9 “feeds” correspond to the v3 mainnet wrapper inventory in [V3_MAINNET_ORACLES_WORKPLAN.md](V3_MAINNET_ORACLES_WORKPLAN.md). The extractor stores the **underlying input markets** used by those feeds (not the derived on-chain wrapper output series).

Use `START=2017-01-01` (or later) and `END=2025-12-24` (or today).

1. **fxUSD/ETH** (extract `ETH/USD`)

```bash
yarn offchain:extract --market ETH-USD --source coinbase --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market ETH-USD --measure close_return   --top 20
yarn offchain:stats   --market ETH-USD --measure intraday_range --top 20
```

2. **fxUSD/BTC** (extract `BTC/USD`)

```bash
yarn offchain:extract --market BTC-USD --source coinbase --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market BTC-USD --measure close_return   --top 20
yarn offchain:stats   --market BTC-USD --measure intraday_range --top 20
```

3. **fxUSD/EUR** (extract `EUR/USD`)

```bash
yarn offchain:extract --market EUR-USD --source fred --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market EUR-USD --measure close_return --top 20
```

4. **fxUSD/XAU** (extract `XAU/USD`)

```bash
yarn offchain:extract --market XAU-USD --source fred --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market XAU-USD --measure close_return --top 20
```

5. **fxUSD/MCAP** (extract `MCAP/USD`)

```bash
yarn offchain:extract --market MCAP-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market MCAP-USD --measure close_return --top 20
```

6. **stETH/BTC** (extract `stETH/USD` and `BTC/USD`)

```bash
yarn offchain:extract --market STETH-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:extract --market BTC-USD   --source coinbase  --start 2017-01-01 --end 2025-12-24

yarn offchain:stats --market STETH-USD --measure close_return --top 20
yarn offchain:stats --market BTC-USD   --measure close_return --top 20
```

7. **stETH/EUR** (extract `stETH/USD` and `EUR/USD`)

```bash
yarn offchain:extract --market STETH-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:extract --market EUR-USD   --source fred     --start 2017-01-01 --end 2025-12-24

yarn offchain:stats --market STETH-USD --measure close_return --top 20
yarn offchain:stats --market EUR-USD   --measure close_return --top 20
```

8. **stETH/XAU** (extract `stETH/USD` and `XAU/USD`)

```bash
yarn offchain:extract --market STETH-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:extract --market XAU-USD   --source fred     --start 2017-01-01 --end 2025-12-24

yarn offchain:stats --market STETH-USD --measure close_return --top 20
yarn offchain:stats --market XAU-USD   --measure close_return --top 20
```

9. **stETH/MCAP** (extract `stETH/USD` and `MCAP/USD`)

```bash
yarn offchain:extract --market STETH-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:extract --market MCAP-USD  --source coingecko --start 2017-01-01 --end 2025-12-24

yarn offchain:stats --market STETH-USD --measure close_return --top 20
yarn offchain:stats --market MCAP-USD  --measure close_return --top 20
```

## Deployment

All new oracles go through BaoFactory CREATE3 (`script/deploy-aggregators` / `script/deploy-one-aggregator`). Direct `forge create` chain scripts are removed.

### Prerequisites

1. **Configure foundry.toml RPC endpoints** (for testing):
   Add your RPC URLs to `foundry.toml` under `[rpc_endpoints]`:

   ```toml
   [rpc_endpoints]
   mainnet = "${MAINNET_RPC_URL}"
   arbitrum = "${ARBITRUM_RPC_URL}"
   base = "${BASE_RPC_URL}"
   local = "http://127.0.0.1:8545"
   ```

   Or set environment variables in `.env`:

   ```bash
   MAINNET_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
   ARBITRUM_RPC_URL="https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY"
   BASE_RPC_URL="https://base-mainnet.g.alchemy.com/v2/YOUR_KEY"
   ```

2. **Set up a Foundry keystore account** (for non-local deploys):

   ```bash
   cast wallet import deployer --interactive
   ```

3. **Optional: Use Anvil fork for testing**:

   ```bash
   anvil -f mainnet --auto-impersonate
   ```

### Deploy oracles (CREATE3 via BaoFactory)

```bash
# Deploy one or more pairs
./script/deploy-aggregators --network mainnet --account deployer --deploy fxUSD/ETH fxUSD/BTC

# Local anvil fork
./script/deploy-aggregators --network mainnet --local --deploy fxUSD/ETH

# Check a live proxy
./script/deploy-aggregators --network mainnet --check fxUSD/ETH

# Verify on Etherscan
./script/deploy-aggregators --network mainnet --etherscan-api-key "$ETHERSCAN_API_KEY" --verify fxUSD/ETH
```

Same command, different `--network` (`arbitrum`, `base`, `megaeth`). ETH peg convenience wrapper:

```bash
SALT_PREFIX=harbor_v1 ACCOUNT=deployer script/mainnet/deploy/deploy-mainnet-eth-oracles.sh
```

**Modes:**

- `--deploy`: implementation + CREATE3 proxy via BaoFactory
- `--deploy-impl`: new implementation only (upgrades; outputs Safe tx)
- `--check`: code exists and `latestAnswer` works
- `--verify`: implementation and proxy on the explorer

State: `deployments/<network>/v3-oracles.json` (or the salted filename). See `script/README.md`.

## License

MIT
