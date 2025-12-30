#!/usr/bin/env bash
set -euo pipefail

# Harbor Base Normalization Oracle Deployment Script
# Deploys HarborCustomFeedNormalization_v2 for meme coin basket with supply normalization
#
# Configuration:
#   - Set RPC_URL and ETHERSCAN_API_KEY as environment variables, or
#   - Create a .env file in the project root

# Get script directory and change to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Use full path to forge/cast
FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CAST=${CAST:-$HOME/.foundry/bin/cast}

# State file for tracking deployments
STATE_FILE="${STATE_FILE:-deployment-state-base-normalization.json}"
MODE="${MODE:-deploy}"  # deploy, check, verify, verify-impl, upgrade

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
  exit 1
fi

if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "❌ ERROR: ETHERSCAN_API_KEY is not set"
  echo "   Set it via: export ETHERSCAN_API_KEY='your_api_key'"
  exit 1
fi

# Use PRIVATE_KEY_LOCAL if set, otherwise fall back to PRIVATE_KEY or default
PRIVATE_KEY=${PRIVATE_KEY_LOCAL:-${PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}}
OWNER=${OWNER:-0x2f1567c4a651ed93db0fc6d9df1ea9196054f63e}

# Initialize variables
PRICE_ORACLE_LIB="${PRICE_ORACLE_LIB:-0x90e877e9660a52443cBabD86CA0871A1D60f27e1}"
NORMALIZATION_IMPL="${NORMALIZATION_IMPL:-}"
STETH_BAGM="${STETH_BAGM:-}"

# Check network
CHAIN_ID=$("$CAST" chain-id --rpc-url "$RPC_URL" 2>/dev/null || echo "unknown")
echo "=== Network Check ==="
echo "RPC URL: $RPC_URL"
echo "Chain ID: $CHAIN_ID"
if [[ "$CHAIN_ID" != "0x2105" ]] && [[ "$CHAIN_ID" != "8453" ]]; then
  echo "⚠️  WARNING: Expected Base chain ID (8453), got: $CHAIN_ID"
  echo "   Press Ctrl+C to cancel, or wait 5 seconds to continue..."
  sleep 5
fi
echo ""

# Base contract addresses
WSTETH=${WSTETH:-0x0000000000000000000000000000000000000000}  # Not used (using Chainlink rate)
FXSAVE=${FXSAVE:-0x0000000000000000000000000000000000000000}  # Not used
SUSDE_USDE_FEED=${SUSDE_USDE_FEED:-0x0000000000000000000000000000000000000000}  # Not used
WSTETH_STETH_FEED=${WSTETH_STETH_FEED:-0xB88BAc61a4Ca37C43a3725912B1f472c9A5bc061}  # wstETH/stETH rate

# Feeds on Base
# Note: You may need to provide a stETH/USD feed address, or use stETH/ETH * ETH/USD conversion
# For now, using stETH/ETH feed - you may need to adjust this
STETH_ETH_FEED=${STETH_ETH_FEED:-0xf586d0728a47229e747d824a939000Cf21dEF5A0}  # stETH/ETH
ETH_USD_FEED=${ETH_USD_FEED:-0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70}  # ETH/USD
# If you have a direct stETH/USD feed, set STETH_USD_FEED environment variable
STETH_USD_FEED=${STETH_USD_FEED:-$ETH_USD_FEED}  # Default to ETH/USD if no direct stETH/USD feed

# Meme coin feeds on Base
DOGE_USD_FEED=${DOGE_USD_FEED:-0x8422f3d3CAFf15Ca682939310d6A5e619AE08e57}
SHIB_USD_FEED=${SHIB_USD_FEED:-0xC8D5D660bb585b68fa0263EeD7B4224a5FC99669}
PEPE_USD_FEED=${PEPE_USD_FEED:-0xB48ac6409C0c3718b956089b0fFE295A10ACDdad}
TRUMP_USD_FEED=${TRUMP_USD_FEED:-0x7bAfa1Af54f17cC0775a1Cf813B9fF5dED2C51E5}
WIF_USD_FEED=${WIF_USD_FEED:-0x674940e1dBf7FD841b33156DA9A88afbD95AaFBa}

