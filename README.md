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

| Oracle | Rate Source | Feeds |
|--------|-------------|-------|
| fxUSD/ETH | fxSAVE | ETH/USD (inverted) |
| fxUSD/BTC | fxSAVE | BTC/USD |
| fxUSD/EUR | fxSAVE | EUR/USD (inverted) |
| fxUSD/XAU | fxSAVE | XAU/USD |
| fxUSD/MCAP | fxSAVE | MCAP/USD |
| stETH/BTC | wstETH | ETH/USD, BTC/USD |
| stETH/EUR | wstETH | ETH/USD, EUR/USD (inverted) |
| stETH/XAU | wstETH | ETH/USD, XAU/USD |
| stETH/MCAP | wstETH | ETH/USD, MCAP/USD |

## Installation

```bash
# Install Foundry if not already installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

## Testing

```bash
forge test
```

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

### Prerequisites

1. **Configure foundry.toml RPC endpoints**:
   Add your RPC URLs to `foundry.toml` under `[rpc_endpoints]`:

   ```toml
   [rpc_endpoints]
   mainnet = "https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
   local = "http://127.0.0.1:8545"
   ```

2. **Set up a Foundry keystore account** (for non-local deploys):

   ```bash
   cast wallet import deployer --interactive
   ```

3. **Optional: Use Anvil fork for testing**:

   ```bash
   anvil -f mainnet --auto-impersonate
   ```

### Deploy v3 Mainnet Oracles

Deploy individual oracles using `script/harbor-aggregators-v3`:

```bash
# Deploy fxUSD/ETH to mainnet
./script/harbor-aggregators-v3 --network mainnet --base fxUSD --quote ETH --account deployer --deploy

# Deploy with local anvil fork (for testing)
./script/harbor-aggregators-v3 --network mainnet --local --base fxUSD --quote ETH --deploy

# Check deployment status
./script/harbor-aggregators-v3 --network mainnet --base fxUSD --quote ETH --check

# Verify on Etherscan
./script/harbor-aggregators-v3 --network mainnet --base fxUSD --quote ETH --etherscan-api-key YOUR_KEY --verify
```

**Modes:**

- `--deploy`: Deploy implementation + proxy via BaoFactory
- `--deploy-impl`: Deploy new implementation only (for upgrades; outputs Safe tx)
- `--check`: Verify deployment exists and returns valid data
- `--verify`: Verify both implementation and proxy on Etherscan
- `--validate-args`: Dry-run validation

Deployments are recorded in `deployment-state-v3-<network>.json`.

### Deploy to Arbitrum

Deploy the Arbitrum oracle contracts:

```bash
./script/deploy-arbitrum-oracles
```

This will deploy:

- 1 PriceOracle library (pre-deployed, reused)
- 3 implementation contracts (Single Feed, Double Feed, Custom Feed)
- 20 proxy contracts:
  - sUSDE→USD, sUSDE→AAPL, sUSDE→AMZN, sUSDE→GOOGL, sUSDE→META, sUSDE→MSFT, sUSDE→NVDA, sUSDE→SPY, sUSDE→TSLA, sUSDE→MAG7
  - wstETH→USD, wstETH→AAPL, wstETH→AMZN, wstETH→GOOGL, wstETH→META, wstETH→MSFT, wstETH→NVDA, wstETH→SPY, wstETH→TSLA, wstETH→MAG7

**Deployment Modes:**

- `MODE=deploy` (default): Deploy all contracts
- `MODE=check`: Check deployment status
- `MODE=retry`: Retry initialization of failed contracts
- `MODE=init`: Initialize contracts only
- `MODE=verify`: Verify all contracts on Arbiscan

**Examples:**

```bash
# Deploy all contracts
./script/deploy-arbitrum-oracles

# Check deployment status
MODE=check ./script/deploy-arbitrum-oracles

# Verify all contracts
MODE=verify ./script/deploy-arbitrum-oracles

# Skip rate source configuration
SKIP_RATE_CONFIG=true ./script/deploy-arbitrum-oracles
```

**Note**: For Arbitrum, make sure to set:

- `RPC_URL` to an Arbitrum RPC endpoint (e.g., `https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY`)
- `ETHERSCAN_API_KEY` to your Etherscan API key (same key works for both mainnet and Arbitrum)

## License

MIT
