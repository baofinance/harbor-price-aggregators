# Harbor Price Aggregators

Generic price oracle aggregators for Harbor Protocol, supporting single, double, and custom feed aggregations with configurable rate sources.

## Overview

This repository contains three main oracle aggregator contracts:

- **HarborSingleFeedAndRateAggregator_v1**: For single feed conversions (e.g., wstETH→ETH)
- **HarborDoubleFeedAndRateAggregator_v1**: For double feed conversions (e.g., fxSAVE→BTC, wstETH→MCAP)
- **HarborCustomFeedAndRateAggregator_v1**: For custom feed aggregations (e.g., wstETH→T6CH aggregated stock basket)

## Features

- **Generic Implementation**: Reusable contracts that can be configured for different feed combinations
- **Rate Sources**: Support for wstETH, fxSAVE, and Chainlink rate feeds (SUSDE_CHAINLINK, WSTETH_CHAINLINK)
- **Custom Feed Aggregation**: Aggregate multiple feeds with configurable divisor (e.g., average of 6 stock prices)
- **Rate Source Validation**: Configurable staleness checks for Chainlink rate feeds
- **Divisor Support**: Configurable divisors for special feed normalization (e.g., MCAP)
- **UUPS Upgradeable**: Upgradeable proxy pattern for future improvements
- **Comprehensive Testing**: Full test coverage with fuzzing

## Contracts

### HarborSingleFeedAndRateAggregator_v1

Single feed aggregator for direct conversions (e.g., wstETH/ETH).

**Initialize Parameters:**
- `owner`: The owner address
- `oracleName`: Oracle name/description
- `rateSource`: Rate source (0 = WSTETH, 1 = FXSAVE, 2 = SUSDE_CHAINLINK, 3 = WSTETH_CHAINLINK)
- `firstFeed`: First feed address
- `priceDivisor`: Divisor for price normalization
- `firstFeedMaxAge`: Max age for first feed
- `firstFeedMaxDev`: Max deviation for first feed

**Key Functions:**
- `getPrice()`: Get the current price (optimized internal implementation)
- `getRate()`: Get the current rate from the configured rate source
- `decimals()`: Returns 18 (always 18 decimals)
- `description()`: Returns the oracle name/description (Chainlink interface)
- `version()`: Returns the contract version (always 1 for v1)
- `maxRateSourceAge()`: View the current max age setting for Chainlink rate feeds
- `setMaxRateSourceAge(uint64)`: Configure staleness tolerance for Chainlink rate feeds (default: 1 day)

### HarborDoubleFeedAndRateAggregator_v1

Double feed aggregator for cross-currency conversions (e.g., fxSAVE→BTC, wstETH→MCAP).

**Initialize Parameters:**
- `owner`: The owner address
- `oracleName`: Oracle name/description
- `rateSource`: Rate source (0 = WSTETH, 1 = FXSAVE, 2 = SUSDE_CHAINLINK, 3 = WSTETH_CHAINLINK)
- `firstFeed`: First feed address
- `secondFeed`: Second feed address
- `priceDivisor`: Divisor for price normalization (e.g., 1e12 for MCAP)
- `firstFeedMaxAge`: Max age for first feed
- `firstFeedMaxDev`: Max deviation for first feed
- `secondFeedMaxAge`: Max age for second feed
- `secondFeedMaxDev`: Max deviation for second feed

**Key Functions:**
- `getPrice()`: Get the current price (optimized internal implementation)
- `getRate()`: Get the current rate from the configured rate source
- `decimals()`: Returns 18 (always 18 decimals)
- `description()`: Returns the oracle name/description (Chainlink interface)
- `version()`: Returns the contract version (always 1 for v1)
- `maxRateSourceAge()`: View the current max age setting for Chainlink rate feeds
- `setMaxRateSourceAge(uint64)`: Configure staleness tolerance for Chainlink rate feeds (default: 1 day)

### HarborCustomFeedAndRateAggregator_v1

Custom feed aggregator for aggregating multiple feeds (e.g., wstETH→T6CH aggregated stock basket).

