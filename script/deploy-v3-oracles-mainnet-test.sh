#!/usr/bin/env bash
set -euo pipefail

# Harbor V3 Oracle Deployment Script - Mainnet (Test Deployment)
# Deploys v3 oracle contracts to regular addresses (not predictable) for on-chain verification
# before using the predictable address deployment script
#
# Configuration:
#   - Set RPC_URL, PRIVATE_KEY, and ETHERSCAN_API_KEY as environment variables, or
#   - Create a .env file in the project root

# Get script directory and change to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Use full path to forge/cast
FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CAST=${CAST:-$HOME/.foundry/bin/cast}

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

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  echo "   Set it via: export PRIVATE_KEY='your_private_key'"
  exit 1
fi

# ETHERSCAN_API_KEY is optional (only needed for verification)
ETHERSCAN_API_KEY=${ETHERSCAN_API_KEY:-}

# Note: All addresses are hardcoded in the contract constructors via MainnetOracleAddresses.sol
# No constructor arguments needed - the mainnet contracts have no-arg constructors

# Check network
CHAIN_ID=$("$CAST" chain-id --rpc-url "$RPC_URL" 2>/dev/null || echo "unknown")
echo "=== Network Check ==="
echo "RPC URL: $RPC_URL"
echo "Chain ID: $CHAIN_ID"
if [[ "$CHAIN_ID" != "0x1" ]] && [[ "$CHAIN_ID" != "1" ]]; then
  echo "⚠️  WARNING: Expected Mainnet chain ID (1), got: $CHAIN_ID"
  echo "   Press Ctrl+C to cancel, or wait 5 seconds to continue..."
  sleep 5
fi
echo ""

# State file for tracking deployments
STATE_FILE="${STATE_FILE:-deployment-state-v3-mainnet-test.json}"

# Function to save deployment address
save_deployment() {
  local name=$1
  local address=$2
  local jq_cmd=".deployments.\"$name\" = \"$address\""
  
  if [[ -f "$STATE_FILE" ]]; then
    jq "$jq_cmd" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  else
    echo "{\"deployments\": {\"$name\": \"$address\"}, \"deployment_time\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$STATE_FILE"
  fi
}

