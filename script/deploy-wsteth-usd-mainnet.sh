#!/usr/bin/env bash
set -euo pipefail

# Harbor wstETH→USD Single Feed Oracle Deployment Script - Mainnet
# Deploys a single feed oracle for wstETH→USD conversion
#
# Configuration:
#   - Set RPC_URL and ETHERSCAN_API_KEY as environment variables, or
#   - Create a .env file in the project root (see .env.example)
#   - Environment variables take precedence over .env file

# Use full path to forge/cast
FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CAST=${CAST:-$HOME/.foundry/bin/cast}

# State file for tracking deployments
STATE_FILE="${STATE_FILE:-deployment-state.json}"
MODE="${MODE:-deploy}"  # deploy, check, retry, init, verify

# Load environment variables from .env.local or .env file if they exist
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
  echo "   Set it via: export RPC_URL='your_rpc_url'"
  echo "   Or add it to a .env.local or .env file in the project root"
  exit 1
fi
if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "❌ ERROR: ETHERSCAN_API_KEY is not set"
  echo "   Set it via: export ETHERSCAN_API_KEY='your_api_key'"
  echo "   Or add it to a .env.local or .env file in the project root"
  exit 1
fi

PRIVATE_KEY=${PRIVATE_KEY_LOCAL:-${PRIVATE_KEY:-}}
OWNER=${OWNER:-}

