#!/usr/bin/env bash
set -euo pipefail

# Deploy all MegaETH v4 oracles
# These are direct deployments (no proxies) with hardcoded wiring
# Based on deploy-mainnet-v4-oracles.sh

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
if [[ -z "${MEGAETH_RPC_URL:-}" ]]; then
  echo "❌ ERROR: MEGAETH_RPC_URL is not set"
  echo "   Set it via: export MEGAETH_RPC_URL='https://mainnet.megaeth.com/rpc'"
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  echo "   Set it via: export PRIVATE_KEY='your_private_key'"
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

# Verification is done separately via verify-megaeth-v4-oracles.sh (run after deploy)
VERIFY=false

# Check network
CHAIN_ID=$("$CAST" chain-id --rpc-url "$MEGAETH_RPC_URL" 2>/dev/null || echo "unknown")
echo "=== Network Check ==="
echo "RPC URL: $MEGAETH_RPC_URL"
echo "Chain ID: $CHAIN_ID"
# TODO: Update with actual MegaETH chain ID once known
# if [[ "$CHAIN_ID" != "0x..." ]] && [[ "$CHAIN_ID" != "..." ]]; then
#   echo "⚠️  WARNING: Expected MegaETH chain ID (...), got: $CHAIN_ID"
#   echo "   Press Ctrl+C to cancel, or wait 5 seconds to continue..."
#   sleep 5
# fi
echo ""

# Create deployments directory if it doesn't exist
mkdir -p deployments/megaeth

# Deployment state file
DEPLOYMENT_FILE="deployments/megaeth/v4-oracles.json"

# Initialize deployment JSON if it doesn't exist
# TODO: Update chainId with actual MegaETH chain ID once known
if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  cat > "$DEPLOYMENT_FILE" <<EOF
{
  "schemaVersion": 1,
  "chainId": 0,
  "chainName": "MegaETH",
  "deploymentTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "oracles": {}
}
EOF
  echo "📝 Created deployment file: $DEPLOYMENT_FILE"
else
  echo "📂 Using existing deployment file: $DEPLOYMENT_FILE"
  # Show current count
  current_count=$(jq '.oracles | length' "$DEPLOYMENT_FILE" 2>/dev/null || echo "0")
  echo "   Current oracles in file: $current_count"
fi
echo ""

