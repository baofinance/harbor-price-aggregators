#!/usr/bin/env bash
set -euo pipefail

# Deploy the ETH peg's two price oracles (implementation + deterministic CREATE3 proxy via BaoFactory),
# using the generic per-oracle deployer. Each lands at
#
#     <salt-prefix>::<base>::ETH::wrappedPriceAggregator
#
# which are exactly the CREATE3 addresses the harbor / harbor-yield deploy predicts:
#
#   - Aggregator_ETH_ETH_mainnet    peg/ETH gas-floor oracle (constant 1e18)
#                                    consumed by harbor's AutoCompounder._ethPriceOracleAddress
#                                    -> salt <prefix>::ETH::ETH::wrappedPriceAggregator
#   - Aggregator_stETH_ETH_mainnet  wstETH equivalent-vault valuation oracle
#                                    consumed by harbor-yield's HarborYieldDeployStack._equivalentOracleAddress
#                                    -> salt <prefix>::stETH::ETH::wrappedPriceAggregator
#
# SALT_PREFIX must match the harbor ETH minter deploy salt so the predicted and deployed
# addresses agree. RPC and signing are handled by deploy-one-aggregator (--network resolves
# foundry.toml rpc_endpoints; --account is a foundry keystore account).
#
# Usage (run from anywhere; cd's to the repo root itself):
#   SALT_PREFIX=harbor_v1 ACCOUNT=<keystore-account> \
#     script/mainnet/deploy/deploy-mainnet-eth-oracles.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

NETWORK="${NETWORK:-mainnet}"
SALT_PREFIX="${SALT_PREFIX:-harbor_v1}"
ACCOUNT="${ACCOUNT:-}"

ONE="$REPO_ROOT/script/deploy-one-aggregator"

COMMON=(--network "$NETWORK" --salt "$SALT_PREFIX")
if [[ -n "$ACCOUNT" ]]; then
  COMMON+=(--account "$ACCOUNT")
fi

echo "=== Deploying ETH peg oracles ==="
echo "  network:     $NETWORK"
echo "  salt prefix: $SALT_PREFIX"
echo ""

# Two independent CREATE3 deployments (order irrelevant). deploy-one-aggregator skips any
# oracle already deployed at its predicted address, so this is safe to re-run.
echo "--- 1/2: Aggregator_ETH_ETH (peg/ETH gas-floor) ---"
"$ONE" "${COMMON[@]}" --base ETH --quote ETH --deploy

echo ""
echo "--- 2/2: Aggregator_stETH_ETH (wstETH equivalent valuation) ---"
"$ONE" "${COMMON[@]}" --base stETH --quote ETH --deploy

echo ""
echo "=== Done. Both ETH oracles deployed at <${SALT_PREFIX}>::<base>::ETH::wrappedPriceAggregator ==="
