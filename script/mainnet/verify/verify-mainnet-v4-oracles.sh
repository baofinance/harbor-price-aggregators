#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Verify all Mainnet v4 oracles on Etherscan
# This script reads from deployments/mainnet/v4-oracles.json and verifies all contracts

# Use full path to forge
FORGE=${FORGE:-$HOME/.foundry/bin/forge}

# Load environment variables from .env if it exists
if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

# Required environment variables
if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "❌ ERROR: ETHERSCAN_API_KEY is not set"
  echo "   Set it via: export ETHERSCAN_API_KEY='your_api_key'"
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

DEPLOYMENT_FILE="deployments/mainnet/v4-oracles.json"

if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  echo "❌ ERROR: Deployment file not found: $DEPLOYMENT_FILE"
  echo "   Run deploy-mainnet-v4-oracles.sh first"
  exit 1
fi

echo "=== Verifying Mainnet v4 Oracles ==="
echo ""

# Function to verify a contract
verify_contract() {
  local address=$1
  local contract_path=$2
  local contract_name=$3
  
  echo "Verifying $contract_name at $address..."
  
  # Submit verification request
  local verify_output
  verify_output=$("$FORGE" verify-contract \
    "$address" \
    "$contract_path" \
    --verifier etherscan \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --compiler-version 0.8.30 \
    --chain mainnet 2>&1 || echo "VERIFY_ERROR")
  
  if echo "$verify_output" | grep -q "Contract successfully verified"; then
    echo "  ✅ Verified successfully"
    return 0
  elif echo "$verify_output" | grep -qi "already verified"; then
    echo "  ✅ Already verified on Etherscan"
    return 0
  elif echo "$verify_output" | grep -qi "submitted\|pending\|waiting"; then
    echo "  ⏳ Verification submitted (check Etherscan in a few minutes)"
    return 0
  elif echo "$verify_output" | grep -qi "VERIFY_ERROR\|Error\|error"; then
    echo "  ❌ Verification failed"
    echo "  Error:"
    echo "$verify_output" | grep -E "(Error|error|revert|Revert)" | head -3
    return 1
  else
    echo "  ⏳ Verification request submitted"
    return 0
  fi
}

# Read all oracles from deployment file
TOTAL=0
SUCCESS=0
FAILED=0

# Extract all oracle entries
while IFS= read -r line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  
  oracle_key=$(echo "$line" | jq -r '.key' 2>/dev/null || echo "")
  address=$(echo "$line" | jq -r '.value.address // empty' 2>/dev/null || echo "")
  contract_path=$(echo "$line" | jq -r '.value.contractPath // empty' 2>/dev/null || echo "")
  name=$(echo "$line" | jq -r '.value.name // empty' 2>/dev/null || echo "")
  
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
done < <(jq -c '.oracles | to_entries[]' "$DEPLOYMENT_FILE" 2>/dev/null || echo "")

echo "=== Verification Summary ==="
echo "Total: $TOTAL"
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "✅ All contracts verified successfully!"
else
  echo "⚠️  Some contracts failed verification. Check the output above for details."
  exit 1
fi
