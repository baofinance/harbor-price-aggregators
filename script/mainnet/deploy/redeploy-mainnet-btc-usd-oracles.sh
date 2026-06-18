#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Redeploy only wBTC/USD and tBTC/USD (e.g. after heartbeat config change).
# Updates deployments/mainnet/v4-oracles.json with new addresses.

FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CAST=${CAST:-$HOME/.foundry/bin/cast}

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

if [[ -z "${MAINNET_RPC_URL:-}" ]]; then
  echo "❌ ERROR: MAINNET_RPC_URL is not set"
  exit 1
fi
if [[ -z "${PRIVATE_KEY:-}" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  exit 1
fi

DEPLOYMENT_FILE="deployments/mainnet/v4-oracles.json"
mkdir -p deployments/mainnet
if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  echo "❌ ERROR: $DEPLOYMENT_FILE not found. Run deploy-mainnet-v4-oracles.sh first."
  exit 1
fi

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
    echo "$DEPLOY_OUT" | tail -30 >&2
    return 1
  fi
  local address=$(echo "$DEPLOY_OUT" | grep -Eo "Deployed to: 0x[0-9a-fA-F]{40}" | awk '{print $3}')
  if [[ -z "$address" ]]; then
    echo "❌ Could not extract address for $contract_name" >&2
    return 1
  fi
  echo "✅ Deployed to: $address" >&2
  local tmp_file=$(mktemp)
  if jq --arg key "$oracle_key" --arg name "$contract_name" --arg addr "$address" --arg path "$contract_path" \
     '.oracles[$key] = { "name": $name, "address": $addr, "contractPath": $path }' "$DEPLOYMENT_FILE" > "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DEPLOYMENT_FILE"
    echo "  💾 Saved to $DEPLOYMENT_FILE" >&2
  else
    rm -f "$tmp_file"
    echo "  ⚠️  Failed to update JSON" >&2
  fi
  echo "$address"
}

echo "=== Redeploying wBTC/USD and tBTC/USD ==="
echo ""

declare -a ORACLES=(
  "src/mainnet/Aggregator_wBTC_USD_mainnet.sol:Aggregator_wBTC_USD_mainnet|WBTC_USD|wBTC/USD"
  "src/mainnet/Aggregator_tBTC_USD_mainnet.sol:Aggregator_tBTC_USD_mainnet|TBTC_USD|tBTC/USD"
)

for oracle_info in "${ORACLES[@]}"; do
  IFS='|' read -r contract_path oracle_key display_name <<< "$oracle_info"
  set +e
  address=$(deploy_contract "$contract_path" "$display_name" "$oracle_key")
  set -e
  address=$(echo "$address" | tr -d '\n\r' | grep -Eo '0x[0-9a-fA-F]{40}' | head -1)
  if [[ -n "$address" ]]; then
    echo "  $display_name -> $address"
  fi
  echo ""
  sleep 3
done

echo "=== Updated addresses ==="
jq -r '.oracles | to_entries[] | select(.key == "WBTC_USD" or .key == "TBTC_USD") | "\(.key): \(.value.address)"' "$DEPLOYMENT_FILE"
echo ""
echo "Verify on Etherscan: ./script/mainnet/verify/verify-mainnet-v4-oracles.sh"
