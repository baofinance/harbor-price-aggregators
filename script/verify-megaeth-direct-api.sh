#!/usr/bin/env bash
set -euo pipefail

# Verify MegaETH contracts directly via Etherscan API V2 using curl
# This bypasses forge's chain ID check by calling the API directly
# Usage: ./script/verify-megaeth-direct-api.sh [contract_address] [contract_path]
# If no arguments, verifies all contracts from deployment file

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
  exit 1
fi

API_URL="https://api.etherscan.io/v2/api"

# Function to verify a single contract
verify_contract_direct() {
  local address=$1
  local contract_path=$2
  local contract_name=$3
  
  echo "Verifying $contract_name at $address..."
  
  # Extract contract file and contract name
  IFS=':' read -r contract_file contract_name_only <<< "$contract_path"
  
  # Get compiler settings from foundry.toml
  SOLC_VERSION="v0.8.30+commit.73712a01"
  OPTIMIZATION_USED="1"
  OPTIMIZATION_RUNS="700"
  EVM_VERSION="cancun"
  LICENSE_TYPE="3"  # MIT
  
  if [[ -f "foundry.toml" ]]; then
    OPTIMIZATION_RUNS=$(grep "optimizer_runs" foundry.toml 2>/dev/null | head -1 | sed 's/#.*$//' | sed 's/.*=//' | tr -d ' ') || OPTIMIZATION_RUNS="700"
    if ! grep -q "optimizer\s*=\s*true" foundry.toml 2>/dev/null; then
      OPTIMIZATION_USED="0"
    fi
    EVM_VERSION=$(grep "evm_version" foundry.toml 2>/dev/null | head -1 | sed 's/#.*$//' | sed 's/.*=//' | tr -d ' "') || EVM_VERSION="cancun"
  fi
  
  # Use forge's --show-standard-json-input to get the Standard JSON Input
  # This includes all source files and dependencies automatically (no flattening needed!)
  echo "  Generating Standard JSON Input via forge..."
  
  # Get constructor arguments (empty for MegaETH contracts)
  CONSTRUCTOR_ARGS=""
  
  # Use forge to generate the standard JSON input
  # --show-standard-json-input outputs the JSON that forge would send to the verifier
  TEMP_JSON=$(mktemp)
  
  STANDARD_JSON=$("$FORGE" verify-contract \
    --rpc-url "$MEGAETH_RPC_URL" \
    --show-standard-json-input \
    "$address" \
    "$contract_path" \
    --compiler-version 0.8.30 2>&1)
  
  # Extract just the JSON (forge may output other text)
  # The JSON should be valid and parseable
  JSON_CONTENT=$(echo "$STANDARD_JSON" | jq -c '.' 2>/dev/null || echo "")
  
  if [[ -n "$JSON_CONTENT" ]] && echo "$JSON_CONTENT" | jq -e '.sources' > /dev/null 2>&1; then
    echo "  ✓ Got Standard JSON Input from forge (includes all dependencies)"
    echo "$JSON_CONTENT" > "$TEMP_JSON"
    CODE_FORMAT="solidity-standard-json-input"
  else
    echo "  ❌ Could not extract Standard JSON Input from forge output"
    echo "  Forge output:"
    echo "$STANDARD_JSON" | head -20
    rm -f "$TEMP_JSON"
    return 1
  fi
  
  # Prepare API request
  # According to docs, chainid is a query parameter
  API_REQUEST_URL="${API_URL}?apikey=${ETHERSCAN_API_KEY}&chainid=4326&module=contract&action=verifysourcecode"
  
  echo "  Submitting verification request..."
  
  # Read the JSON content
  JSON_CONTENT=$(cat "$TEMP_JSON")
  rm -f "$TEMP_JSON"
  
  # For Standard JSON Input, sourceCode must be sent as a string (not file upload)
  # Use --data-urlencode to properly encode the JSON string
  RESPONSE=$(curl -s -X POST "$API_REQUEST_URL" \
    --data-urlencode "contractaddress=${address}" \
    --data-urlencode "sourceCode=${JSON_CONTENT}" \
    --data-urlencode "codeformat=${CODE_FORMAT}" \
    --data-urlencode "contractname=${contract_file}:${contract_name_only}" \
    --data-urlencode "compilerversion=${SOLC_VERSION}" \
    --data-urlencode "optimizationUsed=${OPTIMIZATION_USED}" \
    --data-urlencode "runs=${OPTIMIZATION_RUNS}" \
    --data-urlencode "evmVersion=${EVM_VERSION}" \
    --data-urlencode "licenseType=${LICENSE_TYPE}" \
    ${CONSTRUCTOR_ARGS:+--data-urlencode "constructorArguments=${CONSTRUCTOR_ARGS}"})
  
  # Parse response
  STATUS=$(echo "$RESPONSE" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")
  MESSAGE=$(echo "$RESPONSE" | jq -r '.message // ""' 2>/dev/null || echo "")
  RESULT=$(echo "$RESPONSE" | jq -r '.result // ""' 2>/dev/null || echo "")
  
  if [[ "$STATUS" == "1" ]]; then
    echo "  ✅ Verification submitted successfully!"
    if [[ -n "$RESULT" ]] && [[ "$RESULT" =~ ^[a-zA-Z0-9]+$ ]]; then
      echo "     GUID: $RESULT"
    fi
    return 0
  elif echo "$RESPONSE" | grep -qi "already verified"; then
    echo "  ✅ Contract is already verified"
    return 0
  else
    echo "  ❌ Verification failed"
    echo "     Status: $STATUS"
    echo "     Message: $MESSAGE"
    echo "     Result: $RESULT"
    echo "     Full response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    return 1
  fi
}

# Main execution
if [[ $# -ge 2 ]]; then
  # Verify single contract
  verify_contract_direct "$1" "$2" "${3:-$2}"
else
  # Verify all contracts from deployment file
  DEPLOYMENT_FILE="deployments/megaeth/v4-oracles.json"
  
  if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
    echo "❌ ERROR: Deployment file not found: $DEPLOYMENT_FILE"
    exit 1
  fi
  
  echo "=== Verifying MegaETH Contracts via Direct API ==="
  echo "Using Etherscan API V2 with chainid=4326"
  echo ""
  
  TOTAL=0
  SUCCESS=0
  FAILED=0
  
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
    
    if verify_contract_direct "$address" "$contract_path" "$name"; then
      SUCCESS=$((SUCCESS + 1))
    else
      FAILED=$((FAILED + 1))
    fi
    
    echo ""
    sleep 2
  done < <(jq -c '.oracles | to_entries[]' "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
  
  echo "=== Verification Summary ==="
  echo "Total: $TOTAL"
  echo "Successful: $SUCCESS"
  echo "Failed: $FAILED"
fi
