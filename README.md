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

## Deployment

### Prerequisites

1. Start anvil with a mainnet fork to access real contract data:
```bash
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY --host 0.0.0.0 --port 8545
```

2. Deploy the contracts:
```bash
export PATH="$HOME/.foundry/bin:$PATH" && cd /Volumes/Github/Cursor/harbor-price-aggregators && OWNER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 ./script/deploy-harbor-oracles-v2
```

This will deploy:
- 3 implementation contracts (Single Feed, Double Feed, and Custom Feed)
- Multiple proxy contracts for various oracle configurations
- All oracles will use real mainnet data via the fork

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

