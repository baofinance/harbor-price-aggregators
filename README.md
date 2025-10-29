# Harbor Price Aggregators

Generic price oracle aggregators for Harbor Protocol, supporting single and double feed conversions with configurable rate sources.

## Overview

This repository contains two main oracle aggregator contracts:

- **HarborSingleFeedAndRateAggregator_v1**: For single feed conversions (e.g., wstETH→ETH)
- **HarborDoubleFeedAndRateAggregator_v1**: For double feed conversions (e.g., fxSAVE→BTC, wstETH→MCAP)

## Features

- **Generic Implementation**: Reusable contracts that can be configured for different feed combinations
- **Rate Sources**: Support for both wstETH and fxSAVE rate conversions
- **Divisor Support**: Configurable divisors for special feed normalization (e.g., MCAP)
- **UUPS Upgradeable**: Upgradeable proxy pattern for future improvements
- **Comprehensive Testing**: Full test coverage with fuzzing

## Contracts

### HarborSingleFeedAndRateAggregator_v1

Single feed aggregator for direct conversions (e.g., wstETH/ETH).

**Initialize Parameters:**
- `owner`: The owner address
- `oracleName`: Oracle name/description
- `rateSource`: Rate source (0 = wstETH, 1 = fxSAVE)
- `firstFeed`: First feed address
- `firstFeedDivisor`: Divisor for feed normalization
- `firstFeedMaxAge`: Max age for first feed
- `firstFeedMaxDev`: Max deviation for first feed

### HarborDoubleFeedAndRateAggregator_v1

Double feed aggregator for cross-currency conversions (e.g., fxSAVE→BTC, wstETH→MCAP).

**Initialize Parameters:**
- `owner`: The owner address
- `oracleName`: Oracle name/description
- `rateSource`: Rate source (0 = wstETH, 1 = fxSAVE)
- `firstFeed`: First feed address
- `secondFeed`: Second feed address
- `secondFeedDivisor`: Divisor for second feed normalization (e.g., 1e12 for MCAP)
- `firstFeedMaxAge`: Max age for first feed
- `firstFeedMaxDev`: Max deviation for first feed
- `secondFeedMaxAge`: Max age for second feed
- `secondFeedMaxDev`: Max deviation for second feed

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
- 2 implementation contracts (Single Feed and Double Feed)
- 10 proxy contracts (5 for fxSAVE, 5 for wstETH)
- All oracles will use real mainnet data via the fork

### Deployment Output

The script will output all deployed contract addresses and verify they're working with live price data.

## License

MIT

