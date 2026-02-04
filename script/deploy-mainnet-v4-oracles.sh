#!/usr/bin/env bash
set -euo pipefail

# Deploy all Mainnet v4 oracles
# These are direct deployments (no proxies) with hardcoded wiring
# Includes: wstETH/USD, wBTC/USD, tBTC/BTC, PAXG/USD, and all sUSDe aggregators

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
if [[ -z "${MAINNET_RPC_URL:-}" ]]; then
  echo "❌ ERROR: MAINNET_RPC_URL is not set"
  echo "   Set it via: export MAINNET_RPC_URL='your_rpc_url'"
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  echo "   Set it via: export PRIVATE_KEY='your_private_key'"
  echo "   Or add it to a .env file in the project root"
  exit 1
fi

VERIFY=${VERIFY:-true}
if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "⚠️  WARNING: ETHERSCAN_API_KEY is not set"
  echo "   Verification will be skipped"
  VERIFY=false
fi

# Check network
CHAIN_ID=$("$CAST" chain-id --rpc-url "$MAINNET_RPC_URL" 2>/dev/null || echo "unknown")
echo "=== Network Check ==="
echo "RPC URL: $MAINNET_RPC_URL"
echo "Chain ID: $CHAIN_ID"
if [[ "$CHAIN_ID" != "0x1" ]] && [[ "$CHAIN_ID" != "1" ]]; then
  echo "⚠️  WARNING: Expected Mainnet chain ID (1), got: $CHAIN_ID"
  echo "   Press Ctrl+C to cancel, or wait 5 seconds to continue..."
  sleep 5
fi
echo ""

# Create deployments directory if it doesn't exist
mkdir -p deployments/mainnet

# Deployment state file
DEPLOYMENT_FILE="deployments/mainnet/v4-oracles.json"

# Initialize deployment JSON if it doesn't exist
if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  cat > "$DEPLOYMENT_FILE" <<EOF
{
  "schemaVersion": 1,
  "chainId": 1,
  "chainName": "Mainnet",
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
    --rpc-url "$MAINNET_RPC_URL" \
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
  
  # Submit verification request (non-blocking)
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
  
  local oracle_name=$("$CAST" call "$address" "oracleName()(string)" --rpc-url "$MAINNET_RPC_URL" 2>/dev/null || echo "")
  local base_name=$("$CAST" call "$address" "baseName()(string)" --rpc-url "$MAINNET_RPC_URL" 2>/dev/null || echo "")
  
  if [[ -n "$oracle_name" ]] && [[ "$oracle_name" != "" ]]; then
    echo "  ✅ $name: $oracle_name (base: $base_name)"
    return 0
  else
    echo "  ⚠️  $name: Could not fetch oracle name"
    return 1
  fi
}

echo "=== Deploying Mainnet v4 Oracles ==="
echo ""

# Define all oracles to deploy
declare -a ORACLES=(
  # New v4 Oracles
  "src/mainnet/Aggregator_wstETH_USD_mainnet.sol:Aggregator_wstETH_USD_mainnet|WSTETH_USD|wstETH/USD"
  "src/mainnet/Aggregator_wBTC_USD_mainnet.sol:Aggregator_wBTC_USD_mainnet|WBTC_USD|wBTC/USD"
  "src/mainnet/Aggregator_tBTC_BTC_mainnet.sol:Aggregator_tBTC_BTC_mainnet|TBTC_BTC|tBTC/BTC"
  "src/mainnet/Aggregator_PAXG_USD_mainnet.sol:Aggregator_PAXG_USD_mainnet|PAXG_USD|PAXG/USD"
  
  # sUSDe Oracles
  "src/mainnet/Aggregator_sUSDe_BTC_mainnet.sol:Aggregator_sUSDe_BTC_mainnet|SUSDE_BTC|sUSDe/BTC"
  "src/mainnet/Aggregator_sUSDe_ETH_mainnet.sol:Aggregator_sUSDe_ETH_mainnet|SUSDE_ETH|sUSDe/ETH"
  "src/mainnet/Aggregator_sUSDe_EUR_mainnet.sol:Aggregator_sUSDe_EUR_mainnet|SUSDE_EUR|sUSDe/EUR"
  "src/mainnet/Aggregator_sUSDe_XAU_mainnet.sol:Aggregator_sUSDe_XAU_mainnet|SUSDE_XAU|sUSDe/XAU"
  "src/mainnet/Aggregator_sUSDe_XAG_mainnet.sol:Aggregator_sUSDe_XAG_mainnet|SUSDE_XAG|sUSDe/XAG"
  "src/mainnet/Aggregator_sUSDe_MCAP_mainnet.sol:Aggregator_sUSDe_MCAP_mainnet|SUSDE_MCAP|sUSDe/MCAP"
  "src/mainnet/Aggregator_sUSDe_GOLD_mainnet.sol:Aggregator_sUSDe_GOLD_mainnet|SUSDE_GOLD|sUSDe/GOLD"
  "src/mainnet/Aggregator_sUSDe_SILVER_mainnet.sol:Aggregator_sUSDe_SILVER_mainnet|SUSDE_SILVER|sUSDe/SILVER"
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
      code=$("$CAST" code "$existing_addr" --rpc-url "$MAINNET_RPC_URL" 2>/dev/null | head -1 || echo "0x")
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
    
    # Verify contract
    verify_contract "$address" "$contract_path" "$display_name"
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
  echo "✅ All oracles deployed and tested successfully!"
else
  echo "⚠️  Some oracles failed. Check the output above for details."
  exit 1
fi
