#!/usr/bin/env bash
set -euo pipefail

# Re-verify all Arbitrum v3 oracles
# This script reads from deployments/arbitrum/v3-oracles.json and verifies all contracts

# Use full path to forge/cast
FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CAST=${CAST:-$HOME/.foundry/bin/cast}

# Load environment variables from .env if it exists
if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

# Required environment variables
if [[ -z "${ARBITRUM_RPC_URL:-}" ]]; then
  echo "❌ ERROR: ARBITRUM_RPC_URL is not set"
  echo "   Set it via: export ARBITRUM_RPC_URL='your_rpc_url'"
  exit 1
fi

if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "❌ ERROR: ETHERSCAN_API_KEY is not set"
  echo "   Set it via: export ETHERSCAN_API_KEY='your_api_key'"
  exit 1
fi

# Deployment file
DEPLOYMENT_FILE="deployments/arbitrum/v3-oracles.json"

if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  echo "❌ ERROR: Deployment file not found: $DEPLOYMENT_FILE"
  echo "   Run the deployment script first: ./script/deploy-arbitrum-v3-oracles.sh"
  exit 1
fi

# Check network
CHAIN_ID=$("$CAST" chain-id --rpc-url "$ARBITRUM_RPC_URL" 2>/dev/null || echo "unknown")
echo "=== Network Check ==="
echo "RPC URL: $ARBITRUM_RPC_URL"
echo "Chain ID: $CHAIN_ID"
if [[ "$CHAIN_ID" != "0xa4b1" ]] && [[ "$CHAIN_ID" != "42161" ]]; then
  echo "⚠️  WARNING: Expected Arbitrum chain ID (42161), got: $CHAIN_ID"
  echo "   Press Ctrl+C to cancel, or wait 5 seconds to continue..."
  sleep 5
fi
echo ""

# Function to verify a contract
verify_contract() {
  local address=$1
  local contract_path=$2
  local contract_name=$3
  
  echo "Verifying $contract_name at $address..."
  
  # Check if contract exists on chain
  local code=$("$CAST" code "$address" --rpc-url "$ARBITRUM_RPC_URL" 2>/dev/null | head -1 || echo "0x")
  if [[ "$code" == "0x" ]]; then
    echo "  ❌ No contract code at address"
    return 1
  fi
  
  # Try to verify with retries
  local max_retries=3
  local retry=0
  local success=false
  
  while [[ $retry -lt $max_retries ]]; do
    local verify_output
    verify_output=$("$FORGE" verify-contract \
      "$address" \
      "$contract_path" \
      --verifier etherscan \
      --etherscan-api-key "$ETHERSCAN_API_KEY" \
      --compiler-version 0.8.30 \
      --chain arbitrum \
      --watch 2>&1)
    
    if echo "$verify_output" | grep -q "Contract successfully verified"; then
      echo "  ✅ Verified successfully"
      success=true
      break
    elif echo "$verify_output" | grep -qi "already verified"; then
      echo "  ✅ Already verified"
      success=true
      break
    else
      retry=$((retry + 1))
      if [[ $retry -lt $max_retries ]]; then
        echo "  ⏳ Retrying verification ($retry/$max_retries)..."
        sleep 5
      else
        echo "  ❌ Verification failed"
        echo "  Error output:"
        echo "$verify_output" | grep -E "(Error|error|Failed|failed)" | head -5
      fi
    fi
  done
  
  if [[ "$success" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# Get all oracles from deployment file
echo "=== Reading Deployment File ==="
echo "File: $DEPLOYMENT_FILE"
echo ""

# Extract oracle count
ORACLE_COUNT=$(jq '.oracles | length' "$DEPLOYMENT_FILE" 2>/dev/null || echo "0")
if [[ "$ORACLE_COUNT" == "0" ]]; then
  echo "❌ No oracles found in deployment file"
  exit 1
fi

echo "Found $ORACLE_COUNT oracles to verify"
echo ""

# Verify all oracles
TOTAL=0
SUCCESS=0
FAILED=0
ALREADY_VERIFIED=0

# Read oracles from JSON and verify each one
while IFS= read -r oracle_key; do
  TOTAL=$((TOTAL + 1))
  
  address=$(jq -r ".oracles[\"$oracle_key\"].address // empty" "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
  contract_path=$(jq -r ".oracles[\"$oracle_key\"].contractPath // empty" "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
  name=$(jq -r ".oracles[\"$oracle_key\"].name // \"$oracle_key\"" "$DEPLOYMENT_FILE" 2>/dev/null || echo "$oracle_key")
  
  if [[ -z "$address" ]] || [[ "$address" == "null" ]] || [[ -z "$contract_path" ]] || [[ "$contract_path" == "null" ]]; then
    echo "[$TOTAL] $oracle_key: ⚠️  Missing address or contract path"
    FAILED=$((FAILED + 1))
    continue
  fi
  
  echo "[$TOTAL/$ORACLE_COUNT] $name"
  
  # Check if already verified by trying to get contract info from Etherscan
  # (This is a simple check - actual verification will confirm)
  if verify_contract "$address" "$contract_path" "$name"; then
    SUCCESS=$((SUCCESS + 1))
  else
    # Check if it's already verified
    verify_output=$("$FORGE" verify-contract \
      "$address" \
      "$contract_path" \
      --verifier etherscan \
      --etherscan-api-key "$ETHERSCAN_API_KEY" \
      --compiler-version 0.8.30 \
      --chain arbitrum 2>&1 || true)
    
    if echo "$verify_output" | grep -qi "already verified"; then
      echo "  ✅ Already verified on Arbiscan"
      ALREADY_VERIFIED=$((ALREADY_VERIFIED + 1))
      SUCCESS=$((SUCCESS + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  fi
  
  # Small delay between verifications
  sleep 2
  echo ""
  
done < <(jq -r '.oracles | keys[]' "$DEPLOYMENT_FILE" 2>/dev/null || echo "")

echo "=== Verification Summary ==="
echo "Total: $TOTAL"
echo "Successfully verified: $SUCCESS"
echo "Already verified: $ALREADY_VERIFIED"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "✅ All contracts verified!"
else
  echo "⚠️  Some contracts failed verification. Check the output above for details."
  echo ""
  echo "To manually verify a contract, use:"
  echo "  $FORGE verify-contract \\"
  echo "    <ADDRESS> \\"
  echo "    <CONTRACT_PATH> \\"
  echo "    --verifier etherscan \\"
  echo "    --etherscan-api-key \$ETHERSCAN_API_KEY \\"
  echo "    --compiler-version 0.8.30 \\"
  echo "    --chain arbitrum"
  exit 1
fi

