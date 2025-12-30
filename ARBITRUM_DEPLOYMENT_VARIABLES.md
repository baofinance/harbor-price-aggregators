# Arbitrum Deployment Variables

This document lists all variables needed for deploying Harbor oracles on Arbitrum.

## Required Variables

These variables MUST be set (either as environment variables or in `.env`/`.env.local`):

```bash
# RPC endpoint for Arbitrum
RPC_URL="https://arb1.arbitrum.io/rpc"  # or your Arbitrum RPC provider

# Arbiscan API key for contract verification
ETHERSCAN_API_KEY="your_arbiscan_api_key"
```

## Optional but Recommended Variables

```bash
# Private key for deployment (defaults to test key if not set)
PRIVATE_KEY="0x..."  # or use PRIVATE_KEY_LOCAL for local deployments

# Owner address (defaults to 0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e)
OWNER="0x..."  # Address that will own the deployed contracts
```

## Pre-configured Contract Addresses (Arbitrum)

These are already configured in the script with Arbitrum mainnet addresses. You can override them if needed:

### Core Contracts
```bash
# wstETH contract on Arbitrum
WSTETH="0x5979D7b546E38E414F7E9822514be443A4800529"

# fxSAVE (not used for stock oracles, can be zero)
FXSAVE="0x0000000000000000000000000000000000000000"
```

### Rate Feeds (Chainlink)
```bash
# sUSDE to USDE rate feed
SUSDE_USDE_FEED="0x605EA726F0259a30db5b7c9ef39Df9fE78665C44"

# USDE to USD feed (pegged asset feed)
USDE_USD_FEED="0x88AC7Bca36567525A866138F03a6F6844868E0Bc"

# wstETH to stETH rate feed
WSTETH_STETH_FEED="0xB1552C5e96B312d0Bf8b554186F846C40614a540"

# stETH to USD feed (pegged asset feed)
STETH_USD_FEED="0x07C5b924399cc23c24a95c8743DE4006a32b7f2a"
```

### Stock Price Feeds (Chainlink)
```bash
AAPL_USD_FEED="0x8d0CC5f38f9E802475f2CFf4F9fc7000C2E1557c"
AMZN_USD_FEED="0xd6a77691f071E98Df7217BED98f38ae6d2313EBA"
GOOGL_USD_FEED="0x1D1a83331e9D255EB1Aaf75026B60dFD00A252ba"
META_USD_FEED="0xcd1bd86fDc33080DCF1b5715B6FCe04eC6F85845"
MSFT_USD_FEED="0xDde33fb9F21739602806580bdd73BAd831DcA867"
NVDA_USD_FEED="0x4881A4418b5F2460B21d6F08CD5aA0678a7f262F"
SPY_USD_FEED="0x46306F3795342117721D8DEd50fbcF6DF2b3cc10"
TSLA_USD_FEED="0x3609baAa0a9b1f0FE4d6CC01884585d0e191C3E3"
```

### Price Oracle Library
```bash
# Pre-deployed PriceOracle_v1 library on Arbitrum
PRICE_ORACLE_LIB="0x07f347B979fCE7cD7Bb761fEda6bd7Dfea19a6A5"
```

## Configuration Parameters

These control validation constraints and can be overridden:

```bash
# Maximum age for feed data (default: 7 days = 604800 seconds)
MAX_AGE="604800"

# Maximum deviation allowed (default: 5% = 50000000000000000)
MAX_DEV="50000000000000000"

# Maximum age for rate source feeds (default: 7 days = 604800 seconds)
MAX_RATE_SOURCE_AGE="604800"

# Custom feed aggregation divisor (default: 7 for MAG7)
AGGREGATION_DIVISOR_SUSDE="7"
AGGREGATION_DIVISOR="7"

# USD feed for custom aggregations (defaults to USDE_USD_FEED and STETH_USD_FEED)
USD_FEED_FOR_SUSDE_CUSTOM="${USDE_USD_FEED}"
USD_FEED_FOR_CUSTOM="${STETH_USD_FEED}"
```

## Deployment State Variables

These are set automatically during deployment (stored in `deployment-state-arbitrum.json`):

```bash
# Implementation contracts
SINGLE_IMPL=""    # HarborSingleFeedAndRateAggregator_v2
DOUBLE_IMPL=""    # HarborDoubleFeedAndRateAggregator_v2
CUSTOM_IMPL=""    # HarborCustomFeedAndRateAggregator_v2

# Proxy contracts for sUSDE
SUSDE_USD=""
SUSDE_AAPL=""
SUSDE_AMZN=""
SUSDE_GOOGL=""
SUSDE_META=""
SUSDE_MSFT=""
SUSDE_NVDA=""
SUSDE_SPY=""
SUSDE_TSLA=""
SUSDE_MAG7=""

# Proxy contracts for wstETH
WSTETH_USD=""
WSTETH_AAPL=""
WSTETH_AMZN=""
WSTETH_GOOGL=""
WSTETH_META=""
WSTETH_MSFT=""
WSTETH_NVDA=""
WSTETH_SPY=""
WSTETH_TSLA=""
WSTETH_MAG7=""
```

## Script Control Variables

```bash
# Deployment mode: deploy, check, retry, init, verify (default: deploy)
MODE="deploy"

# State file location (default: deployment-state-arbitrum.json)
STATE_FILE="deployment-state-arbitrum.json"

# Skip rate source staleness configuration (default: false)
SKIP_RATE_CONFIG="false"

# Forge and Cast paths (defaults to $HOME/.foundry/bin/)
FORGE="${HOME}/.foundry/bin/forge"
CAST="${HOME}/.foundry/bin/cast"
```

## Example .env File

Create a `.env` or `.env.local` file in the project root:

```bash
# Required
RPC_URL="https://arb1.arbitrum.io/rpc"
ETHERSCAN_API_KEY="your_arbiscan_api_key_here"

# Optional but recommended
PRIVATE_KEY="0xyour_private_key_here"
OWNER="0xyour_owner_address_here"

# Optional overrides (only if you need to change defaults)
# MAX_AGE="604800"
# MAX_DEV="50000000000000000"
# MAX_RATE_SOURCE_AGE="604800"
```

## Usage

1. **Create `.env` file** with at minimum `RPC_URL` and `ETHERSCAN_API_KEY`
2. **Run deployment**: `./script/deploy-arbitrum-oracles`
3. **Check status**: `MODE=check ./script/deploy-arbitrum-oracles`
4. **Verify contracts**: `MODE=verify ./script/deploy-arbitrum-oracles`

## Notes

- All feed addresses are pre-configured for Arbitrum mainnet
- The script uses v2 contracts with `invertPrice=false` for all oracles
- Deployment state is saved to `deployment-state-arbitrum.json` for resuming/interruption recovery
- The script automatically handles library linking and constructor arguments


