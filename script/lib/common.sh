# Shared library for Harbor deployment scripts
#
# Source this file from deploy-impl, deploy-proxy, etc.
# Usage: source "$(dirname "$0")/lib/common.sh"
#
# Provides:
#   - Constants: FORGE, CAST, BAO_FACTORY, OWNER
#   - Variables (after init_common): RPC_NETWORK, CHAIN_ID, STATE_FILE, SIGNER_ARGS
#   - Functions: has_code, predict_proxy_address, record_implementation, record_proxy

# Ensure script fails on errors
set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────

FORGE=forge
CAST=cast
BAO_FACTORY=0xD696E56b3A054734d4C6DCBD32E11a278b0EC458
OWNER=0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2

# ── Shared variables (set by init_common) ──────────────────────────────────

RPC_NETWORK=""
CHAIN_ID=""
STATE_FILE=""
SIGNER_ARGS=()

# ── Helper functions ───────────────────────────────────────────────────────

has_code() {
  local addr=$1
  local code
  code=$("$CAST" code "$addr" --rpc-url "$RPC_NETWORK" 2>/dev/null | head -n 1 || echo "0x")
  [[ "$code" != "0x" ]]
}

# Wait for bytecode to be visible at address.
# Args: address [attempts] [sleep_seconds]
# Environment overrides:
#   DEPLOY_CODE_WAIT_ATTEMPTS (default 20)
#   DEPLOY_CODE_WAIT_SECONDS  (default 1)
wait_for_code() {
  local addr=$1
  local attempts=${2:-${DEPLOY_CODE_WAIT_ATTEMPTS:-20}}
  local sleep_seconds=${3:-${DEPLOY_CODE_WAIT_SECONDS:-1}}
  local i=0

  while [[ $i -lt $attempts ]]; do
    if has_code "$addr"; then
      return 0
    fi
    sleep "$sleep_seconds"
    ((i++))
  done

  return 1
}

# Optional 4th arg: salt suffix (default wrappedPriceAggregator). Used for MegaETH priceoracle etc.
predict_proxy_address() {
  local base=$1
  local quote=$2
  local salt_prefix=$3
  local suffix=${4:-wrappedPriceAggregator}
  local salt_str="${salt_prefix}::${base}::${quote}::${suffix}"
  local salt_b32
  salt_b32=$("$CAST" keccak "$("$CAST" from-utf8 "$salt_str")")
  "$CAST" call "$BAO_FACTORY" "predictAddress(bytes32)(address)" "$salt_b32" --rpc-url "$RPC_NETWORK"
}

record_implementation() {
  local state_file=$1
  local pair=$2
  local address=$3
  local contract_source=$4
  local contract_type=$5
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local tmp
  tmp=$(mktemp)
  jq \
    --arg addr "$address" \
    --arg pair "$pair" \
    --arg src "$contract_source" \
    --arg ctype "$contract_type" \
    --arg ts "$timestamp" \
    '.implementations[$addr] = {pair: $pair, contractSource: $src, contractType: $ctype, deploymentTime: $ts}' \
    "$state_file" >"$tmp" && mv "$tmp" "$state_file"
}

record_proxy() {
  local state_file=$1
  local pair=$2
  local address=$3
  local impl_address=$4
  local salt=$5
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local tmp
  tmp=$(mktemp)
  jq \
    --arg pair "$pair" \
    --arg addr "$address" \
    --arg impl "$impl_address" \
    --arg salt "$salt" \
    --arg ts "$timestamp" \
    '.proxies[$pair] = {address: $addr, implementation: $impl, salt: $salt, deploymentTime: $ts}' \
    "$state_file" >"$tmp" && mv "$tmp" "$state_file"
}

# Find the most recent implementation address for a given pair
# Returns empty string if not found
find_implementation_for_pair() {
  local state_file=$1
  local pair=$2
  jq -r --arg pair "$pair" '
    .implementations
    | to_entries
    | map(select(.value.pair == $pair))
    | sort_by(.value.deploymentTime)
    | last
    | .key // ""
  ' "$state_file"
}