**Initialize Parameters:**
- `owner`: The owner address
- `oracleName`: Oracle name/description
- `rateSource`: Rate source (0 = WSTETH, 1 = FXSAVE, 2 = SUSDE_CHAINLINK, 3 = WSTETH_CHAINLINK)
- `customFeeds`: Array of custom feed addresses (e.g., stock price feeds)
- `usdFeed`: USD feed address for final conversion
- `aggregationDivisor`: Divisor for aggregated price normalization (e.g., 6 for average of 6 stocks)
- `customFeedMaxAge`: Max age for custom feeds
- `customFeedMaxDev`: Max deviation for custom feeds
- `usdFeedMaxAge`: Max age for USD feed
- `usdFeedMaxDev`: Max deviation for USD feed

**Key Functions:**
- `getPrice()`: Get the current price (optimized internal implementation)
- `getRate()`: Get the current rate from the configured rate source
- `decimals()`: Returns 18 (always 18 decimals)
- `description()`: Returns the oracle name/description (Chainlink interface)
- `version()`: Returns the contract version (always 1 for v1)
- `getCustomFeedCount()`: Get the number of custom feeds
- `getCustomFeed(uint256)`: Get a custom feed address by index
- `maxRateSourceAge()`: View the current max age setting for Chainlink rate feeds
- `setMaxRateSourceAge(uint64)`: Configure staleness tolerance for Chainlink rate feeds (default: 1 day)

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

### 9 mainnet v3 feeds: what to extract and how to run stats

These 9 “feeds” correspond to the v3 mainnet wrapper inventory in [V3_MAINNET_ORACLES_WORKPLAN.md](V3_MAINNET_ORACLES_WORKPLAN.md). The extractor stores the **underlying input markets** used by those feeds (not the derived on-chain wrapper output series).

Use `START=2017-01-01` (or later) and `END=2025-12-24` (or today).

1) **fxUSD/ETH** (extract `ETH/USD`)

```bash
yarn offchain:extract --market ETH-USD --source coinbase --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market ETH-USD --measure close_return   --top 20
yarn offchain:stats   --market ETH-USD --measure intraday_range --top 20
```

2) **fxUSD/BTC** (extract `BTC/USD`)

```bash
yarn offchain:extract --market BTC-USD --source coinbase --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market BTC-USD --measure close_return   --top 20
yarn offchain:stats   --market BTC-USD --measure intraday_range --top 20
```

3) **fxUSD/EUR** (extract `EUR/USD`)

```bash
yarn offchain:extract --market EUR-USD --source fred --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market EUR-USD --measure close_return --top 20
```

4) **fxUSD/XAU** (extract `XAU/USD`)

```bash
yarn offchain:extract --market XAU-USD --source fred --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market XAU-USD --measure close_return --top 20
```

5) **fxUSD/MCAP** (extract `MCAP/USD`)

```bash
yarn offchain:extract --market MCAP-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:stats   --market MCAP-USD --measure close_return --top 20
```

6) **stETH/BTC** (extract `stETH/USD` and `BTC/USD`)

```bash
yarn offchain:extract --market STETH-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:extract --market BTC-USD   --source coinbase  --start 2017-01-01 --end 2025-12-24

yarn offchain:stats --market STETH-USD --measure close_return --top 20
yarn offchain:stats --market BTC-USD   --measure close_return --top 20
```

7) **stETH/EUR** (extract `stETH/USD` and `EUR/USD`)

```bash
yarn offchain:extract --market STETH-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:extract --market EUR-USD   --source fred     --start 2017-01-01 --end 2025-12-24

yarn offchain:stats --market STETH-USD --measure close_return --top 20
yarn offchain:stats --market EUR-USD   --measure close_return --top 20
```

8) **stETH/XAU** (extract `stETH/USD` and `XAU/USD`)

```bash
yarn offchain:extract --market STETH-USD --source coingecko --start 2017-01-01 --end 2025-12-24
yarn offchain:extract --market XAU-USD   --source fred     --start 2017-01-01 --end 2025-12-24

yarn offchain:stats --market STETH-USD --measure close_return --top 20
yarn offchain:stats --market XAU-USD   --measure close_return --top 20
```

9) **stETH/MCAP** (extract `stETH/USD` and `MCAP/USD`)

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

