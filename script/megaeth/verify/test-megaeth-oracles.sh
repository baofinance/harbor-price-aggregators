#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$REPO_ROOT"

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

echo "=== Testing MegaETH Oracles ==="
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
    
    # Harbor v3 oracles always return 18 decimals (IWrappedPriceOracle); aggregator has no decimals().
    decimals_val="18"
    
    if [[ -n "$base_name" ]] && [[ -n "$quote_name" ]]; then
      echo "  📋 Oracle Info:"
      if [[ -n "$oracle_name" ]]; then
        echo "     Name: $oracle_name"
      fi
      echo "     Base: $base_name"
      echo "     Quote: $quote_name"
      echo "     Decimals: $decimals_val"
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
    
    # Parse the output - cast returns 4 values (minPrice, maxPrice, minRate, maxRate).
    # Price-only oracles (e.g. BTC/USD, BTC.b/USD) have rate 0; cast may show one number per line.
    numbers=()
    while IFS= read -r line; do
      [[ ${#numbers[@]} -ge 4 ]] && break
      if [[ "$line" =~ ^[[:space:]]*([0-9]+) ]]; then
        numbers+=("${BASH_REMATCH[1]}")
      fi
    done < <(echo "$latest_answer_output")
    numbers=("${numbers[@]:0:4}")
    
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
    
    # Price must be non-trivial; rate may be 0 for price-only oracles
    if [[ ${#min_price} -lt 6 ]] || [[ ${#max_price} -lt 6 ]]; then
      echo "  ⚠️  Warning: Parsed price values seem too small"
      echo "     Raw output:"
      echo "$latest_answer_output" | head -15 | sed 's/^/     /'
      return 1
    fi
    
    echo "  ✅ latestAnswer() successful:"
    echo "     Raw values (18 decimals):"
    echo "       Price: $min_price (min) / $max_price (max)"
    echo "       Rate:  $min_rate (min) / $max_rate (max)"
    
    # Convert to human-readable format using bc if available
    # Price = quote per 1 base (e.g. 1 BTC.b = X USD); base_name/quote_name from oracle
    base=${base_name:-BASE}
    quote=${quote_name:-QUOTE}
    if command -v bc &> /dev/null; then
      # price / 1e18 = quote per 1 base (e.g. USD per 1 BTC.b)
      price_decimal=$(echo "scale=18; $min_price / 1000000000000000000" | bc)
      # 1 quote = 1/price base (e.g. 1 USD = X BTC.b); use scale 8 for small inverses
      quote_per_base=$(echo "scale=8; 1000000000000000000 / $min_price" | bc)
      # Trim trailing zeros for readability
      quote_per_base=$(echo "$quote_per_base" | sed 's/0*$//' | sed 's/\.$//')
      
      echo ""
      echo "     Human-readable prices:"
      echo "       1 $base = $price_decimal $quote"
      echo "       1 $quote = $quote_per_base $base"
    else
      echo ""
      echo "     ⚠️  Install 'bc' to see human-readable prices"
      quote_per_base_approx=$(awk "BEGIN {printf \"%.8f\", 1000000000000000000 / $min_price}")
      echo "     Quick calc: 1 $quote ≈ $quote_per_base_approx $base"
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
