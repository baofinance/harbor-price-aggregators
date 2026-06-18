#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

# Verify all MegaETH v4 oracles on Blockscout or Etherscan
# Usage: ./script/verify-megaeth-v4-oracles.sh [blockscout|etherscan]
# Default: blockscout
# This script reads from deployments/megaeth/v4-aggregators.json (preferred)
# or deployments/megaeth/v4-oracles.json (legacy) and verifies all contracts

# Use full path to forge
FORGE=${FORGE:-$HOME/.foundry/bin/forge}

# Load environment variables from .env if it exists
if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

# Parse command line argument for verifier choice
VERIFIER=${1:-blockscout}
if [[ "$VERIFIER" != "blockscout" ]] && [[ "$VERIFIER" != "etherscan" ]]; then
  echo "❌ ERROR: Invalid verifier: $VERIFIER"
  echo "   Usage: $0 [blockscout|etherscan]"
  echo "   Default: blockscout"
  exit 1
fi

# Required environment variables
if [[ -z "${MEGAETH_RPC_URL:-}" ]]; then
  echo "❌ ERROR: MEGAETH_RPC_URL is not set"
  echo "   Set it via: export MEGAETH_RPC_URL='https://mainnet.megaeth.com/rpc'"
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

# For Etherscan, require API key
if [[ "$VERIFIER" == "etherscan" ]]; then
  if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
    echo "❌ ERROR: ETHERSCAN_API_KEY is not set (required for Etherscan verification)"
    echo "   Set it via: export ETHERSCAN_API_KEY='your_api_key'"
    echo "   Or add it to a .env file in the project root"
    exit 1
  fi
  
  # Check if MegaETH Etherscan API URL is set
  if [[ -z "${MEGAETH_ETHERSCAN_API_URL:-}" ]]; then
    echo "ℹ️  Using Etherscan API V2: https://api.etherscan.io/v2/api"
    echo "   Chain ID 4326 will be included in the request"
    echo "   To use a different URL, set:"
    echo "   export MEGAETH_ETHERSCAN_API_URL='https://api.etherscan.io/v2/api'"
    echo ""
  fi
else
  # Blockscout doesn't require an API key, but forge still checks for ETHERSCAN_KEY
  # Set a dummy value if not set (Blockscout won't use it)
  export ETHERSCAN_KEY=${ETHERSCAN_KEY:-"dummy"}
fi

if [[ -f "deployments/megaeth/v4-aggregators.json" ]]; then
  DEPLOYMENT_FILE="deployments/megaeth/v4-aggregators.json"
elif [[ -f "deployments/megaeth/v4-oracles.json" ]]; then
  DEPLOYMENT_FILE="deployments/megaeth/v4-oracles.json"
else
  echo "❌ ERROR: Deployment file not found:"
  echo "   - deployments/megaeth/v4-aggregators.json"
  echo "   - deployments/megaeth/v4-oracles.json"
  echo "   Run deployment first"
  exit 1
fi

echo "=== Verifying MegaETH v4 Oracles ==="
echo "Verifier: $VERIFIER"
echo "RPC URL: $MEGAETH_RPC_URL"
echo ""

# Function to verify a contract
verify_contract() {
  local address=$1
  local contract_path=$2
  local contract_name=$3
  
  echo "Verifying $contract_name at $address..."
  
  local verify_output
  
  if [[ "$VERIFIER" == "etherscan" ]]; then
    # Verify using Etherscan API V2
    # MegaETH uses Etherscan API V2 with chain ID 4326
    # Use --verifier-url to specify the API endpoint directly
    # Forge will handle all source files and dependencies automatically
    ETHERSCAN_API_URL=${MEGAETH_ETHERSCAN_API_URL:-"https://api.etherscan.io/v2/api"}
    
    verify_output=$("$FORGE" verify-contract \
      --rpc-url "$MEGAETH_RPC_URL" \
      --verifier etherscan \
      --verifier-url "$ETHERSCAN_API_URL" \
      --etherscan-api-key "$ETHERSCAN_API_KEY" \
      "$address" \
      "$contract_path" \
      --compiler-version 0.8.30 2>&1 || echo "VERIFY_ERROR")
    
    verifier_name="Etherscan"
  else
    # Verify using Blockscout (default)
    # Note: Blockscout doesn't require an API key, but forge checks for ETHERSCAN_KEY
    # We set a dummy value above if it wasn't already set, and pass it explicitly
    verify_output=$("$FORGE" verify-contract \
      --rpc-url "$MEGAETH_RPC_URL" \
      --verifier blockscout \
      --verifier-url "https://megaeth.blockscout.com/api/" \
      --etherscan-api-key "$ETHERSCAN_KEY" \
      "$address" \
      "$contract_path" \
      --compiler-version 0.8.30 2>&1 || echo "VERIFY_ERROR")
    
    verifier_name="Blockscout"
  fi
  
  if echo "$verify_output" | grep -q "Contract successfully verified"; then
    echo "  ✅ Verified successfully on $verifier_name"
    return 0
  elif echo "$verify_output" | grep -qi "already verified"; then
    echo "  ✅ Already verified on $verifier_name"
    return 0
  elif echo "$verify_output" | grep -qi "submitted\|pending\|waiting"; then
    echo "  ⏳ Verification submitted (check $verifier_name in a few minutes)"
    return 0
  elif echo "$verify_output" | grep -qi "VERIFY_ERROR\|Error\|error"; then
    echo "  ❌ Verification failed"
    echo "  Full error output:"
    echo "$verify_output" | head -20
    return 1
  else
    echo "  ⏳ Verification request submitted to $verifier_name"
    return 0
  fi
}

