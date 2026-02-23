#!/usr/bin/env bash
set -euo pipefail

# Ensure output is not buffered
export PYTHONUNBUFFERED=1 2>/dev/null || true

# Test MegaETH oracle inputs: Chainlink feeds and rate source
# Usage: ./script/test-megaeth-oracles.sh

# Use full path to cast
CAST=${CAST:-$HOME/.foundry/bin/cast}

# Verify cast exists
if [[ ! -f "$CAST" ]] && ! command -v cast &> /dev/null; then
  echo "❌ ERROR: cast not found"
  echo "   Expected at: $CAST"
  echo "   Or install Foundry: https://book.getfoundry.sh/getting-started/installation"
  exit 1
fi

# Use cast from PATH if full path doesn't exist but cast is in PATH
if [[ ! -f "$CAST" ]] && command -v cast &> /dev/null; then
  CAST=$(command -v cast)
  echo "ℹ️  Using cast from PATH: $CAST"
fi

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

echo "=== Testing MegaETH Oracle Inputs ==="
echo "Testing Chainlink feed values and USDMY rate source"
echo "RPC URL: $MEGAETH_RPC_URL"
echo ""

# Test RPC connectivity first
echo "🔌 Testing RPC connectivity..."
set +e
chain_id=$("$CAST" chain-id --rpc-url "$MEGAETH_RPC_URL" 2>&1)
rpc_test=$?
set -e

if [[ $rpc_test -ne 0 ]]; then
  echo "❌ ERROR: Cannot connect to RPC"
  echo "   Error: $chain_id"
  echo "   Please check your MEGAETH_RPC_URL"
  exit 1
else
  echo "✅ RPC connected (Chain ID: $chain_id)"
fi
echo ""

# Feed addresses (from constants)
USDM_USD_FEED="0xdFe0063491d9DeD8F8abCdd7AE04238A1e70D270"
ETH_USD_FEED="0xcA4e254D95637DE95E2a2F79244b03380d697feD"
HYPE_USD_FEED="0x642C7127cDC688816e91CB9664322401B909d77c"
SOL_USD_FEED="0x53c05390FdfDB63526Ac0814825093A68eaddC87"
BTC_USD_FEED="0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721"

# Rate provider
USDMY_VAULT="0x2eA493384F42d7Ea78564F3EF4C86986eAB4a890"

# Helper function to format wei to readable number
format_wei() {
  local value=$1
  local decimals=${2:-18}
  # Use bc for precision calculation if available, otherwise just show raw value
  if command -v bc &> /dev/null; then
    echo "scale=8; $value / 10^$decimals" | bc | sed 's/^\./0./' | sed 's/0*$//' | sed 's/\.$//'
  else
    echo "$value (wei, $decimals decimals)"
  fi
}

