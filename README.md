# Harbor Price Aggregators

Generic price oracle aggregators for Harbor Protocol, supporting single, double, and custom feed aggregations with configurable rate sources.

## Overview

This repository contains v3 price oracle aggregators built on a modular, immutable architecture. The v3 design separates formula logic (price calculations) from chain-specific wiring (addresses and feeds), enabling clean, upgradeable, and secure oracle implementations.

**Architecture:**

- **Formula Contracts** (`src/price/oracles/`): Contain immutable price calculation logic
- **Wiring Contracts** (`src/mainnet/`, `src/arbitrum/`, `src/base/`): Wire formula contracts with chain-specific addresses
- **Utility Libraries**: Reusable price calculation libraries (SingleFeedPriceLib, DoubleFeedPriceLib, MultiFeedPriceLib, etc.)
- **Rate Libraries**: Rate fetching libraries (FxSaveRateLib, WstETHRateLib, ChainlinkRateLib)

## Features

- **Immutable Configuration**: All oracle parameters are set at construction time, ensuring security and predictability
- **Modular Design**: Formula contracts are chain-agnostic; wiring contracts provide chain-specific configuration
- **Multi-Chain Support**: Deployed on Ethereum Mainnet, Arbitrum, and Base
- **Library-Based Calculations**: Price calculations use embedded library functions (no separate deployments)
- **Rate Source Support**: 
  - Direct contract calls: fxSAVE, wstETH
  - Chainlink feeds: wstETH/stETH, sUSDE/USDE
- **Oracle Types**:
  - **Single Feed**: Direct price conversions (e.g., fxUSD/BTC, fxUSD/ETH)
  - **Double Feed**: Cross-currency conversions (e.g., stETH/BTC, stETH/EUR)
  - **Multi-Feed Average**: Average of multiple feeds (e.g., stETH/MAG7 - 7 stock average)
  - **Multi-Feed Indexed**: Indexed multi-feed with baseline normalization (e.g., stETH/MAG7.i26)
  - **Multi-Feed Normalized**: Multi-feed with per-feed normalization factors (e.g., stETH/BOM5 - meme coin basket)
- **UUPS Upgradeable**: Upgradeable proxy pattern for future improvements
- **Comprehensive Testing**: Full test coverage including fork tests for live chain validation

## Oracle Types

### Single Feed Oracles

Single feed oracles use one Chainlink price feed with optional price inversion.

**Examples:**
- `Oracle_fxUSD_BTC`: fxUSD/BTC (inverted BTC/USD feed)
- `Oracle_fxUSD_ETH`: fxUSD/ETH (ETH/USD feed)
- `Oracle_fxUSD_EUR`: fxUSD/EUR (EUR/USD feed)

**Formula Contract Structure:**
- Uses `SingleFeedPriceLib` for price calculation
- Rate from fxSAVE or wstETH contract
- Immutable feed address, decimals, divisor, and inversion flag

### Double Feed Oracles

Double feed oracles combine two Chainlink feeds to calculate cross-currency prices.

**Examples:**
- `Oracle_stETH_BTC`: stETH/BTC = (stETH/USD) / (BTC/USD)
- `Oracle_stETH_EUR`: stETH/EUR = (stETH/USD) / (EUR/USD)
- `Oracle_stETH_XAU`: stETH/XAU = (stETH/USD) / (XAU/USD)

**Formula Contract Structure:**
- Uses `DoubleFeedPriceLib` for price calculation
- Rate from wstETH contract or Chainlink feed
- Immutable first feed, second feed, decimals, divisor, and inversion flag

### Multi-Feed Average Oracles

Multi-feed average oracles calculate the average of multiple feeds, then convert to base asset terms.

**Examples:**
- `Oracle_stETH_MAG7`: stETH/MAG7 = (stETH/USD) / (average of 7 stock feeds)
- `Oracle_USDE_MAG7`: USDE/MAG7 = (USDE/USD) / (average of 7 stock feeds)

**Formula Contract Structure:**
- Uses `MultiFeedDivPriceLib` to sum feeds and divide by feed count
- Rate from Chainlink feed (wstETH/stETH or sUSDE/USDE)
- Immutable array of feed addresses and decimals

### Multi-Feed Indexed Oracles

Multi-feed indexed oracles normalize a multi-feed sum against a baseline index price.

**Examples:**
- `Oracle_stETH_MAG7i26`: stETH/MAG7.i26 = (stETH/USD) / (indexed MAG7 value)
  - Indexed value = (current sum of 7 stocks) / (baseline sum from 1-1-2026)
- `Oracle_USDE_MAG7i26`: USDE/MAG7.i26 = (USDE/USD) / (indexed MAG7 value)

**Formula Contract Structure:**
- Uses `MultiFeedSumPriceLib` to sum feeds
- Calculates indexed value: `(currentSum * 1e18) / indexPrice`
- Immutable index price baseline

### Multi-Feed Normalized Oracles

Multi-feed normalized oracles apply per-feed normalization factors before summing.

**Examples:**
- `Oracle_stETH_BOM5`: stETH/BOM5 = (stETH/USD) / (normalized basket sum)
  - Basket: DOGE, SHIB, PEPE, TRUMP, WIF
  - Each feed price is multiplied by its normalization factor (supply normalization)
  - Sum of normalized prices represents the basket value

