#!/usr/bin/env bash
set -euo pipefail

# Verify Single Feed Implementation Contract
# Contract Address: 0xAbBD1bc15365D3BaB403612b96F4A3C3aA4B8227

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

if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "❌ ERROR: ETHERSCAN_API_KEY is not set"
  echo "   Set it via: export ETHERSCAN_API_KEY='your_api_key'"
  exit 1
fi

FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CONTRACT_ADDRESS="0xAbBD1bc15365D3BaB403612b96F4A3C3aA4B8227"
PRICE_ORACLE_LIB="0xe0fa670bb2e77a14d64945acae9c09f1bd268b39"

# Constructor arguments: (WSTETH, FXSAVE, SUSDE_USDE_FEED, WSTETH_STETH_FEED)
CONSTRUCTOR_ARGS="0x0000000000000000000000007f39c581f595b53c5cb19bd0b3f8da6c935e2ca00000000000000000000000007743e50f534a7f9f1791dde7dcd89f7783eefc3900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

echo "=== Verifying Single Feed Implementation ==="
echo "Contract: $CONTRACT_ADDRESS"
echo "Library: $PRICE_ORACLE_LIB"
echo ""

"$FORGE" verify-contract "$CONTRACT_ADDRESS" \
  src/price/HarborSingleFeedAndRateAggregator_v1.sol:HarborSingleFeedAndRateAggregator_v1 \
  --chain-id 1 \
  --compiler-version 0.8.30 \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  --libraries src/price/PriceOracle_v1.sol:PriceOracle_v1:"$PRICE_ORACLE_LIB" \
  --constructor-args "$CONSTRUCTOR_ARGS"

echo ""
echo "✅ Verification submitted! Check Etherscan for status."