# Function to get feed latest round data
get_feed_data() {
  local feed_address=$1
  local feed_name=$2
  local heartbeat=$3
  
  set +e
  echo "  ⏳ Calling latestRoundData() for $feed_name..."
  
  # Make the call - cast should work fine
  result=$("$CAST" call "$feed_address" "latestRoundData()(uint80,int256,uint256,uint256,uint80)" --rpc-url "$MEGAETH_RPC_URL" 2>&1)
  exit_code=$?
  set -e
  
  if [[ $exit_code -ne 0 ]]; then
    echo "  ❌ Cast call failed (exit code: $exit_code)"
    echo "  Error: $result"
    return 1
  fi
  
  if [[ $exit_code -eq 0 ]]; then
    # Parse cast's labeled output format
    # Cast returns: roundId (uint80) : 18446744073709553167
    #               answer (int256) : 6468706258748
    #               startedAt (uint256) : 1771880868
    #               updatedAt (uint256) : 1771880881
    #               answeredInRound (uint80) : 18446744073709553167
    
    # Extract values: look for field name, then colon, then number
    round_id=""
    price=""
    started_at=""
    updated_at=""
    answered_in_round=""
    
    # Read line by line - most reliable method
    while IFS= read -r line || [[ -n "$line" ]]; do
      # Extract roundId
      if [[ "$line" =~ roundId.*:.*([0-9-]+) ]]; then
        round_id="${BASH_REMATCH[1]}"
      fi
      # Extract answer (but not answeredInRound)
      if [[ "$line" =~ ^[[:space:]]*answer[[:space:]] && ! "$line" =~ answeredInRound ]]; then
        if [[ "$line" =~ :[[:space:]]*([0-9-]+) ]]; then
          price="${BASH_REMATCH[1]}"
        fi
      fi
      # Extract startedAt
      if [[ "$line" =~ startedAt.*:.*([0-9-]+) ]]; then
        started_at="${BASH_REMATCH[1]}"
      fi
      # Extract updatedAt
      if [[ "$line" =~ updatedAt.*:.*([0-9-]+) ]]; then
        updated_at="${BASH_REMATCH[1]}"
      fi
      # Extract answeredInRound
      if [[ "$line" =~ answeredInRound.*:.*([0-9-]+) ]]; then
        answered_in_round="${BASH_REMATCH[1]}"
      fi
    done <<< "$result"
    
    # Get decimals (non-blocking, use default if fails)
    set +e
    decimals_output=$("$CAST" call "$feed_address" "decimals()(uint8)" --rpc-url "$MEGAETH_RPC_URL" 2>&1)
    if [[ $? -eq 0 ]]; then
      decimals=$(echo "$decimals_output" | grep -Eo '[0-9]+' | head -1)
    else
      decimals="8"  # Default
    fi
    set -e
    
    # Get current block timestamp (non-blocking, skip if slow)
    current_time=""
    set +e
    block_output=$("$CAST" block latest --rpc-url "$MEGAETH_RPC_URL" 2>&1 | head -20)
    if [[ $? -eq 0 ]]; then
      current_time=$(echo "$block_output" | grep -Eo 'timestamp:[0-9]+' | cut -d: -f2 | head -1)
    fi
    set -e
    
    echo "  ✅ $feed_name:"
    echo "     Address: $feed_address"
    
    # Normalize price to 18 decimals for display
    if [[ -n "$price" ]] && [[ "$price" =~ ^[0-9-]+$ ]]; then
      # Handle negative prices (shouldn't happen for Chainlink but int256 can be negative)
      if [[ "$price" =~ ^- ]]; then
        price_abs="${price#-}"
        is_negative=true
      else
        price_abs="$price"
        is_negative=false
      fi
      
      # Simple display - skip bc normalization to avoid hangs
      echo "     Price (raw, ${decimals} decimals): $price"
      if [[ "$decimals" -ne 18 ]]; then
        echo "     Note: Price is in ${decimals} decimals (not normalized to 18)"
      fi
    else
      echo "     Price: $price (could not parse)"
    fi
    
    echo "     Decimals: $decimals"
    echo "     Updated At: $updated_at"
    
    if [[ -n "$current_time" ]] && [[ -n "$updated_at" ]] && [[ "$updated_at" != "0" ]]; then
      age=$((current_time - updated_at))
      max_age=$((heartbeat + 42))  # heartbeat + tolerance
      
      echo "     Current Time: $current_time"
      echo "     Age: $age seconds"
      echo "     Max Age: $max_age seconds (heartbeat: $heartbeat + 42s tolerance)"
      
      if [[ $age -gt $max_age ]]; then
        echo "     ⚠️  STALE! Feed is older than allowed ($age > $max_age)"
        return 2
      else
        echo "     ✅ Fresh (within heartbeat)"
      fi
    elif [[ "$updated_at" == "0" ]]; then
      echo "     ❌ Feed never updated!"
      return 3
    fi
    
    return 0
  else
    echo "  ❌ $feed_name: Failed to read ($result)"
    return 1
  fi
}

# Function to get rate from USDMY vault
get_rate() {
  local vault_address=$1
  
  set +e
  echo "  ⏳ Calling convertToAssets() for USDMY vault..."
  rate=$("$CAST" call "$vault_address" "convertToAssets(uint256)(uint256)" 1000000000000000000 --rpc-url "$MEGAETH_RPC_URL" 2>&1)
  exit_code=$?
  set -e
  
  if [[ $exit_code -eq 0 ]]; then
    rate_value=$(echo "$rate" | grep -Eo '[0-9]+' | head -1)
    echo "  ✅ USDMY Rate:"
    echo "     Vault: $vault_address"
    echo "     Rate: $rate_value (raw, 18 decimals)"
    return 0
  else
    echo "  ❌ USDMY Rate: Failed to read ($rate)"
    return 1
  fi
}

# Test all feeds and rate
echo "Testing all Chainlink feeds and USDMY rate..."
echo ""