**Formula Contract Structure:**
- Uses `MultiFeedNormalizedPriceLib` for per-feed normalization
- Each feed has an immutable normalization factor (18 decimals)
- Normalization factors normalize prices to a common supply base (e.g., WIF's total supply)

## Installation

```bash
# Install Foundry if not already installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install
```

## Testing

### Prerequisites

**Important**: Before running tests, you must set the required RPC URLs in your `.env` file:

```bash
# Required RPC URLs for fork tests
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
ARBITRUM_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY
BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY
```

These are used by fork tests to test oracles against live on-chain data.

### Running Tests

**Run all tests:**
```bash
forge test
```

**Run specific test suites:**

- **Mainnet v3 Oracle Tests:**
  ```bash
  forge test --match-path "test/price/*.t.sol" -vvv
  ```

- **Arbitrum Oracle Fork Tests:**
  ```bash
  # All Arbitrum tests
  forge test --match-path "test/arbitrum/*.t.sol" --fork-url $arbitrum -vvv
  
  # Specific test suites
  forge test --match-path "test/arbitrum/ArbitrumOraclesFork.t.sol" --fork-url $arbitrum -vvv
  forge test --match-path "test/arbitrum/ArbitrumSUSDEOraclesFork.t.sol" --fork-url $arbitrum -vvv
  forge test --match-path "test/arbitrum/ArbitrumMAG7OraclesFork.t.sol" --fork-url $arbitrum -vvv
  forge test --match-path "test/arbitrum/ArbitrumMAG7i26OraclesFork.t.sol" --fork-url $arbitrum -vvv
  ```

- **Base Oracle Fork Tests:**
  ```bash
  forge test --match-path "test/base/*.t.sol" --fork-url $base -vvv
  ```

**Note**: Fork tests require the corresponding RPC URLs to be set in your `.env` file. See `test/arbitrum/README.md` and `test/base/README.md` for more details.

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

1. **Set required environment variables** (choose one method):

   **Option A: Create a `.env.local` or `.env` file** in the project root:

   ```bash
   # .env.local (recommended - typically gitignored)
   RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
   ETHERSCAN_API_KEY=your_etherscan_api_key
   PRIVATE_KEY=your_private_key
   OWNER=your_owner_address  # Set to your deployer address
   ```

   **Option B: Export environment variables**:

   ```bash
   export RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY"
   export ETHERSCAN_API_KEY="your_etherscan_api_key"
   export PRIVATE_KEY="your_private_key"
   export OWNER="your_owner_address"  # Set to your deployer address
   ```

   **Note**: The scripts will automatically load from `.env.local` (if exists) or `.env` (if exists). Priority order:
   1. Environment variables (exported)
   2. `.env.local` file
   3. `.env` file

2. **Get API keys**:
   - **RPC URL**: Get an Alchemy/Infura API key for your target network
   - **Etherscan API Key**: Get from [Etherscan](https://etherscan.io/apis) (works for both mainnet and Arbitrum via their multichain API v2)

3. **Optional: Use Anvil fork for testing**:
   For local testing with real mainnet data, you can use Anvil:

   ```bash
   # Fork Ethereum mainnet
   anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY --host 0.0.0.0 --port 8545

   # Fork Arbitrum
   anvil --fork-url https://arb-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY --host 0.0.0.0 --port 8545
   ```

   Then set `RPC_URL=http://localhost:8545` in your `.env.local` or export it.

### Deploy to Ethereum Mainnet

Deploy the new mainnet oracle contracts:

```bash
./script/deploy-harbor-oracles-v2-mainnet-new
```

This will deploy:

- 1 Double Feed implementation contract
- 10 proxy contracts:
  - fxsave→ETH, fxsave→BTC, fxsave→EUR, fxsave→XAU, fxsave→MCAP
  - wstETH→BTC, wstETH→EUR, wstETH→XAU, wstETH→MCAP

**Deployment Modes:**

- `MODE=deploy` (default): Deploy all contracts
- `MODE=check`: Check deployment status
- `MODE=retry`: Retry initialization of failed contracts
- `MODE=init`: Initialize contracts only
- `MODE=verify`: Verify all contracts on Etherscan

**Examples:**

```bash
# Deploy all contracts
./script/deploy-harbor-oracles-v2-mainnet-new

# Check deployment status
MODE=check ./script/deploy-harbor-oracles-v2-mainnet-new

# Verify all contracts
MODE=verify ./script/deploy-harbor-oracles-v2-mainnet-new

# Skip rate source configuration
SKIP_RATE_CONFIG=true ./script/deploy-harbor-oracles-v2-mainnet-new
```

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

## Rate Sources

The contracts support four rate source types:

1. **WSTETH** (0): Direct call to `IWstETH.getStETHByWstETH()` - always current, no staleness check
2. **FXSAVE** (1): Direct call to `IFxSAVE.convertToAssets()` - always current, no staleness check
3. **SUSDE_CHAINLINK** (2): Chainlink feed for sUSDE/USDE rate - configurable staleness check
4. **WSTETH_CHAINLINK** (3): Chainlink feed for wstETH/stETH rate - configurable staleness check

For Chainlink rate sources, use `setMaxRateSourceAge()` to configure the maximum acceptable age (default: 1 day, typically set to 7 days in production). If a Chainlink rate feed goes stale beyond this threshold, the oracle will revert to prevent using outdated conversion rates.

**Rate Validation:**

- **WSTETH**: Rate must be between 1.0 and 2.0 (wstETH/stETH conversion)
- **FXSAVE**: Rate must be >= 0.9x underlying
- **SUSDE_CHAINLINK**: Rate must be >= 0.9x (no upper bound, matches fxSAVE pattern)
- **WSTETH_CHAINLINK**: Rate must be between 1.0 and 2.0 (wstETH/stETH conversion)

### Deployment Output

The script will output all deployed contract addresses and verify they're working with live price data.

## License

MIT
