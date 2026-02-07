#!/usr/bin/env bash
set -euo pipefail

# Deploy Mainnet Leveraged Token v4 oracles (USD feeds only)
# These are direct deployments (no proxies) with hardcoded wiring
# Includes: hsfxUSD-EUR/USD, hsstETH-EUR/USD, hsstETH-BTC/USD, hsfxUSD-BTC/USD, hsfxUSD-ETH/USD

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

# Verification is done separately via verify-mainnet-leverage-v4-oracles.sh (run after deploy)
VERIFY=false

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
DEPLOYMENT_FILE="deployments/mainnet/leverage-v4-oracles.json"

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

# Function to deploy a contract. Only the deployed address is printed to stdout (for capture).
# All other messages go to stderr so success/failure is determined correctly.
deploy_contract() {
  local contract_path=$1
  local contract_name=$2
  local oracle_key=$3
  
  echo "Deploying $contract_name..." >&2
  
  DEPLOY_OUT=$("$FORGE" create "$contract_path" \
    --rpc-url "$MAINNET_RPC_URL" \
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

echo "=== Deploying Mainnet Leveraged Token v4 Oracles ==="
echo ""

# Define leveraged token oracles to deploy (USD feeds only)
declare -a ORACLES=(
  "src/mainnet/Aggregator_hsfxUSD_EUR_USD_mainnet.sol:Aggregator_hsfxUSD_EUR_USD_mainnet|HSFXUSD_EUR_USD|hsfxUSD-EUR/USD"
  "src/mainnet/Aggregator_hsstETH_EUR_USD_mainnet.sol:Aggregator_hsstETH_EUR_USD_mainnet|HSSTETH_EUR_USD|hsstETH-EUR/USD"
  "src/mainnet/Aggregator_hsstETH_BTC_USD_mainnet.sol:Aggregator_hsstETH_BTC_USD_mainnet|HSSTETH_BTC_USD|hsstETH-BTC/USD"
  "src/mainnet/Aggregator_hsfxUSD_BTC_USD_mainnet.sol:Aggregator_hsfxUSD_BTC_USD_mainnet|HSFXUSD_BTC_USD|hsfxUSD-BTC/USD"
  "src/mainnet/Aggregator_hsfxUSD_ETH_USD_mainnet.sol:Aggregator_hsfxUSD_ETH_USD_mainnet|HSFXUSD_ETH_USD|hsfxUSD-ETH/USD"
)

TOTAL=${#ORACLES[@]}
CURRENT=0
SUCCESS=0
FAILED=0

# Deploy all oracles
echo "Deploying $TOTAL leveraged token USD oracles..."
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
    code=$("$CAST" code "$existing_addr" --rpc-url "$MAINNET_RPC_URL" 2>/dev/null | head -1 || echo "0x")
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
  
  # Deploy (with --verify to verify on Etherscan after deploy)
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
  echo "✅ All leveraged token oracles deployed and tested successfully!"
  echo "   Verify on Etherscan: ./script/verify-mainnet-leverage-v4-oracles.sh"
else
  echo "⚠️  Some oracles failed. Check the output above for details."
  exit 1
fi