# Test USDM/USD feed (used by all oracles)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 USDM/USD Feed (First Feed for all oracles)"
echo ""
HEARTBEAT=86400
get_feed_data "$USDM_USD_FEED" "USDM/USD" "$HEARTBEAT"
echo ""

# Test all quote asset feeds
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 ETH/USD Feed (for USDMY/ETH)"
echo ""
get_feed_data "$ETH_USD_FEED" "ETH/USD" "$HEARTBEAT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 HYPE/USD Feed (for USDMY/HYPE)"
echo ""
get_feed_data "$HYPE_USD_FEED" "HYPE/USD" "$HEARTBEAT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 SOL/USD Feed (for USDMY/SOL)"
echo ""
get_feed_data "$SOL_USD_FEED" "SOL/USD" "$HEARTBEAT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📡 BTC/USD Feed (for USDMY/BTC)"
echo ""
get_feed_data "$BTC_USD_FEED" "BTC/USD" "$HEARTBEAT"
echo ""

# Test rate
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💹 USDMY Rate Source"
echo ""
get_rate "$USDMY_VAULT"
echo ""

# Test deployed oracles
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔮 Testing Deployed Oracles (latestAnswer)"
echo ""

DEPLOYMENT_FILE="deployments/megaeth/v4-oracles.json"

if [[ ! -f "$DEPLOYMENT_FILE" ]]; then
  echo "  ⚠️  Deployment file not found: $DEPLOYMENT_FILE"
  echo "     Skipping oracle tests"