# Function to deploy a contract. Only the deployed address is printed to stdout (for capture).
# All other messages go to stderr so success/failure is determined correctly.
deploy_contract() {
  local contract_path=$1
  local contract_name=$2
  local oracle_key=$3
  
  echo "Deploying $contract_name..." >&2
  
  DEPLOY_OUT=$("$FORGE" create "$contract_path" \
    --rpc-url "$MEGAETH_RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast 2>&1)
  
  local forge_exit_code=$?
  
  if [[ $forge_exit_code -ne 0 ]] || ! echo "$DEPLOY_OUT" | grep -q "Deployed to:"; then
    echo "❌ Deployment failed for $contract_name" >&2
    echo "Error output:" >&2
    echo "$DEPLOY_OUT" | tail -30 >&2
    return 1
  fi
  
  local address=$(echo "$DEPLOY_OUT" | grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" | awk '{print $3}')
  
  if [[ -z "$address" ]]; then
    echo "❌ Could not extract address for $contract_name" >&2
    return 1
  fi
  
  echo "✅ Deployed to: $address" >&2
  
  # Update deployment JSON
  local tmp_file=$(mktemp)
  if ! jq --arg key "$oracle_key" \
     --arg name "$contract_name" \
     --arg addr "$address" \
     --arg path "$contract_path" \
     '.oracles[$key] = {
       "name": $name,
       "address": $addr,
       "contractPath": $path
     }' "$DEPLOYMENT_FILE" > "$tmp_file" 2>/dev/null; then
    echo "  ⚠️  Warning: Failed to update JSON file, but deployment succeeded" >&2
    rm -f "$tmp_file"
  else
    mv "$tmp_file" "$DEPLOYMENT_FILE"
    echo "  💾 Address saved to deployment file" >&2
    
    # Verify it was saved
    saved_addr=$(jq -r ".oracles[\"$oracle_key\"].address // empty" "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
    if [[ "$saved_addr" == "$address" ]]; then
      echo "  ✅ Address confirmed in deployment file" >&2
    else
      echo "  ⚠️  Warning: Address may not have been saved correctly" >&2
    fi
  fi
  
  # Only stdout: the address (so capture gets a single line and success check works)
  echo "$address"
}

# Function to verify a contract (non-blocking, continues on failure)
verify_contract() {
  local address=$1
  local contract_path=$2
  local contract_name=$3
  
  if [[ "$VERIFY" != "true" ]]; then
    return 0
  fi
  
  echo "  Verifying $contract_name..."
  
  # Submit verification request (non-blocking) using Blockscout
  local verify_output
  verify_output=$("$FORGE" verify-contract \
    --rpc-url "$MEGAETH_RPC_URL" \
    --verifier blockscout \
    --verifier-url "https://megaeth.blockscout.com/api/" \
    "$address" \
    "$contract_path" \
    --compiler-version 0.8.30 2>&1 || echo "VERIFY_ERROR")
  
  if echo "$verify_output" | grep -q "Contract successfully verified"; then
    echo "  ✅ Verified successfully"
    return 0
  elif echo "$verify_output" | grep -qi "already verified"; then
    echo "  ✅ Already verified on Blockscout"
    return 0
  elif echo "$verify_output" | grep -qi "submitted\|pending\|waiting"; then
    echo "  ⏳ Verification submitted (check Blockscout in a few minutes)"
    return 0
  elif echo "$verify_output" | grep -qi "VERIFY_ERROR\|Error\|error"; then
    echo "  ⚠️  Verification submission failed (will retry later)"
    return 0  # Don't fail deployment
  else
    echo "  ⏳ Verification request submitted"
    return 0
  fi
}

# Function to test an oracle
test_oracle() {
  local address=$1
  local name=$2
  
  local oracle_name=$("$CAST" call "$address" "oracleName()(string)" --rpc-url "$MEGAETH_RPC_URL" 2>/dev/null || echo "")
  local base_name=$("$CAST" call "$address" "baseName()(string)" --rpc-url "$MEGAETH_RPC_URL" 2>/dev/null || echo "")
  
  if [[ -n "$oracle_name" ]] && [[ "$oracle_name" != "" ]]; then
    echo "  ✅ $name: $oracle_name (base: $base_name)"
    
    # Test latestAnswer()
    echo "  ⏳ Testing latestAnswer()..."
    set +e
    latest_answer_output=$("$CAST" call "$address" "latestAnswer()(uint256,uint256,uint256,uint256)" --rpc-url "$MEGAETH_RPC_URL" 2>&1)
    latest_answer_exit=$?
    set -e
    
    if [[ $latest_answer_exit -eq 0 ]]; then
      # Parse the tuple output: cast returns values like:
      # minUnderlyingPrice (uint256) : 1234567890
      # maxUnderlyingPrice (uint256) : 1234567890
      # minWrappedRate (uint256) : 1234567890
      # maxWrappedRate (uint256) : 1234567890
      # Or sometimes just comma-separated numbers
      
      # Try labeled parsing first
      min_price=$(echo "$latest_answer_output" | grep -i "minUnderlyingPrice" | sed -n 's/.*: *\([0-9]*\).*/\1/p' | head -1)
      max_price=$(echo "$latest_answer_output" | grep -i "maxUnderlyingPrice" | sed -n 's/.*: *\([0-9]*\).*/\1/p' | head -1)
      min_rate=$(echo "$latest_answer_output" | grep -i "minWrappedRate" | sed -n 's/.*: *\([0-9]*\).*/\1/p' | head -1)
      max_rate=$(echo "$latest_answer_output" | grep -i "maxWrappedRate" | sed -n 's/.*: *\([0-9]*\).*/\1/p' | head -1)
      
      # Fallback: if labeled parsing fails, try extracting numbers in order
      if [[ -z "$min_price" ]] || [[ -z "$max_price" ]] || [[ -z "$min_rate" ]] || [[ -z "$max_rate" ]]; then
        # Extract all numbers from the output (cast may return comma-separated or line-separated)
        numbers=($(echo "$latest_answer_output" | grep -Eo '[0-9]+' | head -4))
        if [[ ${#numbers[@]} -ge 4 ]]; then
          min_price="${numbers[0]}"
          max_price="${numbers[1]}"
          min_rate="${numbers[2]}"
          max_rate="${numbers[3]}"
        fi
      fi
      
      if [[ -n "$min_price" ]] && [[ -n "$max_price" ]] && [[ -n "$min_rate" ]] && [[ -n "$max_rate" ]]; then
        echo "  ✅ latestAnswer() successful:"
        echo "     Price: $min_price (min) / $max_price (max)"
        echo "     Rate:  $min_rate (min) / $max_rate (max)"
        return 0
      else
        echo "  ⚠️  latestAnswer() returned data but parsing failed"
        echo "     Raw output (first 5 lines):"
        echo "$latest_answer_output" | head -5 | sed 's/^/       /'
        return 1
      fi
    else
      # Check if it's a known error
      if echo "$latest_answer_output" | grep -qi "StaleFeedData\|stale"; then
        echo "  ❌ latestAnswer() failed: StaleFeedData (feed is too old)"
      elif echo "$latest_answer_output" | grep -qi "revert\|error"; then
        echo "  ❌ latestAnswer() failed: $(echo "$latest_answer_output" | head -3 | tr '\n' ' ')"
      else
        echo "  ❌ latestAnswer() failed: $latest_answer_output"
      fi
      return 1
    fi
  else
    echo "  ⚠️  $name: Could not fetch oracle name"
    return 1
  fi
}

echo "=== Deploying MegaETH v4 Oracles ==="
echo ""

# Define all oracles to deploy
declare -a ORACLES=(
  # USDMY Oracles
  "src/megaeth/Aggregator_USDMY_ETH_megaeth.sol:Aggregator_USDMY_ETH_megaeth|USDMY_ETH|USDMY/ETH"
  "src/megaeth/Aggregator_USDMY_HYPE_megaeth.sol:Aggregator_USDMY_HYPE_megaeth|USDMY_HYPE|USDMY/HYPE"
  "src/megaeth/Aggregator_USDMY_SOL_megaeth.sol:Aggregator_USDMY_SOL_megaeth|USDMY_SOL|USDMY/SOL"
  "src/megaeth/Aggregator_USDMY_BTC_megaeth.sol:Aggregator_USDMY_BTC_megaeth|USDMY_BTC|USDMY/BTC"
)

TOTAL=${#ORACLES[@]}
CURRENT=0
SUCCESS=0
FAILED=0

# Deploy all oracles
echo "Deploying $TOTAL oracles..."
echo ""

for oracle_info in "${ORACLES[@]}"; do
  CURRENT=$((CURRENT + 1))
  IFS='|' read -r contract_path oracle_key display_name <<< "$oracle_info"
  
  echo "[$CURRENT/$TOTAL] $display_name"
  
  # Check if already deployed (unless FORCE_REDEPLOY is set)
  # Use set +e so a crashing cast (e.g. proxy bug) doesn't kill the script
  existing_addr=""
  if [[ "${FORCE_REDEPLOY:-}" != "true" ]] && [[ -f "$DEPLOYMENT_FILE" ]]; then
    existing_addr=$(jq -r ".oracles[\"$oracle_key\"].address // empty" "$DEPLOYMENT_FILE" 2>/dev/null) || existing_addr=""
  fi
  if [[ -n "$existing_addr" ]] && [[ "$existing_addr" != "null" ]]; then
    set +e
    code=$("$CAST" code "$existing_addr" --rpc-url "$MEGAETH_RPC_URL" 2>/dev/null | head -1 || echo "0x")
    set -e
    if [[ -n "$code" ]] && [[ "$code" != "0x" ]]; then
      echo "  ⏭️  Already deployed at: $existing_addr"
      continue
    else
      echo "  ⚠️  Address in file but no contract on-chain, redeploying..."
    fi
  fi
  if [[ "${FORCE_REDEPLOY:-}" == "true" ]]; then
    echo "  🔄 Force redeploy mode - deploying new contract..."
  fi
  
  # Deploy
  set +e
  address=$(deploy_contract "$contract_path" "$display_name" "$oracle_key")
  deploy_exit_code=$?
  set -e
  
  # Trim whitespace/newlines so we only have the address
  address=$(echo "$address" | tr -d '\n\r' | grep -Eo '0x[0-9a-fA-F]{40}' | head -1)
  
  if [[ $deploy_exit_code -eq 0 ]] && [[ -n "$address" ]] && [[ "$address" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    SUCCESS=$((SUCCESS + 1))
    
    # Small delay between deployments (wait for block confirmation)
    sleep 3
  else
    FAILED=$((FAILED + 1))
    echo "  ❌ Failed to deploy $display_name"
  fi
  
  echo ""
done

# Update deployment time
tmp_file=$(mktemp)
if jq ".deploymentTime = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$DEPLOYMENT_FILE" > "$tmp_file" 2>/dev/null; then
  mv "$tmp_file" "$DEPLOYMENT_FILE"
else
  rm -f "$tmp_file"
  echo "⚠️  Warning: Could not update deployment time"
fi

# Final verification - show what's in the file
echo "=== Final Deployment File Status ==="
final_count=$(jq '.oracles | length' "$DEPLOYMENT_FILE" 2>/dev/null || echo "0")
echo "Total oracles in file: $final_count"
if [[ $final_count -gt 0 ]]; then
  echo ""
  echo "All saved addresses:"
  jq -r '.oracles | to_entries[] | "  \(.value.name): \(.value.address)"' "$DEPLOYMENT_FILE" | sort
fi
echo ""

echo "=== Deployment Summary ==="
echo "Total: $TOTAL"
echo "Successful: $SUCCESS"
echo "Failed: $FAILED"
echo ""

# Test all deployed oracles
echo "=== Testing Deployed Oracles ==="
echo ""

TEST_SUCCESS=0
TEST_FAILED=0

for oracle_info in "${ORACLES[@]}"; do
  IFS='|' read -r contract_path oracle_key display_name <<< "$oracle_info"
  
  address=$(jq -r ".oracles[\"$oracle_key\"].address // empty" "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
  if [[ -n "$address" ]] && [[ "$address" != "null" ]] && [[ "$address" != "" ]]; then
    if test_oracle "$address" "$display_name"; then
      TEST_SUCCESS=$((TEST_SUCCESS + 1))
    else
      TEST_FAILED=$((TEST_FAILED + 1))
    fi
  fi
done

echo ""
echo "=== Test Summary ==="
echo "Successful: $TEST_SUCCESS"
echo "Failed: $TEST_FAILED"
echo ""

echo "=== Deployment File ==="
echo "Deployment addresses saved to: $DEPLOYMENT_FILE"
echo ""

# Display all addresses
echo "=== All Deployed Addresses ==="
jq -r '.oracles | to_entries[] | "\(.key): \(.value.address)"' "$DEPLOYMENT_FILE" | sort
echo ""

if [[ $FAILED -eq 0 ]] && [[ $TEST_FAILED -eq 0 ]]; then
  echo "✅ All v4 oracles deployed and tested successfully!"
  echo ""
  echo "📋 Next steps:"
  echo "   Verify contracts on Blockscout: ./script/verify-megaeth-v4-oracles.sh"
else
  echo "⚠️  Some oracles failed. Check the output above for details."
  exit 1
fi