# Get all unique pairs that have implementations
get_implementation_pairs() {
  local state_file=$1
  jq -r '.implementations | [.[].pair] | unique | .[]' "$state_file"
}

# Get all proxy pairs (keys of .proxies)
get_proxy_pairs() {
  local state_file=$1
  jq -r '.proxies | keys[]' "$state_file" 2>/dev/null || echo ""
}

# Get all implementation addresses
get_implementation_addresses() {
  local state_file=$1
  jq -r '.implementations | keys[]' "$state_file" 2>/dev/null | sort || echo ""
}

# Get implementation info by address
# Usage: get_implementation_info STATE_FILE ADDRESS FIELD
# FIELD: pair, contractSource, contractType, deploymentTime
get_implementation_info() {
  local state_file=$1
  local addr=$2
  local field=$3
  jq -r --arg addr "$addr" --arg field "$field" '.implementations[$addr][$field] // "-"' "$state_file"
}

# Get proxy info by pair
# Usage: get_proxy_info STATE_FILE PAIR FIELD
# FIELD: address, implementation, salt, deploymentTime
get_proxy_info() {
  local state_file=$1
  local pair=$2
  local field=$3
  jq -r --arg pair "$pair" --arg field "$field" '.proxies[$pair][$field] // "-"' "$state_file"
}

# ── Initialization functions ───────────────────────────────────────────────

# Resolve state file basename by network.
# MegaETH uses v4 naming; other networks remain on v3 naming.
state_basename_for_network() {
  local network=$1
  local salt_prefix=$2
  local base

  if [[ "$network" == "megaeth" ]]; then
    base="v4-aggregators"
  else
    base="v3-aggregators"
  fi

  if [[ "$salt_prefix" == "harbor_v1" ]]; then
    echo "${base}.json"
  else
    echo "${base}-${salt_prefix}.json"
  fi
}

# Check we're in project root
check_project_root() {
  if [[ ! -f "foundry.toml" ]] || [[ ! -d "src" ]]; then
    echo "❌ Must be run from the project root (missing foundry.toml or src/)" >&2
    exit 1
  fi
}

# Set up RPC and get chain ID
# Args: network use_local
init_rpc() {
  local network=$1
  local use_local=$2

  if [[ "$use_local" == true ]]; then
    RPC_NETWORK="local"
  else
    RPC_NETWORK="$network"
  fi

  if ! CHAIN_ID=$("$CAST" chain-id --rpc-url "$RPC_NETWORK" 2>&1); then
    echo "❌ Failed to fetch chainId from RPC '$RPC_NETWORK'" >&2
    echo "   $CHAIN_ID" >&2
    exit 1
  fi
}

