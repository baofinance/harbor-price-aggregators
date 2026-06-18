#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

# Verify MegaETH contracts on mega.etherscan.io via Etherscan API V2 (direct curl).
# Use this for Etherscan; use verify-megaeth-v4-oracles.sh for Blockscout.
# Requires: ETHERSCAN_API_KEY, MEGAETH_RPC_URL (.env or export)
# Usage: ./script/verify-megaeth-direct-api.sh [contract_address] [contract_path] [contract_name] [constructor_args_hex]
# If no arguments, verifies all contracts from deployments/megaeth/v4-aggregators.json
# (preferred) or deployments/megaeth/v4-oracles.json (legacy)
# Optional 4th arg: constructor args as hex (for proxies use verify-megaeth-proxies.sh)

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
  echo "   Set it via: export ETHERSCAN_API_KEY='your_key' or add to .env"
  exit 1
fi
if [[ -z "${MEGAETH_RPC_URL:-}" ]]; then
  echo "❌ ERROR: MEGAETH_RPC_URL is not set (needed to generate Standard JSON Input)"
  echo "   Set it via: export MEGAETH_RPC_URL='https://mainnet.megaeth.com/rpc' or add to .env"
  exit 1
fi

API_URL="https://api.etherscan.io/v2/api"

# Function to verify a single contract
# Optional 4th argument: constructor arguments as hex (e.g. from cast abi-encode) for proxies
verify_contract_direct() {
  local address=$1
  local contract_path=$2
  local contract_name=$3
  local constructor_args_hex="${4:-}"
  
  echo "Verifying $contract_name at $address..."
  
  # Build full identifier for forge/API: path or path:ContractName
  # Deployment JSON has contractPath (file only) and name (contract name); use both
  if [[ "$contract_path" == *":"* ]]; then
    contract_file="${contract_path%%:*}"
    contract_name_only="${contract_path#*:}"
    FORGE_CONTRACT_ID="$contract_path"
  else
    contract_file="$contract_path"
    # If name not provided or same as path, derive contract name from filename (e.g. path.sol -> path)
    if [[ -z "${contract_name:-}" ]] || [[ "$contract_name" == "$contract_path" ]]; then
      contract_name_only=$(basename "$contract_path" .sol)
    else
      contract_name_only="$contract_name"
    fi
    FORGE_CONTRACT_ID="${contract_path}:${contract_name_only}"
  fi
  
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
  
  # Etherscan API expects constructor args without 0x prefix; forge accepts with 0x
  CONSTRUCTOR_ARGS="${constructor_args_hex#0x}"
  TEMP_JSON=$(mktemp)
  # Capture only stdout so we get the JSON even if forge prints bytecode errors to stderr
  # Avoid empty-array expansion issues with `set -u` on older bash versions.
  if [[ -n "$constructor_args_hex" ]]; then
    STANDARD_JSON=$("$FORGE" verify-contract \
      --rpc-url "$MEGAETH_RPC_URL" \
      --show-standard-json-input \
      "$address" \
      "$FORGE_CONTRACT_ID" \
      --compiler-version 0.8.30 \
      --constructor-args "$constructor_args_hex" 2>/dev/null)
  else
    STANDARD_JSON=$("$FORGE" verify-contract \
      --rpc-url "$MEGAETH_RPC_URL" \
      --show-standard-json-input \
      "$address" \
      "$FORGE_CONTRACT_ID" \
      --compiler-version 0.8.30 2>/dev/null)
  fi
  
  JSON_CONTENT=$(echo "$STANDARD_JSON" | jq -c '.' 2>/dev/null || echo "")
  # If forge printed extra lines (e.g. "Compiling..." or errors), try to extract a single JSON object
  if [[ -z "$JSON_CONTENT" ]] || ! echo "$JSON_CONTENT" | jq -e '.sources' > /dev/null 2>&1; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      candidate=$(echo "$line" | jq -c '.' 2>/dev/null)
      if [[ -n "$candidate" ]] && echo "$candidate" | jq -e '.sources' > /dev/null 2>&1; then
        JSON_CONTENT="$candidate"
        break
      fi
    done <<< "$STANDARD_JSON"
  fi
  
  if [[ -n "$JSON_CONTENT" ]] && echo "$JSON_CONTENT" | jq -e '.sources' > /dev/null 2>&1; then
    echo "  ✓ Got Standard JSON Input from forge (includes all dependencies)"
    echo "$JSON_CONTENT" > "$TEMP_JSON"
    CODE_FORMAT="solidity-standard-json-input"
  else
    echo "  ❌ Could not extract Standard JSON Input from forge output"
    echo "  Forge stdout (first 30 lines):"
    echo "$STANDARD_JSON" | head -30
    echo "  Run forge manually (without 2>/dev/null) to see stderr."
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
  # Etherscan expects contractname as "path:ContractName" for standard-json-input
  API_CONTRACT_NAME="${contract_file}:${contract_name_only}"
  RESPONSE=$(curl -s -X POST "$API_REQUEST_URL" \
    --data-urlencode "contractaddress=${address}" \
    --data-urlencode "sourceCode=${JSON_CONTENT}" \
    --data-urlencode "codeformat=${CODE_FORMAT}" \
    --data-urlencode "contractname=${API_CONTRACT_NAME}" \
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
  # Verify single contract (optional 4th arg: constructor args hex for proxies)
  verify_contract_direct "$1" "$2" "${3:-$2}" "${4:-}"
else
  # Verify all contracts from deployment file
  if [[ -f "deployments/megaeth/v4-aggregators.json" ]]; then
    DEPLOYMENT_FILE="deployments/megaeth/v4-aggregators.json"
  elif [[ -f "deployments/megaeth/v4-oracles.json" ]]; then
    DEPLOYMENT_FILE="deployments/megaeth/v4-oracles.json"
  else
    echo "❌ ERROR: Deployment file not found:"
    echo "   - deployments/megaeth/v4-aggregators.json"
    echo "   - deployments/megaeth/v4-oracles.json"
    exit 1
  fi
  
  echo "=== Verifying MegaETH Contracts via Direct API ==="
  echo "Using Etherscan API V2 with chainid=4326"
  echo ""
  
  TOTAL=0
  SUCCESS=0
  FAILED=0
  
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

    if [[ "$contract_path" == *.sol ]] && [[ -n "$contract_type" ]]; then
      contract_path="${contract_path}:${contract_type}"
    fi
    
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
  done < <(eval "$ENTRY_STREAM" 2>/dev/null || echo "")
  
  echo "=== Verification Summary ==="
  echo "Total: $TOTAL"
  echo "Successful: $SUCCESS"
  echo "Failed: $FAILED"
fi