else
  # Function to test an oracle's latestAnswer
  test_oracle_answer() {
    local address=$1
    local name=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing $name at $address"
    echo ""
    
    # Get oracle metadata
    set +e
    oracle_name_output=$("$CAST" call "$address" "oracleName()(string)" --rpc-url "$MEGAETH_RPC_URL" 2>&1)
    base_name_output=$("$CAST" call "$address" "baseName()(string)" --rpc-url "$MEGAETH_RPC_URL" 2>&1)
    quote_name_output=$("$CAST" call "$address" "quoteName()(string)" --rpc-url "$MEGAETH_RPC_URL" 2>&1)
    set -e
    
    # Parse cast string output - cast returns: (string) : "USDMY"
    # Extract the string value (remove quotes, parentheses, colons, etc.)
    oracle_name=$(echo "$oracle_name_output" | sed -n 's/.*"\([^"]*\)".*/\1/p' | head -1)
    base_name=$(echo "$base_name_output" | sed -n 's/.*"\([^"]*\)".*/\1/p' | head -1)
    quote_name=$(echo "$quote_name_output" | sed -n 's/.*"\([^"]*\)".*/\1/p' | head -1)
    
    # Fallback: if sed doesn't work, try grep
    if [[ -z "$base_name" ]]; then
      base_name=$(echo "$base_name_output" | grep -Eo '[A-Za-z0-9]+' | tail -1 || echo "")
    fi
    if [[ -z "$quote_name" ]]; then
      quote_name=$(echo "$quote_name_output" | grep -Eo '[A-Za-z0-9]+' | tail -1 || echo "")
    fi
    
    if [[ -n "$base_name" ]] && [[ -n "$quote_name" ]]; then
      echo "  📋 Oracle Info:"
      if [[ -n "$oracle_name" ]]; then
        echo "     Name: $oracle_name"
      fi
      echo "     Base: $base_name"
      echo "     Quote: $quote_name"
      echo ""
    fi
    
    set +e
    latest_answer_output=$("$CAST" call "$address" "latestAnswer()(uint256,uint256,uint256,uint256)" --rpc-url "$MEGAETH_RPC_URL" 2>&1)
    latest_answer_exit=$?
    set -e
    
    if [[ $latest_answer_exit -ne 0 ]]; then
      if echo "$latest_answer_output" | grep -qi "StaleFeedData\|stale"; then
        echo "  ❌ StaleFeedData error (feed is too old)"
      else
        echo "  ❌ Failed: $(echo "$latest_answer_output" | head -3 | tr '\n' ' ')"
      fi
      return 1
    fi
    
    # Parse the output - cast returns values like:
    # (uint256) : 535364065676779
    # (uint256) : 535364065676779
    # (uint256) : 1000000046447315924
    # (uint256) : 1000000046447315924
    
    # Simple approach: extract only very large numbers (12+ digits) - these are definitely uint256 values
    # This avoids picking up line numbers, error codes, or other small metadata
    numbers=($(echo "$latest_answer_output" | grep -Eo '[0-9]{12,}' | head -4))
    
    # If we didn't get 4 numbers, try a more lenient approach (10+ digits)
    if [[ ${#numbers[@]} -lt 4 ]]; then
      numbers=($(echo "$latest_answer_output" | grep -Eo '[0-9]{10,}' | head -4))
    fi
    
    if [[ ${#numbers[@]} -lt 4 ]]; then
      echo "  ⚠️  Could not parse output (expected 4 values, found ${#numbers[@]})"
      echo "     Raw output:"
      echo "$latest_answer_output" | head -15 | sed 's/^/     /'
      return 1
    fi
    
    min_price="${numbers[0]}"
    max_price="${numbers[1]}"
    min_rate="${numbers[2]}"
    max_rate="${numbers[3]}"
    
    # Basic validation - check if values are reasonable (at least 6 digits)
    if [[ ${#min_price} -lt 6 ]] || [[ ${#max_price} -lt 6 ]] || [[ ${#min_rate} -lt 6 ]] || [[ ${#max_rate} -lt 6 ]]; then
      echo "  ⚠️  Warning: Parsed values seem too small"
      echo "     Raw output:"
      echo "$latest_answer_output" | head -15 | sed 's/^/     /'
      return 1
    fi
    
    echo "  ✅ latestAnswer() successful:"
    echo "     Raw values (18 decimals):"
    echo "       Price: $min_price (min) / $max_price (max)"
    echo "       Rate:  $min_rate (min) / $max_rate (max)"
    
    # Convert to human-readable format using bc if available
    if command -v bc &> /dev/null; then
      # Price is in 18 decimals: price / 1e18 = ETH per USDMY
      # For USDMY/ETH oracle: price represents how much ETH you get for 1 USDMY
      # Since USDMY ≈ USD, this is approximately ETH per USD
      price_decimal=$(echo "scale=18; $min_price / 1000000000000000000" | bc)
      
      # Invert: Calculate USD per ETH
      # If 1 USDMY = price_decimal ETH, then 1 ETH = 1/price_decimal USDMY
      # Formula: (1e18 / min_price) gives USDMY per ETH in 18 decimals
      # Then divide by 1e18 to get readable number
      usd_per_eth=$(echo "scale=2; 1000000000000000000 / $min_price" | bc)
      
      echo ""
      echo "     Human-readable prices:"
      echo "       1 USDMY = $price_decimal ETH"
      echo "       1 ETH = $usd_per_eth USDMY (≈ $usd_per_eth USD)"
      
      # Also show the rate
      rate_decimal=$(echo "scale=18; $min_rate / 1000000000000000000" | bc)
      echo "       USDMY Rate: $rate_decimal (1 USDMY share = $rate_decimal USDMY assets)"
    else
      echo ""
      echo "     ⚠️  Install 'bc' to see human-readable prices"
      # Quick calculation without bc: 1 ETH ≈ (1e18 / price) USDMY
      usd_per_eth_approx=$(awk "BEGIN {printf \"%.2f\", 1000000000000000000 / $min_price}")
      echo "     Quick calc: 1 ETH ≈ $usd_per_eth_approx USDMY"
    fi
    
    return 0
  }
  
  # Test each oracle from deployment file
  if command -v jq &> /dev/null; then
    oracle_count=$(jq '.oracles | length' "$DEPLOYMENT_FILE" 2>/dev/null || echo "0")
    
    if [[ "$oracle_count" -gt 0 ]]; then
      jq -r '.oracles | to_entries[] | "\(.key)|\(.value.name)|\(.value.address)"' "$DEPLOYMENT_FILE" | while IFS='|' read -r key name address; do
        test_oracle_answer "$address" "$name"
        echo ""
      done
    else
      echo "  ⚠️  No oracles found in deployment file"
    fi
  else
    echo "  ⚠️  'jq' not found - cannot read deployment file"
    echo "     Install jq to test deployed oracles"
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Testing Complete"
echo ""
echo "Summary:"
echo "  - Check feed update times above to identify stale feeds"
echo "  - Feed age must be < 86442 seconds (86400s heartbeat + 42s tolerance)"
echo "  - Rate should be >= 0.9 (9e17) to pass validation"
echo "  - Oracle latestAnswer() tested above"