if [[ -z "$PRIVATE_KEY" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  echo "   Set it via: export PRIVATE_KEY='your_private_key'"
  exit 1
fi
if [[ -z "$OWNER" ]]; then
  echo "❌ ERROR: OWNER is not set"
  echo "   Set it via: export OWNER='your_owner_address'"
  exit 1
fi

# Contract addresses (Ethereum mainnet)
WSTETH=${WSTETH:-0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0}
FXSAVE=${FXSAVE:-0x7743e50f534a7f9f1791dde7dcd89f7783eefc39}

# Chainlink feeds (Ethereum mainnet)
STETH_USD_FEED=${STETH_USD_FEED:-0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8}

# Chainlink feeds (not used for WSTETH rate source, but required for constructor)
SUSDE_USDE_FEED=${SUSDE_USDE_FEED:-0x0000000000000000000000000000000000000000}
WSTETH_STETH_FEED=${WSTETH_STETH_FEED:-0x0000000000000000000000000000000000000000}

# Library (pre-deployed on mainnet)
PRICE_ORACLE_LIB=${PRICE_ORACLE_LIB:-0xe0fa670bb2e77a14d64945acae9c09f1bd268b39}

# Constraints
MAX_AGE=${MAX_AGE:-604800}  # 7 days
MAX_DEV=${MAX_DEV:-50000000000000000}  # 5% (0.05 * 1e18)

# Initialize variables
SINGLE_IMPL="${SINGLE_IMPL:-}"
WSTETH_USD="${WSTETH_USD:-}"

# Helper function to save state
save_state() {
  # Load existing state if it exists
  local existing_state="{}"
  if [[ -f "$STATE_FILE" ]]; then
    existing_state=$(cat "$STATE_FILE")
  fi
  
  # Update with new values
  local state_json=$(echo "$existing_state" | jq --arg impl "$SINGLE_IMPL" \
    --arg wsteth_usd "$WSTETH_USD" \
    '. + {
      "single_implementation": $impl,
      "proxies": (.proxies // {}) + {"WSTETH_USD": $wsteth_usd},
      "deployment_time": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
    }')
  
  echo "$state_json" > "$STATE_FILE"
  echo "✓ State saved to $STATE_FILE"
}

# Helper function to load state
load_state() {
  if [[ -f "$STATE_FILE" ]]; then
    echo "📂 Loading state from $STATE_FILE"
    local impl_val=$(jq -r '.single_implementation // empty' "$STATE_FILE" 2>/dev/null || echo "")
    [[ -n "$impl_val" ]] && [[ "$impl_val" != "null" ]] && SINGLE_IMPL="$impl_val"
    
    local val=$(jq -r '.proxies.WSTETH_USD // empty' "$STATE_FILE" 2>/dev/null || echo "")
    [[ -n "$val" ]] && [[ "$val" != "null" ]] && WSTETH_USD="$val"
    
    return 0
  else
    return 1
  fi
}

# Helper function to check if contract is initialized
check_initialized() {
  local proxy=$1
  local name=$2
  
  if [[ -z "$proxy" ]] || [[ "$proxy" == "null" ]] || [[ "$proxy" == "" ]]; then
    echo "❌ $name: Not deployed"
    return 1
  fi
  
  # Check if contract exists (has code)
  local code=$("$CAST" code "$proxy" --rpc-url "$RPC_URL" 2>/dev/null | head -1)
  if [[ "$code" == "0x" ]]; then
    echo "❌ $name ($proxy): No code at address"
    return 1
  fi
  
  # Try to call oracleName() - if initialized, this should work
  local oracle_name=$("$CAST" call "$proxy" "oracleName()(string)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
  if [[ -n "$oracle_name" ]] && [[ "$oracle_name" != "" ]]; then
    echo "✅ $name ($proxy): Initialized (name: $oracle_name)"
    return 0
  else
    echo "⚠️  $name ($proxy): Deployed but NOT initialized"
    return 1
  fi
}

# Helper function to deploy proxy
deploy_proxy() {
  local impl=$1
  local init_data=$2
  
  echo "  Deploying proxy..."
  PROXY_OUT=$("$FORGE" create lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast \
    --constructor-args "$impl" "$init_data")
  
  local proxy=$(grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" <<<"$PROXY_OUT" | awk '{print $3}')
  if [[ -z "$proxy" ]]; then
    echo "❌ Failed to deploy proxy"
    return 1
  fi
  echo "  ✓ Proxy deployed: $proxy"
  echo "$proxy"
}

# Load existing state
load_state || true

# Check mode
if [[ "$MODE" == "check" ]]; then
  echo "=== Checking Deployment Status ==="
  check_initialized "$SINGLE_IMPL" "Single Feed Implementation"
  check_initialized "$WSTETH_USD" "wstETH→USD"
  exit 0
fi

echo "=== Deploying wstETH→USD Single Feed Oracle ==="
echo "Network: $(cast chain-id --rpc-url "$RPC_URL" 2>/dev/null || echo 'unknown')"
echo "Owner: $OWNER"
echo ""

# 1. Deploy Single Feed Implementation (if not already deployed)
if [[ -z "$SINGLE_IMPL" ]] || [[ "$SINGLE_IMPL" == "null" ]] || [[ "$SINGLE_IMPL" == "" ]]; then
  echo "Deploying HarborSingleFeedAndRateAggregator_v1..."
  echo "  Using PriceOracle library: $PRICE_ORACLE_LIB"
  SINGLE_IMPL_OUT=$("$FORGE" create src/price/HarborSingleFeedAndRateAggregator_v1.sol:HarborSingleFeedAndRateAggregator_v1 \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast \
    --libraries src/price/PriceOracle_v1.sol:PriceOracle_v1:$PRICE_ORACLE_LIB \
    --constructor-args "$WSTETH" "$FXSAVE" "$SUSDE_USDE_FEED" "$WSTETH_STETH_FEED")
  SINGLE_IMPL=$(grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" <<<"$SINGLE_IMPL_OUT" | awk '{print $3}')
  echo "  ✓ Single Feed Implementation: $SINGLE_IMPL"
  save_state
else
  echo "✓ Single Feed Implementation already deployed: $SINGLE_IMPL"
fi

# 2. Deploy wstETH→USD Proxy
echo ""
echo "Deploying wstETH→USD Oracle..."
echo "  Rate Source: WSTETH (0) - direct call to wstETH contract"
echo "  First Feed: stETH/USD ($STETH_USD_FEED)"
echo "  Price Divisor: 1"
echo "  Max Age: $MAX_AGE seconds ($(($MAX_AGE / 86400)) days)"
echo "  Max Deviation: $MAX_DEV (5%)"

# Prepare initialization data
# initialize(address owner_, string oracleName_, RateSource rateSource_, address firstFeed_, uint256 priceDivisor_, uint64 firstFeedMaxAge_, uint256 firstFeedMaxDev_)
# RateSource: 0 = WSTETH
# Price calculation: (wstETH/stETH rate) × (stETH/USD price) = wstETH/USD price
INIT_DATA=$("$CAST" calldata "initialize(address,string,uint8,address,uint256,uint64,uint256)" \
  "$OWNER" "wstETHToUSD" 0 "$STETH_USD_FEED" 1 "$MAX_AGE" "$MAX_DEV")

if [[ -z "$WSTETH_USD" ]] || [[ "$WSTETH_USD" == "null" ]] || [[ "$WSTETH_USD" == "" ]]; then
  WSTETH_USD=$(deploy_proxy "$SINGLE_IMPL" "$INIT_DATA")
  save_state
else
  echo "✓ wstETH→USD already deployed: $WSTETH_USD"
  check_initialized "$WSTETH_USD" "wstETH→USD"
fi

# 3. Verify deployment
echo ""
echo "=== Verification ==="
echo "Single Feed Implementation: $SINGLE_IMPL"
echo "wstETH→USD Proxy: $WSTETH_USD"

# Test the oracle
echo ""
echo "Testing oracle..."
PRICE=$("$CAST" call "$WSTETH_USD" "getPrice()(uint256)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
if [[ -n "$PRICE" ]] && [[ "$PRICE" != "0" ]]; then
  # Convert from 18 decimals to readable format
  PRICE_READABLE=$(echo "scale=2; $PRICE / 10^18" | bc 2>/dev/null || echo "$PRICE")
  echo "✓ Oracle is working! Current price: $PRICE_READABLE USD per wstETH"
else
  echo "⚠️  Could not fetch price from oracle"
fi

# 4. Verification on Etherscan (if MODE is verify)
if [[ "$MODE" == "verify" ]]; then
  echo ""
  echo "=== Verifying Contracts on Etherscan ==="
  
  echo "Verifying Single Feed Implementation..."
  "$FORGE" verify-contract "$SINGLE_IMPL" \
    src/price/HarborSingleFeedAndRateAggregator_v1.sol:HarborSingleFeedAndRateAggregator_v1 \
    --chain-id 1 \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --libraries src/price/PriceOracle_v1.sol:PriceOracle_v1:$PRICE_ORACLE_LIB \
    --constructor-args $(cast abi-encode "constructor(address,address,address,address)" "$WSTETH" "$FXSAVE" "$SUSDE_USDE_FEED" "$WSTETH_STETH_FEED") \
    && echo "  ✓ Single Feed Implementation verified" || echo "  ✗ Single Feed Implementation verification failed"
  
  echo "Verifying wstETH→USD Proxy..."
  PROXY_CONSTRUCTOR_ARGS=$("$CAST" abi-encode "constructor(address,bytes)" "$SINGLE_IMPL" "$INIT_DATA")
  "$FORGE" verify-contract "$WSTETH_USD" \
    lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
    --chain-id 1 \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --constructor-args "$PROXY_CONSTRUCTOR_ARGS" \
    && echo "  ✓ wstETH→USD Proxy verified" || echo "  ✗ wstETH→USD Proxy verification failed"
fi

echo ""
echo "=== Deployment Complete ==="
echo "wstETH→USD Oracle: $WSTETH_USD"
echo ""
echo "To verify the oracle:"
echo "  cast call $WSTETH_USD \"getPrice()(uint256)\" --rpc-url \$RPC_URL"
echo "  cast call $WSTETH_USD \"latestAnswer()(uint256,uint256,uint256,uint256)\" --rpc-url \$RPC_URL"

