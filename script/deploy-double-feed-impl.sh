#!/usr/bin/env bash
set -euo pipefail

# Deploy New Double Feed Implementation - Mainnet
# This deploys a new HarborDoubleFeedAndRateAggregator_v1 implementation
# that can be used to upgrade existing proxies

# Load environment variables
if [[ -f .env.local ]]; then
  set -a
  source .env.local
  set +a
elif [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

# Configuration: REQUIRED environment variables
if [[ -z "${RPC_URL:-}" ]]; then
  echo "❌ ERROR: RPC_URL is not set"
  exit 1
fi

PRIVATE_KEY=${PRIVATE_KEY_LOCAL:-${PRIVATE_KEY:-}}

if [[ -z "$PRIVATE_KEY" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  exit 1
fi

FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CAST=${CAST:-$HOME/.foundry/bin/cast}

# Contract addresses (Ethereum mainnet)
WSTETH=${WSTETH:-0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0}
FXSAVE=${FXSAVE:-0x7743e50f534a7f9f1791dde7dcd89f7783eefc39}

# Chainlink feeds (not used for mainnet, but required for constructor)
SUSDE_USDE_FEED=${SUSDE_USDE_FEED:-0x0000000000000000000000000000000000000000}
WSTETH_STETH_FEED=${WSTETH_STETH_FEED:-0x0000000000000000000000000000000000000000}

# Library (pre-deployed on mainnet)
PRICE_ORACLE_LIB=${PRICE_ORACLE_LIB:-0xe0fa670bb2e77a14d64945acae9c09f1bd268b39}

echo "=== Deploying New Double Feed Implementation ==="
echo "Network: $(cast chain-id --rpc-url "$RPC_URL" 2>/dev/null || echo 'unknown')"
echo "Library: $PRICE_ORACLE_LIB"
echo ""

# Deploy Double Feed Implementation
echo "Deploying HarborDoubleFeedAndRateAggregator_v1..."
echo "  Constructor args:"
echo "    WSTETH: $WSTETH"
echo "    FXSAVE: $FXSAVE"
echo "    SUSDE_USDE_FEED: $SUSDE_USDE_FEED"
echo "    WSTETH_STETH_FEED: $WSTETH_STETH_FEED"
echo ""

DOUBLE_IMPL_OUT=$("$FORGE" create src/price/HarborDoubleFeedAndRateAggregator_v1.sol:HarborDoubleFeedAndRateAggregator_v1 \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast \
  --libraries src/price/PriceOracle_v1.sol:PriceOracle_v1:"$PRICE_ORACLE_LIB" \
  --constructor-args "$WSTETH" "$FXSAVE" "$SUSDE_USDE_FEED" "$WSTETH_STETH_FEED")

DOUBLE_IMPL=$(grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" <<<"$DOUBLE_IMPL_OUT" | awk '{print $3}')

if [[ -z "$DOUBLE_IMPL" ]]; then
  echo "❌ Failed to deploy Double Feed Implementation"
  exit 1
fi

echo "✅ Double Feed Implementation deployed: $DOUBLE_IMPL"
echo ""
echo "=== Deployment Complete ==="
echo "New Implementation Address: $DOUBLE_IMPL"
echo ""
echo "To upgrade a proxy to this implementation, run:"
echo "  export NEW_IMPL_ADDRESS=\"$DOUBLE_IMPL\""
echo "  ./script/upgrade-wsteth-xau.sh"
echo ""
echo "Or verify this contract on Etherscan:"
echo "  export NEW_IMPL_ADDRESS=\"$DOUBLE_IMPL\""
echo "  # Then use the verify script with this address"