# Set up state file path and validate
# Args: network salt_prefix [use_local]
init_state_file() {
  local network=$1
  local salt_prefix=$2
  local use_local=${3:-false}
  local state_version_tag="v3"
  if [[ "$network" == "megaeth" ]]; then
    state_version_tag="v4"
  fi

  local state_dir
  if [[ "$use_local" == "true" ]]; then
    state_dir="deployments/local/${network}"
  else
    state_dir="deployments/${network}"
  fi

  local state_basename
  state_basename=$(state_basename_for_network "$network" "$salt_prefix")
  STATE_FILE="${state_dir}/${state_basename}"

  # MegaETH migration path:
  # If new v4 state file doesn't exist yet but legacy v3 file does, copy it once.
  if [[ "$network" == "megaeth" ]] && [[ ! -f "$STATE_FILE" ]]; then
    local legacy_file
    if [[ "$salt_prefix" == "harbor_v1" ]]; then
      legacy_file="${state_dir}/v3-aggregators.json"
    else
      legacy_file="${state_dir}/v3-aggregators-${salt_prefix}.json"
    fi
    if [[ -f "$legacy_file" ]]; then
      cp "$legacy_file" "$STATE_FILE"
      echo "ℹ Migrated legacy MegaETH state: $legacy_file -> $STATE_FILE"
    fi
  fi

  # Create empty state if doesn't exist
  if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$state_dir"
    local chain_id
    chain_id=$("$CAST" chain-id --rpc-url "$RPC_NETWORK" 2>/dev/null || echo "1")
    cat >"$STATE_FILE" <<EOF
{
  "schemaVersion": 1,
  "version": "$state_version_tag",
  "network": "$network",
  "chainId": $chain_id,
  "baoFactory": "$BAO_FACTORY",
  "implementations": {},
  "proxies": {}
}
EOF
    echo "ℹ Created empty state: $STATE_FILE"
  fi

  # Validate schema
  local state_version
  state_version=$(jq -r '.schemaVersion // 0' "$STATE_FILE")
  if [[ "$state_version" != "1" ]]; then
    echo "❌ Unsupported state file schema version: $state_version (expected 1)" >&2
    exit 1
  fi

  # Keep state metadata aligned with network/version conventions.
  if [[ "$network" == "megaeth" ]]; then
    local current_version
    current_version=$(jq -r '.version // ""' "$STATE_FILE")
    if [[ "$current_version" != "v4" ]]; then
      local tmp
      tmp=$(mktemp)
      jq '.version = "v4"' "$STATE_FILE" >"$tmp" && mv "$tmp" "$STATE_FILE"
      echo "ℹ Normalized MegaETH state version to v4 in $STATE_FILE"
    fi
  fi

  local state_network
  state_network=$(jq -r '.network' "$STATE_FILE")
  if [[ "$state_network" != "$network" ]]; then
    echo "❌ State file network mismatch: $state_network (expected $network)" >&2
    exit 1
  fi
}

# Copy network state to local directory
# Args: network salt_prefix
copy_network_state() {
  local network=$1
  local salt_prefix=$2

  local local_dir="deployments/local/${network}"
  local state_basename
  state_basename=$(state_basename_for_network "$network" "$salt_prefix")
  local prod_file="deployments/${network}/${state_basename}"

  # MegaETH fallback: allow copying legacy v3 file if v4 file doesn't exist yet.
  if [[ "$network" == "megaeth" ]] && [[ ! -f "$prod_file" ]]; then
    if [[ "$salt_prefix" == "harbor_v1" ]]; then
      prod_file="deployments/${network}/v3-aggregators.json"
    else
      prod_file="deployments/${network}/v3-aggregators-${salt_prefix}.json"
    fi
  fi

  if [[ ! -f "$prod_file" ]]; then
    echo "❌ Network state not found: $prod_file" >&2
    exit 1
  fi
  mkdir -p "$local_dir"
  local local_file="${local_dir}/$(basename "$prod_file")"
  cp "$prod_file" "$local_file"
  echo "ℹ Copied $prod_file to $local_file"
}

