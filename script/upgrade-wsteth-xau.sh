#!/usr/bin/env bash
set -euo pipefail

# Upgrade wstETH/XAU Proxy to New Implementation
# Proxy Address: 0x779e83258095464723eD42B2788e87a81d02E4E8

# Load environment variables
if [[ -f .env.local ]]; then
  set -a
  source .env.local
  set +a
elif [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi

# Configuration: REQUIRED environment variables
if [[ -z "${RPC_URL:-}" ]]; then
  echo "❌ ERROR: RPC_URL is not set"
  exit 1
fi

PRIVATE_KEY=${PRIVATE_KEY_LOCAL:-${PRIVATE_KEY:-}}
OWNER=${OWNER:-}

if [[ -z "$PRIVATE_KEY" ]]; then
  echo "❌ ERROR: PRIVATE_KEY is not set"
  exit 1
fi
if [[ -z "$OWNER" ]]; then
  echo "❌ ERROR: OWNER is not set"
  exit 1
fi

FORGE=${FORGE:-$HOME/.foundry/bin/forge}
CAST=${CAST:-$HOME/.foundry/bin/cast}

PROXY_ADDRESS="0x779e83258095464723eD42B2788e87a81d02E4E8"
NEW_IMPL_ADDRESS="${NEW_IMPL_ADDRESS:-}"

# ERC1967 implementation slot
IMPLEMENTATION_SLOT="0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

echo "=== Checking Current Implementation ==="
echo "Proxy: $PROXY_ADDRESS"

# Get current implementation address
CURRENT_IMPL=$("$CAST" storage "$PROXY_ADDRESS" "$IMPLEMENTATION_SLOT" --rpc-url "$RPC_URL" | tail -1)
CURRENT_IMPL_ADDRESS="0x$(echo "$CURRENT_IMPL" | cut -c 27-)"
echo "Current Implementation: $CURRENT_IMPL_ADDRESS"

# Get owner
OWNER_CHECK=$("$CAST" call "$PROXY_ADDRESS" "owner()(address)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
if [[ -n "$OWNER_CHECK" ]]; then
  echo "Current Owner: $OWNER_CHECK"
  if [[ "$OWNER_CHECK" != "$OWNER" ]]; then
    echo "⚠️  WARNING: Owner mismatch! Expected: $OWNER, Got: $OWNER_CHECK"
    echo "   Make sure you're using the correct PRIVATE_KEY"
  fi
fi

# Get oracle name
ORACLE_NAME=$("$CAST" call "$PROXY_ADDRESS" "oracleName()(string)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
if [[ -n "$ORACLE_NAME" ]]; then
  echo "Oracle Name: $ORACLE_NAME"
fi

# Check if new implementation is provided
if [[ -z "$NEW_IMPL_ADDRESS" ]] || [[ "$NEW_IMPL_ADDRESS" == "" ]]; then
  echo ""
  echo "❌ ERROR: NEW_IMPL_ADDRESS is not set"
  echo "   Set it via: export NEW_IMPL_ADDRESS='0x...'"
  echo ""
  echo "   Example:"
  echo "   export NEW_IMPL_ADDRESS='0xAbBD1bc15365D3BaB403612b96F4A3C3aA4B8227'"
  exit 1
fi

if [[ "$CURRENT_IMPL_ADDRESS" == "$NEW_IMPL_ADDRESS" ]]; then
  echo ""
  echo "⚠️  WARNING: New implementation address is the same as current implementation"
  echo "   Current: $CURRENT_IMPL_ADDRESS"
  echo "   New:     $NEW_IMPL_ADDRESS"
  echo "   No upgrade needed!"
  exit 0
fi

echo ""
echo "=== Upgrade Details ==="
echo "Proxy: $PROXY_ADDRESS"
echo "From:  $CURRENT_IMPL_ADDRESS"
echo "To:    $NEW_IMPL_ADDRESS"
echo "Owner: $OWNER"
echo ""

# Confirm upgrade
read -p "⚠️  Are you sure you want to upgrade this proxy? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Upgrade cancelled."
  exit 0
fi

echo ""
echo "=== Performing Upgrade ==="

# Perform upgrade
# upgradeToAndCall(address newImplementation, bytes memory data)
# For UUPS, we call upgradeToAndCall on the proxy itself
TX_HASH=$("$CAST" send "$PROXY_ADDRESS" \
  "upgradeToAndCall(address,bytes)" \
  "$NEW_IMPL_ADDRESS" \
  "0x" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
  --json 2>/dev/null | jq -r '.transactionHash // empty' || echo "")

if [[ -z "$TX_HASH" ]] || [[ "$TX_HASH" == "null" ]] || [[ "$TX_HASH" == "" ]]; then
  echo "❌ Failed to send upgrade transaction"
  exit 1
fi

echo "✅ Upgrade transaction sent: $TX_HASH"
echo "⏳ Waiting for confirmation..."
sleep 5

# Verify upgrade
NEW_IMPL_CHECK=$("$CAST" storage "$PROXY_ADDRESS" "$IMPLEMENTATION_SLOT" --rpc-url "$RPC_URL" | tail -1)
NEW_IMPL_CHECK_ADDRESS="0x$(echo "$NEW_IMPL_CHECK" | cut -c 27-)"

if [[ "$NEW_IMPL_CHECK_ADDRESS" == "$NEW_IMPL_ADDRESS" ]]; then
  echo "✅ Upgrade successful!"
  echo "   New implementation: $NEW_IMPL_CHECK_ADDRESS"
  
  # Verify functionality still works
  echo ""
  echo "=== Verifying Functionality ==="
  PRICE=$("$CAST" call "$PROXY_ADDRESS" "getPrice()(uint256)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
  if [[ -n "$PRICE" ]] && [[ "$PRICE" != "0" ]]; then
    echo "✅ Oracle is working! Price: $PRICE"
  else
    echo "⚠️  Could not fetch price - please verify manually"
  fi
  
  ORACLE_NAME_AFTER=$("$CAST" call "$PROXY_ADDRESS" "oracleName()(string)" --rpc-url "$RPC_URL" 2>/dev/null || echo "")
  if [[ -n "$ORACLE_NAME_AFTER" ]]; then
    echo "✅ Oracle name preserved: $ORACLE_NAME_AFTER"
  fi
else
  echo "❌ Upgrade verification failed"
  echo "   Expected: $NEW_IMPL_ADDRESS"
  echo "   Got:      $NEW_IMPL_CHECK_ADDRESS"
  echo "   Transaction: $TX_HASH"
  exit 1
fi

echo ""
echo "=== Upgrade Complete ==="
echo "Transaction: $TX_HASH"
echo "View on Etherscan: https://etherscan.io/tx/$TX_HASH"