# Normalization factors (in 18 decimals) - multipliers to normalize to WIF max supply (~998.84M)
# Formula: normalized_price = original_price * (WIF_max_supply / coin_max_supply)
# DOGE: Max Supply = Unlimited (use circ. supply ~168B), factor = 998.84M / 168B ≈ 0.005945, but we multiply by 168.2 to get ~$22.33 from $0.133
#       Actually: $0.133 * (168B / 998.84M) = $0.133 * 168.2 = ~$22.33 ✓
# SHIB: Max Supply = ~589.5T, factor = 998.84M / 589.5T ≈ 0.000001695, multiply by 589,500 to get ~$4.41 from $0.0000075
# PEPE: Max Supply = 420.69T, factor = 998.84M / 420.69T ≈ 0.000002375, multiply by 421,000 to get ~$1.70 from $0.0000041
# TRUMP: Max Supply = 1B, factor = 998.84M / 1B ≈ 0.99884, but table shows ~0.2× for minimal change
#        Current circ. supply is ~200M, so: 998.84M / 200M ≈ 4.994×, but max supply normalization: 998.84M / 1B ≈ 0.99884×
#        The ~0.2× factor suggests: 200M / 1B = 0.2× (current circ / max supply)
#        To normalize to WIF: price * (WIF_supply / max_supply) = price * (998.84M / 1B) ≈ price * 0.99884
#        However, table shows minimal change, so we'll use the ratio: WIF_max (998.84M) / TRUMP_max (1B) ≈ 0.99884, which rounds to ~1.0
#        But for consistency with the table showing minimal change, we keep it close to 1.0
# WIF: Max Supply = ~998.84M, factor = 1.0 (reference point)
DOGE_NORM_FACTOR=${DOGE_NORM_FACTOR:-168200000000000000000}  # 168.2e18 (WIF_supply / DOGE_circ_supply ≈ 998.84M / 168B = 0.005945, but 1/0.005945 ≈ 168.2)
SHIB_NORM_FACTOR=${SHIB_NORM_FACTOR:-589500000000000000000000}  # 589500e18 (WIF_supply / SHIB_max_supply, multiply by 589,500)
PEPE_NORM_FACTOR=${PEPE_NORM_FACTOR:-421000000000000000000000}  # 421000e18 (WIF_supply / PEPE_max_supply, multiply by 421,000)
TRUMP_NORM_FACTOR=${TRUMP_NORM_FACTOR:-998840000000000000}    # ~0.99884e18 (WIF_max / TRUMP_max ≈ 998.84M / 1B ≈ 0.99884, minimal change to ~$5.10)
WIF_NORM_FACTOR=${WIF_NORM_FACTOR:-1000000000000000000}       # 1e18 (WIF_max / WIF_max = 1.0, no change)

# Constraints
MAX_AGE=${MAX_AGE:-604800}
MAX_DEV=${MAX_DEV:-50000000000000000}
MAX_RATE_SOURCE_AGE=${MAX_RATE_SOURCE_AGE:-604800}  # Default: 7 days