# Read all oracles from deployment file
TOTAL=0
SUCCESS=0
FAILED=0

# Extract all entries (supports both .oracles and .implementations schemas)
if jq -e '.oracles' "$DEPLOYMENT_FILE" >/dev/null 2>&1; then
  ENTRY_STREAM='jq -c ".oracles | to_entries[]" "$DEPLOYMENT_FILE"'
else
  ENTRY_STREAM='jq -c ".implementations | to_entries[]" "$DEPLOYMENT_FILE"'
fi

while IFS= read -r line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  
  oracle_key=$(echo "$line" | jq -r '.key' 2>/dev/null || echo "")
  # v4-oracles schema stores address at .value.address; v4-aggregators schema uses .key
  address=$(echo "$line" | jq -r '.value.address // .key // empty' 2>/dev/null || echo "")
  contract_path=$(echo "$line" | jq -r '.value.contractPath // .value.contractSource // empty' 2>/dev/null || echo "")
  contract_type=$(echo "$line" | jq -r '.value.contractType // empty' 2>/dev/null || echo "")
  name=$(echo "$line" | jq -r '.value.name // .value.pair // .key // empty' 2>/dev/null || echo "")

  # For v4-aggregators schema, contract path is split into source+type.
  if [[ "$contract_path" == *.sol ]] && [[ -n "$contract_type" ]]; then
    contract_path="${contract_path}:${contract_type}"
  fi
  
  if [[ -z "$oracle_key" ]] || [[ -z "$address" ]] || [[ "$address" == "null" ]] || [[ -z "$contract_path" ]]; then
    continue
  fi
  
  TOTAL=$((TOTAL + 1))
  
  echo "[$TOTAL] $name ($oracle_key)"
  
  if verify_contract "$address" "$contract_path" "$name"; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  
  # Small delay between verifications
  sleep 2
  
  echo ""
done < <(eval "$ENTRY_STREAM" 2>/dev/null || echo "")

echo "=== Implementation verification summary ==="
echo "Total: $TOTAL"
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -gt 0 ]]; then
  echo "⚠️  Some implementations failed verification. Check the output above for details."
  exit 1
fi

# When using Blockscout, also verify proxy contracts (ERC1967Proxy)
if [[ "$VERIFIER" == "blockscout" ]]; then
  if [[ -f "deployments/megaeth/v4-aggregators.json" ]]; then
    STATE_FILE="deployments/megaeth/v4-aggregators.json"
  else
    STATE_FILE="deployments/megaeth/v3-aggregators.json"
  fi
  if [[ -f "$STATE_FILE" ]] && jq -e '.proxies | length > 0' "$STATE_FILE" >/dev/null 2>&1; then
    echo "✅ All implementation contracts verified on Blockscout."
    echo ""
    echo "=== Verifying proxy contracts on Blockscout ==="
    if "$SCRIPT_DIR/verify-megaeth-proxies.sh" blockscout; then
      echo ""
      echo "✅ All proxies verified on Blockscout."
    else
      echo ""
      echo "⚠️  Some proxies failed Blockscout verification. Re-run: ./script/megaeth/verify/verify-megaeth-proxies.sh blockscout"
    fi
  else
    echo "✅ All contracts verified successfully on $VERIFIER!"
  fi
else
  echo "✅ All contracts verified successfully on $VERIFIER!"
  echo "   (Proxy verification on Etherscan: ./script/megaeth/verify/verify-megaeth-proxies.sh etherscan)"
fi
