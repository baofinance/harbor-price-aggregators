#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

# Verify that all MegaETH v4 oracles report owner() == 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2
# HarborAggregator_v3 uses BaoFixedOwnable with this owner baked in at deployment; no transfer needed.

CAST=${CAST:-$HOME/.foundry/bin/cast}
EXPECTED_OWNER="0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2"
if [[ -f "deployments/megaeth/v4-aggregators.json" ]]; then
  DEPLOYMENT_FILE="deployments/megaeth/v4-aggregators.json"
else
  DEPLOYMENT_FILE="deployments/megaeth/v4-oracles.json"
fi

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

if [[ -z "${MEGAETH_RPC_URL:-}" ]]; then
  echo "❌ MEGAETH_RPC_URL not set"
  exit 1
fi

if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  echo "❌ $DEPLOYMENT_FILE not found"
  exit 1
fi

echo "=== MegaETH oracle ownership check ==="
echo "Expected owner: $EXPECTED_OWNER"
echo ""

ok=0
fail=0
while IFS= read -r line; do
  key=$(echo "$line" | jq -r '.key')
  name=$(echo "$line" | jq -r '.value.name // .value.pair // .key')
  addr=$(echo "$line" | jq -r '.value.address')
  [[ -z "$addr" ]] || [[ "$addr" == "null" ]] && continue
  owner=$("$CAST" call "$addr" "owner()(address)" --rpc-url "$MEGAETH_RPC_URL" 2>/dev/null | grep -Eo '0x[a-fA-F0-9]{40}' | head -1 || echo "")
  if [[ "$owner" == "$EXPECTED_OWNER" ]]; then
    echo "  ✅ $name ($key): owner = $owner"
    ((ok++)) || true
  else
    echo "  ❌ $name ($key): owner = ${owner:-'(call failed)'}"
    ((fail++)) || true
  fi
done < <(
  if jq -e '.oracles' "$DEPLOYMENT_FILE" >/dev/null 2>&1; then
    jq -c '.oracles | to_entries[]' "$DEPLOYMENT_FILE" 2>/dev/null || true
  else
    jq -c '.implementations | to_entries[] | {key: .key, value: {name: .value.pair, address: .key}}' "$DEPLOYMENT_FILE" 2>/dev/null || true
  fi
)

echo ""
echo "Summary: $ok ok, $fail failed"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
echo "All oracles are owned by $EXPECTED_OWNER (no transfer needed)."
