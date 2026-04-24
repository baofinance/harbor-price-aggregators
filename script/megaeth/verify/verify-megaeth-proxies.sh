#!/usr/bin/env bash
set -euo pipefail

# Verify MegaETH proxy contracts (ERC1967Proxy) on Etherscan or Blockscout.
# Reads proxy addresses and implementations from deployments/megaeth/v4-aggregators.json
# (preferred) or deployments/megaeth/v3-aggregators.json (legacy).
# Requires: MEGAETH_RPC_URL; for etherscan also ETHERSCAN_API_KEY.
# Usage: ./script/verify-megaeth-proxies.sh [verifier] [pair]
#   verifier: etherscan (default) or blockscout
#   pair: optional, e.g. "BTC/USD" to verify only that proxy; omit to verify all.

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
cd "$REPO_ROOT"

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

# First optional arg: verifier (etherscan | blockscout)
VERIFIER="etherscan"
PAIR_ARG=""
if [[ "${1:-}" == "blockscout" ]] || [[ "${1:-}" == "etherscan" ]]; then
  VERIFIER="$1"
  shift
fi
if [[ -n "${1:-}" ]]; then
  PAIR_ARG="$1"
fi

if [[ -z "${MEGAETH_RPC_URL:-}" ]]; then
  echo "❌ ERROR: MEGAETH_RPC_URL is not set"
  exit 1
fi
if [[ "$VERIFIER" == "etherscan" ]] && [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "❌ ERROR: ETHERSCAN_API_KEY is not set (required for Etherscan)"
  exit 1
fi
if [[ "$VERIFIER" == "blockscout" ]]; then
  export ETHERSCAN_KEY=${ETHERSCAN_KEY:-"dummy"}
fi

FORGE=${FORGE:-$HOME/.foundry/bin/forge}
if [[ -f "deployments/megaeth/v4-aggregators.json" ]]; then
  STATE_FILE="deployments/megaeth/v4-aggregators.json"
else
  STATE_FILE="deployments/megaeth/v3-aggregators.json"
fi
if [[ ! -f "$STATE_FILE" ]]; then
  echo "❌ ERROR: State file not found: $STATE_FILE"
  exit 1
fi

# ERC1967Proxy: constructor(address implementation, bytes memory _data)
PROXY_CONTRACT_ID="lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
PROXY_NAME="ERC1967Proxy"
BLOCKSCOUT_URL="https://megaeth.blockscout.com/api/"

verify_one_etherscan() {
  local pair=$1
  local proxy_addr=$2
  local impl=$3
  local constructor_args_hex
  constructor_args_hex=$(cast abi-encode "constructor(address,bytes)" "$impl" 0x)
  echo "[$pair] Proxy $proxy_addr -> $impl (Etherscan)"
  "$SCRIPT_DIR/verify-megaeth-direct-api.sh" "$proxy_addr" "$PROXY_CONTRACT_ID" "$PROXY_NAME" "$constructor_args_hex"
}

verify_one_blockscout() {
  local pair=$1
  local proxy_addr=$2
  local impl=$3
  local constructor_args_hex
  constructor_args_hex=$(cast abi-encode "constructor(address,bytes)" "$impl" 0x)
  echo "[$pair] Proxy $proxy_addr -> $impl (Blockscout)"
  local verify_output
  verify_output=$("$FORGE" verify-contract \
    --rpc-url "$MEGAETH_RPC_URL" \
    --verifier blockscout \
    --verifier-url "$BLOCKSCOUT_URL" \
    --etherscan-api-key "$ETHERSCAN_KEY" \
    "$proxy_addr" \
    "$PROXY_CONTRACT_ID" \
    --constructor-args "$constructor_args_hex" \
    --compiler-version 0.8.30 2>&1 || echo "VERIFY_ERROR")
  if echo "$verify_output" | grep -q "Contract successfully verified\|already verified\|submitted\|pending\|waiting"; then
    echo "  ✅ Verified / submitted on Blockscout"
    return 0
  elif echo "$verify_output" | grep -qi "VERIFY_ERROR\|Error\|error"; then
    echo "  ❌ Failed"
    echo "$verify_output" | head -15
    return 1
  fi
  echo "  ⏳ Submitted to Blockscout"
  return 0
}

verify_one() {
  if [[ "$VERIFIER" == "blockscout" ]]; then
    verify_one_blockscout "$@"
  else
    verify_one_etherscan "$@"
  fi
}

if [[ -n "$PAIR_ARG" ]]; then
  pair="$PAIR_ARG"
  addr=$(jq -r --arg p "$pair" '.proxies[$p].address // empty' "$STATE_FILE")
  impl=$(jq -r --arg p "$pair" '.proxies[$p].implementation // empty' "$STATE_FILE")
  if [[ -z "$addr" ]] || [[ -z "$impl" ]]; then
    echo "❌ No proxy found for pair: $pair"
    exit 1
  fi
  verify_one "$pair" "$addr" "$impl"
  exit 0
fi

echo "=== Verifying MegaETH proxies (ERC1967Proxy) on $VERIFIER ==="
echo "State: $STATE_FILE"
echo ""

TOTAL=0
SUCCESS=0
FAILED=0

while IFS= read -r line; do
  pair=$(echo "$line" | jq -r '.key')
  addr=$(echo "$line" | jq -r '.value.address')
  impl=$(echo "$line" | jq -r '.value.implementation')
  [[ -z "$pair" ]] || [[ "$addr" == "null" ]] || [[ "$impl" == "null" ]] && continue
  TOTAL=$((TOTAL + 1))
  if verify_one "$pair" "$addr" "$impl"; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  echo ""
  sleep 2
done < <(jq -c '.proxies | to_entries[]' "$STATE_FILE" 2>/dev/null || true)

echo "=== Proxy verification summary ==="
echo "Total: $TOTAL  Successful: $SUCCESS  Failed: $FAILED"
[[ $FAILED -eq 0 ]]