# Function to get deployment address from state
get_deployment() {
  local name=$1
  if [[ -f "$STATE_FILE" ]]; then
    jq -r ".deployments.\"$name\" // empty" "$STATE_FILE" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Function to deploy an oracle contract
deploy_oracle() {
  local contract_name=$1
  local contract_path=$2
  
  echo "📦 Deploying $contract_name..."
  
  local deploy_out=$("$FORGE" create "$contract_path" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast 2>&1)
  
  local address=$(echo "$deploy_out" | grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" | awk '{print $3}')
  
  if [[ -z "$address" ]]; then
    echo "  ❌ Failed to deploy $contract_name"
    echo "$deploy_out"
    exit 1
  fi
  
  echo "  ✓ Deployed to: $address"
  save_deployment "$contract_name" "$address"
  echo ""
  
  echo "$address"
}

# Function to verify contract on Etherscan
verify_contract() {
  local contract_name=$1
  local contract_path=$2
  local address=$3
  
  if [[ -z "$ETHERSCAN_API_KEY" ]]; then
    echo "  ⚠️  Skipping verification (ETHERSCAN_API_KEY not set)"
    return
  fi
  
  echo "  🔍 Verifying $contract_name on Etherscan..."
  
  local verify_out=$("$FORGE" verify-contract \
    "$address" \
    "$contract_path" \
    --rpc-url "$RPC_URL" \
    --etherscan-api-key "$ETHERSCAN_API_KEY" 2>&1)
  
  if echo "$verify_out" | grep -q "OK" || echo "$verify_out" | grep -q "already verified"; then
    echo "  ✓ Verified successfully"
  else
    echo "  ⚠️  Verification failed or pending:"
    echo "$verify_out"
  fi
  echo ""
}

# Deploy fxUSD oracles (single feed, using FXSAVE rate)
echo "=== Deploying fxUSD Oracles ==="
echo ""

FXUSD_BTC=$(get_deployment "Oracle_fxUSD_BTC_mainnet")
if [[ -z "$FXUSD_BTC" ]]; then
  FXUSD_BTC=$(deploy_oracle "Oracle_fxUSD_BTC_mainnet" \
    "src/Oracle_fxUSD_BTC_mainnet.sol:Oracle_fxUSD_BTC_mainnet")
fi

FXUSD_EUR=$(get_deployment "Oracle_fxUSD_EUR_mainnet")
if [[ -z "$FXUSD_EUR" ]]; then
  FXUSD_EUR=$(deploy_oracle "Oracle_fxUSD_EUR_mainnet" \
    "src/Oracle_fxUSD_EUR_mainnet.sol:Oracle_fxUSD_EUR_mainnet")
fi

FXUSD_ETH=$(get_deployment "Oracle_fxUSD_ETH_mainnet")
if [[ -z "$FXUSD_ETH" ]]; then
  FXUSD_ETH=$(deploy_oracle "Oracle_fxUSD_ETH_mainnet" \
    "src/Oracle_fxUSD_ETH_mainnet.sol:Oracle_fxUSD_ETH_mainnet")
fi

FXUSD_MCAP=$(get_deployment "Oracle_fxUSD_MCAP_mainnet")
if [[ -z "$FXUSD_MCAP" ]]; then
  FXUSD_MCAP=$(deploy_oracle "Oracle_fxUSD_MCAP_mainnet" \
    "src/Oracle_fxUSD_MCAP_mainnet.sol:Oracle_fxUSD_MCAP_mainnet")
fi

FXUSD_XAU=$(get_deployment "Oracle_fxUSD_XAU_mainnet")
if [[ -z "$FXUSD_XAU" ]]; then
  FXUSD_XAU=$(deploy_oracle "Oracle_fxUSD_XAU_mainnet" \
    "src/Oracle_fxUSD_XAU_mainnet.sol:Oracle_fxUSD_XAU_mainnet")
fi

# Deploy stETH oracles (double feed, using WSTETH rate)
echo "=== Deploying stETH Oracles ==="
echo ""

STETH_BTC=$(get_deployment "Oracle_stETH_BTC_mainnet")
if [[ -z "$STETH_BTC" ]]; then
  STETH_BTC=$(deploy_oracle "Oracle_stETH_BTC_mainnet" \
    "src/Oracle_stETH_BTC_mainnet.sol:Oracle_stETH_BTC_mainnet")
fi

STETH_EUR=$(get_deployment "Oracle_stETH_EUR_mainnet")
if [[ -z "$STETH_EUR" ]]; then
  STETH_EUR=$(deploy_oracle "Oracle_stETH_EUR_mainnet" \
    "src/Oracle_stETH_EUR_mainnet.sol:Oracle_stETH_EUR_mainnet")
fi

STETH_MCAP=$(get_deployment "Oracle_stETH_MCAP_mainnet")
if [[ -z "$STETH_MCAP" ]]; then
  STETH_MCAP=$(deploy_oracle "Oracle_stETH_MCAP_mainnet" \
    "src/Oracle_stETH_MCAP_mainnet.sol:Oracle_stETH_MCAP_mainnet")
fi

STETH_XAU=$(get_deployment "Oracle_stETH_XAU_mainnet")
if [[ -z "$STETH_XAU" ]]; then
  STETH_XAU=$(deploy_oracle "Oracle_stETH_XAU_mainnet" \
    "src/Oracle_stETH_XAU_mainnet.sol:Oracle_stETH_XAU_mainnet")
fi

# Summary
echo "=== Deployment Summary ==="
echo ""
echo "fxUSD Oracles:"
echo "  Oracle_fxUSD_BTC_mainnet:  $FXUSD_BTC"
echo "  Oracle_fxUSD_EUR_mainnet:  $FXUSD_EUR"
echo "  Oracle_fxUSD_ETH_mainnet:  $FXUSD_ETH"
echo "  Oracle_fxUSD_MCAP_mainnet: $FXUSD_MCAP"
echo "  Oracle_fxUSD_XAU_mainnet:  $FXUSD_XAU"
echo ""
echo "stETH Oracles:"
echo "  Oracle_stETH_BTC_mainnet:  $STETH_BTC"
echo "  Oracle_stETH_EUR_mainnet:  $STETH_EUR"
echo "  Oracle_stETH_MCAP_mainnet: $STETH_MCAP"
echo "  Oracle_stETH_XAU_mainnet:  $STETH_XAU"
echo ""
echo "State saved to: $STATE_FILE"
echo ""

# Verify contracts if ETHERSCAN_API_KEY is set
if [[ -n "$ETHERSCAN_API_KEY" ]]; then
  echo "=== Verifying Contracts on Etherscan ==="
  echo ""
  
  verify_contract "Oracle_fxUSD_BTC_mainnet" "src/Oracle_fxUSD_BTC_mainnet.sol:Oracle_fxUSD_BTC_mainnet" "$FXUSD_BTC"
  verify_contract "Oracle_fxUSD_EUR_mainnet" "src/Oracle_fxUSD_EUR_mainnet.sol:Oracle_fxUSD_EUR_mainnet" "$FXUSD_EUR"
  verify_contract "Oracle_fxUSD_ETH_mainnet" "src/Oracle_fxUSD_ETH_mainnet.sol:Oracle_fxUSD_ETH_mainnet" "$FXUSD_ETH"
  verify_contract "Oracle_fxUSD_MCAP_mainnet" "src/Oracle_fxUSD_MCAP_mainnet.sol:Oracle_fxUSD_MCAP_mainnet" "$FXUSD_MCAP"
  verify_contract "Oracle_fxUSD_XAU_mainnet" "src/Oracle_fxUSD_XAU_mainnet.sol:Oracle_fxUSD_XAU_mainnet" "$FXUSD_XAU"
  verify_contract "Oracle_stETH_BTC_mainnet" "src/Oracle_stETH_BTC_mainnet.sol:Oracle_stETH_BTC_mainnet" "$STETH_BTC"
  verify_contract "Oracle_stETH_EUR_mainnet" "src/Oracle_stETH_EUR_mainnet.sol:Oracle_stETH_EUR_mainnet" "$STETH_EUR"
  verify_contract "Oracle_stETH_MCAP_mainnet" "src/Oracle_stETH_MCAP_mainnet.sol:Oracle_stETH_MCAP_mainnet" "$STETH_MCAP"
  verify_contract "Oracle_stETH_XAU_mainnet" "src/Oracle_stETH_XAU_mainnet.sol:Oracle_stETH_XAU_mainnet" "$STETH_XAU"
else
  echo ""
  echo "ℹ️  To verify contracts on Etherscan, set ETHERSCAN_API_KEY environment variable"
fi

echo "✅ Deployment complete!"