# Helper function to save state
save_state() {
  local state_json=$(cat <<EOF
{
  "library": "${PRICE_ORACLE_LIB:-}",
  "implementations": {
    "NORMALIZATION": "${NORMALIZATION_IMPL:-}"
  },
  "proxies": {
    "STETH_BAGM": "${STETH_BAGM:-}"
  },
  "deployment_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
)
  echo "$state_json" > "$STATE_FILE"
  echo "✓ State saved to $STATE_FILE"
}

# Helper function to load state
load_state() {
  if [[ -f "$STATE_FILE" ]]; then
    echo "📂 Loading state from $STATE_FILE"
    local val=$(jq -r '.library // empty' "$STATE_FILE" 2>/dev/null || echo "")
    [[ -n "$val" ]] && [[ "$val" != "null" ]] && PRICE_ORACLE_LIB="$val"
    
    val=$(jq -r '.implementations.NORMALIZATION // empty' "$STATE_FILE" 2>/dev/null || echo "")
    [[ -n "$val" ]] && [[ "$val" != "null" ]] && NORMALIZATION_IMPL="$val"
    
    val=$(jq -r '.proxies.STETH_BAGM // empty' "$STATE_FILE" 2>/dev/null || echo "")
    [[ -n "$val" ]] && [[ "$val" != "null" ]] && STETH_BAGM="$val"
    
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
  
  local code=$("$CAST" code "$proxy" --rpc-url "$RPC_URL" 2>/dev/null | head -1)
  if [[ "$code" == "0x" ]]; then
    echo "❌ $name ($proxy): No code at address"
    return 1
  fi
  
  local oracle_name=$("$CAST" call "$proxy" "oracleName()(string)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
  if [[ -n "$oracle_name" ]] && [[ "$oracle_name" != "" ]]; then
    echo "✅ $name ($proxy): Initialized (name: $oracle_name)"
    return 0
  else
    echo "⚠️  $name ($proxy): Deployed but NOT initialized"
    return 1
  fi
}

# Function to check deployment status
check_deployment() {
  echo "=== CHECKING DEPLOYMENT STATUS ==="
  echo ""
  
  if ! load_state; then
    echo "❌ No state file found: $STATE_FILE"
    return 1
  fi
  
  echo "Library: ${PRICE_ORACLE_LIB:-not set}"
  echo "Implementation: ${NORMALIZATION_IMPL:-not set}"
  echo ""
  
  check_initialized "$STETH_BAGM" "stETH→Bagm"
  
  return 0
}

if [[ "$MODE" == "check" ]]; then
  check_deployment
  exit 0
fi

if [[ "$MODE" == "upgrade" ]]; then
  # Load state first
  if ! load_state; then
    echo "❌ No state file found: $STATE_FILE"
    exit 1
  fi
  
  # Check if proxy exists
  if [[ -z "$STETH_BAGM" ]] || [[ "$STETH_BAGM" == "null" ]] || [[ "$STETH_BAGM" == "" ]]; then
    echo "❌ No proxy found. Deploy proxy first."
    exit 1
  fi
  
  # Allow manual override
  if [[ -n "${MANUAL_NORMALIZATION_IMPL:-}" ]]; then
    NORMALIZATION_IMPL="$MANUAL_NORMALIZATION_IMPL"
  fi
  
  if [[ -z "$NORMALIZATION_IMPL" ]] || [[ "$NORMALIZATION_IMPL" == "null" ]] || [[ "$NORMALIZATION_IMPL" == "" ]]; then
    echo "❌ No implementation address found."
    echo "   Either load from state file or set MANUAL_NORMALIZATION_IMPL"
    exit 1
  fi
  
  echo "=== UPGRADING PROXY ==="
  echo "Proxy: $STETH_BAGM"
  echo "New Implementation: $NORMALIZATION_IMPL"
  echo ""
  
  echo "Upgrading proxy to new implementation..."
  "$CAST" send "$STETH_BAGM" "upgradeTo(address)" "$NORMALIZATION_IMPL" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast && echo "✓ Proxy upgraded successfully" || {
    echo "✗ Upgrade failed" >&2
    exit 1
  }
  
  echo ""
  echo "✅ Upgrade complete!"
  exit 0
fi

if [[ "$MODE" == "verify-impl" ]] || [[ "$MODE" == "verify-implementations" ]]; then
  # Load state first (optional - can use manual overrides)
  load_state || true
  
  # Allow manual override
  if [[ -n "${MANUAL_NORMALIZATION_IMPL:-}" ]]; then
    NORMALIZATION_IMPL="$MANUAL_NORMALIZATION_IMPL"
  fi
  
  # Check if ETHERSCAN_API_KEY is set
  if [[ -z "$ETHERSCAN_API_KEY" ]]; then
    echo "❌ ETHERSCAN_API_KEY is not set. Cannot verify contracts."
    exit 1
  fi
  
  # Check if we have implementation address
  if [[ -z "$NORMALIZATION_IMPL" ]]; then
    echo "❌ No implementation address found."
    echo "   Either load from state file or set MANUAL_NORMALIZATION_IMPL"
    exit 1
  fi
  
  echo "=== VERIFYING IMPLEMENTATION CONTRACT ON BASESCAN ==="
  echo ""
  
  # Base contract addresses (needed for constructor)
  WSTETH=${WSTETH:-0x0000000000000000000000000000000000000000}
  FXSAVE=${FXSAVE:-0x0000000000000000000000000000000000000000}
  SUSDE_USDE_FEED=${SUSDE_USDE_FEED:-0x0000000000000000000000000000000000000000}
  WSTETH_STETH_FEED=${WSTETH_STETH_FEED:-0xB88BAc61a4Ca37C43a3725912B1f472c9A5bc061}
  
  # Pre-compute constructor args for implementation
  IMPL_CONSTRUCTOR_ARGS=$("$CAST" abi-encode "constructor(address,address,address,address)" "$WSTETH" "$FXSAVE" "$SUSDE_USDE_FEED" "$WSTETH_STETH_FEED")
  
  echo "Verifying Normalization Implementation..."
  echo "   Address: $NORMALIZATION_IMPL"
  "$FORGE" verify-contract \
    "$NORMALIZATION_IMPL" \
    src/price/HarborCustomFeedNormalization_v2.sol:HarborCustomFeedNormalization_v2 \
    --verifier etherscan \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --libraries src/price/PriceOracle_v1.sol:PriceOracle_v1:$PRICE_ORACLE_LIB \
    --constructor-args "$IMPL_CONSTRUCTOR_ARGS" \
    --compiler-version 0.8.30 \
    --chain base && echo "  ✓ Normalization Implementation verified" || echo "  ✗ Normalization Implementation verification failed"
  
  echo ""
  echo "✅ Implementation verification complete!"
  exit 0
fi

# Load existing state if available
if load_state; then
  echo "📂 Resuming from previous deployment state"
  echo ""
fi

echo "=== PriceOracle_v1 Library ==="
echo "✓ Using pre-deployed library: $PRICE_ORACLE_LIB"
echo ""

echo "=== Deploying Implementation Contract ==="

# Deploy Normalization Implementation
# If upgrading, skip deployment if implementation already provided
if [[ "$MODE" != "upgrade" ]] && ([[ -z "$NORMALIZATION_IMPL" ]] || [[ "$NORMALIZATION_IMPL" == "null" ]] || [[ "$NORMALIZATION_IMPL" == "" ]] || [[ -n "${FORCE_REDEPLOY_IMPL:-}" ]]); then
  echo "Deploying HarborCustomFeedNormalization_v2..."
  NORMALIZATION_IMPL_OUT=$("$FORGE" create src/price/HarborCustomFeedNormalization_v2.sol:HarborCustomFeedNormalization_v2 \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --libraries src/price/PriceOracle_v1.sol:PriceOracle_v1:$PRICE_ORACLE_LIB \
    --broadcast \
    --constructor-args "$WSTETH" "$FXSAVE" "$SUSDE_USDE_FEED" "$WSTETH_STETH_FEED")
  NORMALIZATION_IMPL=$(grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" <<<"$NORMALIZATION_IMPL_OUT" | awk '{print $3}')
  echo "  Normalization Implementation: $NORMALIZATION_IMPL"
  save_state
else
  echo "✓ Normalization Implementation already deployed: $NORMALIZATION_IMPL"
fi

echo ""
echo "=== Deploying Proxy Contract ==="

# Helper function to deploy proxy
deploy_proxy() {
  local impl=$1
  local init_data=$2
  local existing_proxy="${3:-}"
  
  if [[ -n "$existing_proxy" ]] && [[ "$existing_proxy" != "null" ]] && [[ "$existing_proxy" != "" ]]; then
    local code=$("$CAST" code "$existing_proxy" --rpc-url "$RPC_URL" 2>/dev/null | head -1)
    if [[ "$code" != "0x" ]]; then
      echo "$existing_proxy"
      return 0
    fi
  fi
  
  PROXY_OUT=$("$FORGE" create lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast \
    --constructor-args "$impl" "$init_data" 2>&1)
  
  # Check for specific error patterns
  if echo "$PROXY_OUT" | grep -q "0x4c9c8ce3"; then
    echo "ERROR: ERC1967InvalidImplementation - The implementation contract may not be properly deployed or doesn't support UUPS pattern" >&2
    echo "       Implementation address: $impl" >&2
    echo "       Please verify the implementation was deployed correctly." >&2
  fi
  
  if [[ $? -ne 0 ]] || ! echo "$PROXY_OUT" | grep -q "Deployed to:"; then
    echo "ERROR: Proxy deployment failed!" >&2
    echo "Error output:" >&2
    echo "$PROXY_OUT" | grep -E "(Error|error|revert|Revert)" | head -5 >&2
    return 1
  fi
  
  PROXY=$(grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" <<<"$PROXY_OUT" | awk '{print $3}')
  echo "$PROXY"
}

# stETH→Bagm (Custom Feed with Normalization - Bag of Memes)
# RateSource=WSTETH_CHAINLINK (3)
# Custom feeds: DOGE, SHIB, PEPE, TRUMP, WIF
# USD feed: stETH/USD (via ETH/USD conversion - we'll use a calculated feed or direct stETH/USD if available)
# aggregationDivisor: 5 (average of 5 coins)
# invertPrice: false (to get stETH/basket)

echo "Deploying stETH→Bagm oracle..."

# Note: The USD feed should be stETH/USD. If a direct feed doesn't exist on Base,
# you may need to use ETH/USD and handle stETH/ETH conversion separately, or
# provide a custom stETH/USD feed address via STETH_USD_FEED environment variable
CUSTOM_FEEDS_ARRAY="[$DOGE_USD_FEED,$SHIB_USD_FEED,$PEPE_USD_FEED,$TRUMP_USD_FEED,$WIF_USD_FEED]"
NORMALIZATION_FACTORS_ARRAY="[$DOGE_NORM_FACTOR,$SHIB_NORM_FACTOR,$PEPE_NORM_FACTOR,$TRUMP_NORM_FACTOR,$WIF_NORM_FACTOR]"

# Verify feeds exist before deployment
echo "=== VERIFYING FEEDS ==="
FEEDS_VALID=true
for feed_name in "DOGE" "SHIB" "PEPE" "TRUMP" "WIF"; do
  feed_var="${feed_name}_USD_FEED"
  feed_addr="${!feed_var}"
  code=$("$CAST" code "$feed_addr" --rpc-url "$RPC_URL" 2>/dev/null | head -1)
  if [[ "$code" == "0x" ]] || [[ -z "$code" ]]; then
    echo "❌ $feed_name feed ($feed_addr): No code" >&2
    FEEDS_VALID=false
  else
    decimals=$("$CAST" call "$feed_addr" "decimals()(uint8)" --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
    if [[ "$decimals" == "0" ]]; then
      echo "⚠️  $feed_name feed ($feed_addr): decimals() returned 0 or call failed" >&2
    else
      echo "✓ $feed_name feed ($feed_addr): decimals=$decimals"
    fi
  fi
done

# Verify USD feed
code=$("$CAST" code "$STETH_USD_FEED" --rpc-url "$RPC_URL" 2>/dev/null | head -1)
if [[ "$code" == "0x" ]] || [[ -z "$code" ]]; then
  echo "❌ stETH/USD feed ($STETH_USD_FEED): No code" >&2
  FEEDS_VALID=false
else
  decimals=$("$CAST" call "$STETH_USD_FEED" "decimals()(uint8)" --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
  if [[ "$decimals" == "0" ]]; then
    echo "⚠️  stETH/USD feed ($STETH_USD_FEED): decimals() returned 0 or call failed" >&2
  else
    echo "✓ stETH/USD feed ($STETH_USD_FEED): decimals=$decimals"
  fi
fi

# Verify wstETH/stETH rate feed
code=$("$CAST" code "$WSTETH_STETH_FEED" --rpc-url "$RPC_URL" 2>/dev/null | head -1)
if [[ "$code" == "0x" ]] || [[ -z "$code" ]]; then
  echo "❌ wstETH/stETH rate feed ($WSTETH_STETH_FEED): No code" >&2
  FEEDS_VALID=false
else
  decimals=$("$CAST" call "$WSTETH_STETH_FEED" "decimals()(uint8)" --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
  if [[ "$decimals" == "0" ]]; then
    echo "⚠️  wstETH/stETH rate feed ($WSTETH_STETH_FEED): decimals() returned 0 or call failed" >&2
  else
    echo "✓ wstETH/stETH rate feed ($WSTETH_STETH_FEED): decimals=$decimals"
  fi
fi

if [[ "$FEEDS_VALID" != "true" ]]; then
  echo "" >&2
  echo "❌ ERROR: One or more feeds are invalid. Please fix feed addresses and retry." >&2
  exit 1
fi
echo ""

# Initialize with: owner, oracleName, rateSource, customFeeds[], normalizationFactors[], usdFeed, aggregationDivisor, 
#                  customFeedMaxAge, customFeedMaxDev, usdFeedMaxAge, usdFeedMaxDev, invertPrice
INIT_DATA=$("$CAST" calldata "initialize(address,string,uint8,address[],uint256[],address,uint256,uint64,uint256,uint64,uint256,bool)" \
  "$OWNER" "stETHToBagm" 3 "$CUSTOM_FEEDS_ARRAY" "$NORMALIZATION_FACTORS_ARRAY" "$STETH_USD_FEED" 5 "$MAX_AGE" "$MAX_DEV" "$MAX_AGE" "$MAX_DEV" false)

if [[ -z "$STETH_BAGM" ]] || [[ "$STETH_BAGM" == "null" ]] || [[ "$STETH_BAGM" == "" ]]; then
  # Verify implementation has code before deploying proxy
  IMPL_CODE=$("$CAST" code "$NORMALIZATION_IMPL" --rpc-url "$RPC_URL" 2>/dev/null | head -1)
  if [[ "$IMPL_CODE" == "0x" ]] || [[ -z "$IMPL_CODE" ]]; then
    echo "❌ ERROR: Implementation contract has no code at $NORMALIZATION_IMPL" >&2
    echo "   Please deploy the implementation first." >&2
    exit 1
  fi
  
  echo "✓ Implementation verified: $NORMALIZATION_IMPL"
  echo "  Initializing proxy with provided feeds..."
  
  STETH_BAGM=$(deploy_proxy "$NORMALIZATION_IMPL" "$INIT_DATA")
  if [[ $? -ne 0 ]]; then
    echo "" >&2
    echo "❌ Proxy deployment failed. Common causes:" >&2
    echo "   1. One or more feed addresses are invalid or not deployed" >&2
    echo "   2. Feed decimals() returns 0 (feed not properly configured)" >&2
    echo "   3. Rate source validation failed (WSTETH_STETH_FEED check)" >&2
    echo "   4. Normalization factors contain invalid values" >&2
    echo "" >&2
    echo "   Please verify all feed addresses are correct:" >&2
    echo "     DOGE: $DOGE_USD_FEED" >&2
    echo "     SHIB: $SHIB_USD_FEED" >&2
    echo "     PEPE: $PEPE_USD_FEED" >&2
    echo "     TRUMP: $TRUMP_USD_FEED" >&2
    echo "     WIF: $WIF_USD_FEED" >&2
    echo "     stETH/USD: $STETH_USD_FEED" >&2
    echo "     wstETH/stETH: $WSTETH_STETH_FEED" >&2
    exit 1
  fi
  save_state
else
  echo "✓ stETH→Bagm already deployed: $STETH_BAGM"
fi

echo ""
echo "=== DEPLOYMENT SUMMARY ==="
echo ""
echo "LIBRARY:"
echo "  PriceOracle_v1: $PRICE_ORACLE_LIB"
echo ""
echo "IMPLEMENTATIONS:"
echo "  Normalization: $NORMALIZATION_IMPL"
echo ""
echo "ORACLES:"
echo "  stETH→Bagm: $STETH_BAGM"
echo ""
echo "Configuration:"
echo "  Custom Feeds: DOGE, SHIB, PEPE, TRUMP, WIF"
echo "  Normalization Factors:"
echo "    DOGE:  $DOGE_NORM_FACTOR (multiply by 168.2)"
echo "    SHIB:  $SHIB_NORM_FACTOR (multiply by 589,500)"
echo "    PEPE:  $PEPE_NORM_FACTOR (multiply by 421,000)"
echo "    TRUMP: $TRUMP_NORM_FACTOR (multiply by ~0.99884, minimal change)"
echo "    WIF:   $WIF_NORM_FACTOR (multiply by 1, no change)"
echo "  Aggregation Divisor: 5 (average)"
echo "  USD Feed: $STETH_USD_FEED"
echo "  Rate Source: WSTETH_CHAINLINK (3)"

# Configure rate source staleness
echo ""
echo "=== CONFIGURING RATE SOURCE STALENESS ==="
echo "Setting maxRateSourceAge to ${MAX_RATE_SOURCE_AGE} seconds..."

# First check current value
CURRENT_AGE=$("$CAST" call "$STETH_BAGM" "maxRateSourceAge()(uint64)" --rpc-url "$RPC_URL" 2>/dev/null | tr -d '[:space:]' || echo "0")
echo "  Current maxRateSourceAge: $CURRENT_AGE seconds"

# Try to set it
SET_OUTPUT=$("$CAST" send "$STETH_BAGM" "setMaxRateSourceAge(uint64)" "$MAX_RATE_SOURCE_AGE" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --broadcast 2>&1)
SET_EXIT_CODE=$?

if [[ $SET_EXIT_CODE -eq 0 ]]; then
  echo "✓ Rate source staleness configured"
  
  # Verify it was set correctly
  NEW_AGE=$("$CAST" call "$STETH_BAGM" "maxRateSourceAge()(uint64)" --rpc-url "$RPC_URL" 2>/dev/null | tr -d '[:space:]' || echo "0")
  if [[ "$NEW_AGE" == "$MAX_RATE_SOURCE_AGE" ]]; then
    echo "  ✓ Verified: maxRateSourceAge = $NEW_AGE"
  else
    echo "  ⚠️  Warning: maxRateSourceAge mismatch (expected $MAX_RATE_SOURCE_AGE, got $NEW_AGE)" >&2
  fi
else
  echo "✗ Failed to configure rate source staleness" >&2
  echo "  Error output:" >&2
  echo "$SET_OUTPUT" | sed 's/^/    /' >&2
  echo "" >&2
  echo "  You may need to set it manually using:" >&2
  echo "  cast send $STETH_BAGM \"setMaxRateSourceAge(uint64)\" $MAX_RATE_SOURCE_AGE --rpc-url \$RPC_URL --private-key \$PRIVATE_KEY --broadcast" >&2
fi

# Test price and rate readout
echo ""
echo "=== PRICE & RATE READOUT ==="

# Helper function to safely call cast with optional timeout (works on macOS without timeout command)
safe_cast_call() {
  local contract=$1
  local method=$2
  local label=$3
  
  echo -n "$label: "
  
  # Try with timeout if available (Linux), otherwise just run directly (macOS)
  if command -v timeout >/dev/null 2>&1; then
    OUTPUT=$(timeout 30 "$CAST" call "$contract" "$method" --rpc-url "$RPC_URL" 2>&1) || true
  else
    # On macOS without timeout, just run it (if it hangs, user can Ctrl+C)
    OUTPUT=$("$CAST" call "$contract" "$method" --rpc-url "$RPC_URL" 2>&1) || true
  fi
  
  if [[ -n "$OUTPUT" ]] && [[ "$OUTPUT" =~ ^[0-9]+$ ]]; then
    CLEAN=$(echo "$OUTPUT" | tr -d '[:space:]')
    FORMATTED=$(printf "%.6e" "$CLEAN" 2>/dev/null || echo "$CLEAN")
    echo "$CLEAN [$FORMATTED]"
  else
    echo "N/A"
    if [[ -n "$OUTPUT" ]] && ! echo "$OUTPUT" | grep -q "^[0-9]"; then
      echo "    Error: $OUTPUT" >&2
      # Try to decode common errors
      if echo "$OUTPUT" | grep -q "ConstraintsNotSet"; then
        echo "    → One or more feed constraints are not set." >&2
      elif echo "$OUTPUT" | grep -q "InvalidPrice"; then
        echo "    → One or more feeds returned invalid/zero price." >&2
      elif echo "$OUTPUT" | grep -q "Stale"; then
        echo "    → One or more feeds are stale (exceeded max age)." >&2
      elif echo "$OUTPUT" | grep -q "UnderlyingPriceDeviation\|maxAbsoluteDeviation"; then
        echo "    → Price deviation check failed." >&2
      fi
    fi
  fi
}

# Call price and rate readouts
safe_cast_call "$STETH_BAGM" "getPrice()(uint256)" "  stETH→Bagm Price"
safe_cast_call "$STETH_BAGM" "getRate()(uint256)" "  Rate (wstETH/stETH)"

echo ""
echo "=== VERIFICATION COMMANDS ==="
echo ""

# Pre-compute constructor args for implementation
IMPL_CONSTRUCTOR_ARGS=$("$CAST" abi-encode "constructor(address,address,address,address)" "$WSTETH" "$FXSAVE" "$SUSDE_USDE_FEED" "$WSTETH_STETH_FEED")

echo "# Verify Implementation:"
echo "$FORGE verify-contract \\"
echo "  $NORMALIZATION_IMPL \\"
echo "  src/price/HarborCustomFeedNormalization_v2.sol:HarborCustomFeedNormalization_v2 \\"
echo "  --verifier etherscan \\"
echo "  --etherscan-api-key \$ETHERSCAN_API_KEY \\"
echo "  --libraries src/price/PriceOracle_v1.sol:PriceOracle_v1:$PRICE_ORACLE_LIB \\"
echo "  --constructor-args $IMPL_CONSTRUCTOR_ARGS \\"
echo "  --compiler-version 0.8.30 \\"
echo "  --chain base"
echo ""

echo "# Verify Proxy:"
PROXY_ARGS=$("$CAST" abi-encode "constructor(address,bytes)" "$NORMALIZATION_IMPL" "$INIT_DATA")
echo "$FORGE verify-contract \\"
echo "  $STETH_BAGM \\"
echo "  lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \\"
echo "  --verifier etherscan \\"
echo "  --etherscan-api-key \$ETHERSCAN_API_KEY \\"
echo "  --constructor-args $PROXY_ARGS \\"
echo "  --compiler-version 0.8.30 \\"
echo "  --chain base"
echo ""

echo "✅ Deployment complete!"
echo ""
echo "=== STATE FILE ==="
echo "Deployment state saved to: $STATE_FILE"
echo ""
save_state