# Set up signer arguments
# Args: use_local account_name
# Sets: SIGNER_ARGS array
init_signer() {
  local use_local=$1
  local account_name=$2

  SIGNER_ARGS=()
  if [[ -n "$account_name" ]]; then
    # Use account if provided (regardless of local mode)
    local password
    read -s -p "Enter password for account '$account_name': " password
    echo ""
    SIGNER_ARGS=(--account "$account_name" --password "$password")
  elif [[ "$use_local" == true ]]; then
    # Fall back to Anvil's test key only if local mode with no account
    SIGNER_ARGS=(--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
  fi
}

# Check and set up BaoFactory operator status
# Args: deployer_address use_local
# Returns: 0 if operator, exits on failure for non-local
ensure_bao_operator() {
  local deployer=$1
  local use_local=$2

  local is_op
  is_op=$("$CAST" call "$BAO_FACTORY" "isCurrentOperator(address)(bool)" "$deployer" --rpc-url "$RPC_NETWORK" 2>/dev/null)

  if [[ "$is_op" == "true" ]]; then
    echo "BaoFactory operator: ✓"
    return 0
  fi

  echo "BaoFactory operator: ✗"

  local set_operator_calldata
  set_operator_calldata=$("$CAST" calldata "setOperator(address,uint256)" "$deployer" 500000)

  if [[ "$use_local" == true ]]; then
    echo "Setting operator as OWNER (local mode)..."
    if ! "$CAST" send "$BAO_FACTORY" "setOperator(address,uint256)" "$deployer" 500000 \
      --from "$OWNER" --unlocked --rpc-url "$RPC_NETWORK" --json >/dev/null 2>&1; then
      echo "❌ Failed to set operator. Start anvil with --auto-impersonate." >&2
      exit 1
    fi
    echo "✓ Operator set"
  else
    echo ""
    echo "⚠ Deployer is not an operator. Execute via Safe first:"
    echo ""
    echo "  Safe Transaction Builder (setOperator):"
    echo "    To:        $BAO_FACTORY"
    echo "    Value:     0"
    echo "    Data:      $set_operator_calldata"
    echo "    Operation: CALL"
    echo ""
    echo "❌ Cannot proceed without operator status." >&2
    exit 1
  fi
}

# Validate pair format
# Args: pair
validate_pair_format() {
  local pair=$1
  if [[ ! "$pair" =~ ^[a-zA-Z0-9.]+/[a-zA-Z0-9.]+$ ]]; then
    echo "❌ Invalid pair format: $pair (expected BASE/QUOTE)" >&2
    return 1
  fi
}

# Get contract details for a pair
# Args: pair network
# Outputs: contract_source contract_type contract_id (space-separated)
get_contract_details() {
  local pair=$1
  local network=$2

  IFS='/' read -r base quote <<<"$pair"
  local base_file="${base//./}"
  local quote_file="${quote//./}"
  local contract_type="Aggregator_${base_file}_${quote_file}_${network}"
  local contract_source="src/${network}/${contract_type}.sol"
  local contract_id="${contract_source}:${contract_type}"

  echo "$contract_source $contract_type $contract_id"
}

# ── Verification functions ─────────────────────────────────────────────────

# Verify a contract on Etherscan
# Args: address contract_id network [constructor_args]
# Returns: 0 on success/already verified, 1 on failure
verify_contract() {
  local address=$1
  local contract_id=$2
  local network=$3
  local constructor_args=${4:-}
  local max_retries=3
  local retry=0

  local chain_arg
  if [[ "$network" == "megaeth" ]]; then
    # forge verify-contract may not recognize custom network aliases,
    # but numeric chain IDs are accepted.
    chain_arg="4326"
  else
    chain_arg="$network"
  fi

  local forge_args=("$address" "$contract_id" --chain "$chain_arg" --watch)
  if [[ -n "$constructor_args" ]]; then
    forge_args+=(--constructor-args "$constructor_args")
  fi

  while [[ $retry -lt $max_retries ]]; do
    local verify_output
    verify_output=$("$FORGE" verify-contract "${forge_args[@]}" 2>&1) || true

    if echo "$verify_output" | grep -q "Contract successfully verified"; then
      echo "  ✅ Verified"
      return 0
    elif echo "$verify_output" | grep -qi "already verified"; then
      echo "  ✅ Already verified"
      return 0
    else
      retry=$((retry + 1))
      if [[ $retry -lt $max_retries ]]; then
        echo "  ⏳ Retrying ($retry/$max_retries)..."
        sleep 3
      fi
    fi
  done

  echo "  ❌ Verification failed"
  echo "$verify_output" | grep -E "(Error|error|Failed|failed)" | head -3 | sed 's/^/     /'
  return 1
}
