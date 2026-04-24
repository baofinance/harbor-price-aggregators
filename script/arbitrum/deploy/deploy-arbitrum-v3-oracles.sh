#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Deploy all Arbitrum v3 oracles
# These are direct deployments (no proxies) with hardcoded wiring

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
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  echo "   Set it via: export PRIVATE_KEY='your_private_key'"
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

# Check for verify-only mode
if [[ "${1:-}" == "verify" ]] || [[ "${MODE:-}" == "verify" ]]; then
  echo "=== VERIFY-ONLY MODE ==="
  echo "Running verification for all deployed contracts..."
  echo ""
  exec "$REPO_ROOT/script/arbitrum/verify/verify-arbitrum-v3-oracles.sh"
fi

VERIFY=${VERIFY:-true}
if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "⚠️  WARNING: ETHERSCAN_API_KEY is not set"
  echo "   Verification will be skipped"
  VERIFY=false
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

# Create deployments directory if it doesn't exist
mkdir -p deployments/arbitrum

# Deployment state file
DEPLOYMENT_FILE="deployments/arbitrum/v3-oracles.json"

# Initialize deployment JSON if it doesn't exist
if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  cat > "$DEPLOYMENT_FILE" <<EOF
{
  "schemaVersion": 1,
  "chainId": 42161,
  "chainName": "Arbitrum",
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

# Function to deploy a contract
deploy_contract() {
  local contract_path=$1
  local contract_name=$2
  local oracle_key=$3
  
  echo "Deploying $contract_name..."
  
  DEPLOY_OUT=$("$FORGE" create "$contract_path" \
    --rpc-url "$ARBITRUM_RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast 2>&1)
  
  if [[ $? -ne 0 ]] || ! echo "$DEPLOY_OUT" | grep -q "Deployed to:"; then
    echo "❌ Deployment failed for $contract_name"
    echo "Error output:"
    echo "$DEPLOY_OUT" | grep -E "(Error|error|revert|Revert)" | head -5
    return 1
  fi
  
  local address=$(echo "$DEPLOY_OUT" | grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" | awk '{print $3}')
  
  if [[ -z "$address" ]]; then
    echo "❌ Could not extract address for $contract_name"
    return 1
  fi
  
  echo "✅ Deployed to: $address"
  
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
    echo "  ⚠️  Warning: Failed to update JSON file, but deployment succeeded"
    rm -f "$tmp_file"
  else
    mv "$tmp_file" "$DEPLOYMENT_FILE"
    echo "  💾 Address saved to deployment file"
    
    # Verify it was saved
    saved_addr=$(jq -r ".oracles[\"$oracle_key\"].address // empty" "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
    if [[ "$saved_addr" == "$address" ]]; then
      echo "  ✅ Address confirmed in deployment file"
    else
      echo "  ⚠️  Warning: Address may not have been saved correctly"
    fi
  fi
  
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
  
  # Submit verification request (non-blocking - removed --watch to prevent hanging)
  local verify_output
  verify_output=$("$FORGE" verify-contract \
    "$address" \
    "$contract_path" \
    --verifier etherscan \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    --compiler-version 0.8.30 \
    --chain arbitrum 2>&1 || echo "VERIFY_ERROR")
  
  if echo "$verify_output" | grep -q "Contract successfully verified"; then
    echo "  ✅ Verified successfully"
    return 0
  elif echo "$verify_output" | grep -qi "already verified"; then
    echo "  ✅ Already verified on Arbiscan"
    return 0
  elif echo "$verify_output" | grep -qi "submitted\|pending\|waiting"; then
    echo "  ⏳ Verification submitted (check Arbiscan in a few minutes)"
    return 0
  elif echo "$verify_output" | grep -qi "VERIFY_ERROR\|Error\|error"; then
    echo "  ⚠️  Verification submission failed (will retry later)"
    echo "  💡 Run './script/arbitrum/verify/verify-arbitrum-v3-oracles.sh' to verify later"
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
  
  local oracle_name=$("$CAST" call "$address" "oracleName()(string)" --rpc-url "$ARBITRUM_RPC_URL" 2>/dev/null || echo "")
  local base_name=$("$CAST" call "$address" "baseName()(string)" --rpc-url "$ARBITRUM_RPC_URL" 2>/dev/null || echo "")
  
  if [[ -n "$oracle_name" ]] && [[ "$oracle_name" != "" ]]; then
    echo "  ✅ $name: $oracle_name (base: $base_name)"
    return 0
  else
    echo "  ⚠️  $name: Could not fetch oracle name"
    return 1
  fi
}

echo "=== Deploying Arbitrum v3 Oracles ==="
echo ""

# Define all oracles to deploy
declare -a ORACLES=(
  # USDE Stock Oracles
  "src/arbitrum/Aggregator_USDE_AAPL_arbitrum.sol:Aggregator_USDE_AAPL_arbitrum|USDE_AAPL|USDE/AAPL"
  "src/arbitrum/Aggregator_USDE_AMZN_arbitrum.sol:Aggregator_USDE_AMZN_arbitrum|USDE_AMZN|USDE/AMZN"
  "src/arbitrum/Aggregator_USDE_GOOGL_arbitrum.sol:Aggregator_USDE_GOOGL_arbitrum|USDE_GOOGL|USDE/GOOGL"
  "src/arbitrum/Aggregator_USDE_META_arbitrum.sol:Aggregator_USDE_META_arbitrum|USDE_META|USDE/META"
  "src/arbitrum/Aggregator_USDE_MSFT_arbitrum.sol:Aggregator_USDE_MSFT_arbitrum|USDE_MSFT|USDE/MSFT"
  "src/arbitrum/Aggregator_USDE_NVDA_arbitrum.sol:Aggregator_USDE_NVDA_arbitrum|USDE_NVDA|USDE/NVDA"
  "src/arbitrum/Aggregator_USDE_SPY_arbitrum.sol:Aggregator_USDE_SPY_arbitrum|USDE_SPY|USDE/SPY"
  "src/arbitrum/Aggregator_USDE_TSLA_arbitrum.sol:Aggregator_USDE_TSLA_arbitrum|USDE_TSLA|USDE/TSLA"
  "src/arbitrum/Aggregator_USDE_MAG7_arbitrum.sol:Aggregator_USDE_MAG7_arbitrum|USDE_MAG7|USDE/MAG7"
  "src/arbitrum/Aggregator_USDE_MAG7i26_arbitrum.sol:Aggregator_USDE_MAG7i26_arbitrum|USDE_MAG7i26|USDE/MAG7.i26"
  
  # stETH Stock Oracles
  "src/arbitrum/Aggregator_stETH_AAPL_arbitrum.sol:Aggregator_stETH_AAPL_arbitrum|STETH_AAPL|stETH/AAPL"
  "src/arbitrum/Aggregator_stETH_AMZN_arbitrum.sol:Aggregator_stETH_AMZN_arbitrum|STETH_AMZN|stETH/AMZN"
  "src/arbitrum/Aggregator_stETH_GOOGL_arbitrum.sol:Aggregator_stETH_GOOGL_arbitrum|STETH_GOOGL|stETH/GOOGL"
  "src/arbitrum/Aggregator_stETH_META_arbitrum.sol:Aggregator_stETH_META_arbitrum|STETH_META|stETH/META"
  "src/arbitrum/Aggregator_stETH_MSFT_arbitrum.sol:Aggregator_stETH_MSFT_arbitrum|STETH_MSFT|stETH/MSFT"
  "src/arbitrum/Aggregator_stETH_NVDA_arbitrum.sol:Aggregator_stETH_NVDA_arbitrum|STETH_NVDA|stETH/NVDA"
  "src/arbitrum/Aggregator_stETH_SPY_arbitrum.sol:Aggregator_stETH_SPY_arbitrum|STETH_SPY|stETH/SPY"
  "src/arbitrum/Aggregator_stETH_TSLA_arbitrum.sol:Aggregator_stETH_TSLA_arbitrum|STETH_TSLA|stETH/TSLA"
  "src/arbitrum/Aggregator_stETH_MAG7_arbitrum.sol:Aggregator_stETH_MAG7_arbitrum|STETH_MAG7|stETH/MAG7"
  "src/arbitrum/Aggregator_stETH_MAG7i26_arbitrum.sol:Aggregator_stETH_MAG7i26_arbitrum|STETH_MAG7i26|stETH/MAG7.i26"
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
  if [[ "${FORCE_REDEPLOY:-}" != "true" ]]; then
    existing_addr=$(jq -r ".oracles[\"$oracle_key\"].address // empty" "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
    if [[ -n "$existing_addr" ]] && [[ "$existing_addr" != "null" ]] && [[ "$existing_addr" != "" ]]; then
      # Check if contract exists on chain
      code=$("$CAST" code "$existing_addr" --rpc-url "$ARBITRUM_RPC_URL" 2>/dev/null | head -1 || echo "0x")
      if [[ "$code" != "0x" ]]; then
        echo "  ⏭️  Already deployed at: $existing_addr"
        continue
      else
        echo "  ⚠️  Address in file but no contract on-chain, redeploying..."
      fi
    fi
  else
    echo "  🔄 Force redeploy mode - deploying new contract..."
  fi
  
  # Deploy
  address=$(deploy_contract "$contract_path" "$display_name" "$oracle_key")
  if [[ $? -eq 0 ]] && [[ -n "$address" ]]; then
    SUCCESS=$((SUCCESS + 1))
    
    # Small delay between deployments (wait for block confirmation)
    sleep 3
    
    # Note: Verification will be done at the end after all deployments
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

# Run verification at the end if enabled
if [[ "$VERIFY" == "true" ]] && [[ -n "$ETHERSCAN_API_KEY" ]] && [[ $SUCCESS -gt 0 ]]; then
  echo ""
  echo "=== Starting Verification Process ==="
  echo "Verifying all deployed contracts (this may take several minutes)..."
  echo ""
  
  # Function to verify a contract (with retries and proper error handling)
  verify_contract_final() {
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
        echo "  ✅ Already verified on Arbiscan"
        success=true
        break
      else
        retry=$((retry + 1))
        if [[ $retry -lt $max_retries ]]; then
          echo "  ⏳ Retrying verification ($retry/$max_retries)..."
          sleep 5
        else
          echo "  ❌ Verification failed after $max_retries attempts"
          echo "  Error: $(echo "$verify_output" | grep -E "(Error|error|Failed|failed)" | head -1 || echo "Unknown error")"
        fi
      fi
    done
    
    if [[ "$success" == "true" ]]; then
      return 0
    else
      return 1
    fi
  }
  
  # Verify all deployed oracles
  VERIFY_TOTAL=0
  VERIFY_SUCCESS=0
  VERIFY_FAILED=0
  VERIFY_ALREADY=0
  
  for oracle_info in "${ORACLES[@]}"; do
    IFS='|' read -r contract_path oracle_key display_name <<< "$oracle_info"
    
    address=$(jq -r ".oracles[\"$oracle_key\"].address // empty" "$DEPLOYMENT_FILE" 2>/dev/null || echo "")
    if [[ -z "$address" ]] || [[ "$address" == "null" ]] || [[ "$address" == "" ]]; then
      continue
    fi
    
    VERIFY_TOTAL=$((VERIFY_TOTAL + 1))
    echo "[$VERIFY_TOTAL/$SUCCESS] $display_name"
    
    if verify_contract_final "$address" "$contract_path" "$display_name"; then
      VERIFY_SUCCESS=$((VERIFY_SUCCESS + 1))
      # Check if it was already verified
      verify_check=$("$FORGE" verify-contract \
        "$address" \
        "$contract_path" \
        --verifier etherscan \
        --etherscan-api-key "$ETHERSCAN_API_KEY" \
        --compiler-version 0.8.30 \
        --chain arbitrum 2>&1 | grep -qi "already verified" && echo "yes" || echo "no")
      if [[ "$verify_check" == "yes" ]]; then
        VERIFY_ALREADY=$((VERIFY_ALREADY + 1))
      fi
    else
      VERIFY_FAILED=$((VERIFY_FAILED + 1))
    fi
    
    # Small delay between verifications
    sleep 2
    echo ""
  done
  
  echo "=== Verification Summary ==="
  echo "Total: $VERIFY_TOTAL"
  echo "Successfully verified: $VERIFY_SUCCESS"
  echo "Already verified: $VERIFY_ALREADY"
  echo "Failed: $VERIFY_FAILED"
  echo ""
  
  if [[ $VERIFY_FAILED -gt 0 ]]; then
    echo "⚠️  Some contracts failed verification. You can retry with:"
    echo "   ./script/arbitrum/verify/verify-arbitrum-v3-oracles.sh"
    echo ""
  fi
elif [[ "$VERIFY" == "true" ]] && [[ -z "$ETHERSCAN_API_KEY" ]]; then
  echo "💡 ETHERSCAN_API_KEY not set. Skipping verification."
  echo "   To verify later, run: ./script/arbitrum/verify/verify-arbitrum-v3-oracles.sh"
  echo ""
elif [[ "$VERIFY" != "true" ]]; then
  echo "💡 Verification disabled. To verify contracts, run:"
  echo "   ./script/arbitrum/verify/verify-arbitrum-v3-oracles.sh"
  echo ""
fi

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
  echo "✅ All oracles deployed and tested successfully!"
else
  echo "⚠️  Some oracles failed. Check the output above for details."
  exit 1
fi

