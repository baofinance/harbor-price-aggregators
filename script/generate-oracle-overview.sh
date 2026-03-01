#!/usr/bin/env bash
set -euo pipefail

# Generate oracle deployment overview table
# Usage: ./script/generate-oracle-overview.sh > deployments/ORACLE_OVERVIEW.md

if ! command -v jq &> /dev/null; then
  echo "❌ ERROR: jq is required. Install with: brew install jq"
  exit 1
fi

echo "# Oracle Deployment Overview"
echo ""
echo "Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo ""
echo "This document provides a cross-chain overview of all deployed oracles."
echo ""

# Find all deployment JSON files
MAINNET_V4="deployments/mainnet/v4-oracles.json"
MAINNET_V3="deployments/mainnet/v3-aggregators.json"
MAINNET_LEVERAGE="deployments/mainnet/leverage-v4-oracles.json"
MEGAETH_V4="deployments/megaeth/v4-oracles.json"
ARBITRUM_V3="deployments/arbitrum/v3-oracles.json"
BASE_V3="deployments/base/v3-oracles.json"

# Temporary files for storing data
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

MAINNET_TMP="$TMP_DIR/mainnet.txt"
MAINNET_V3_TMP="$TMP_DIR/mainnet_v3.txt"
MAINNET_LEVERAGE_TMP="$TMP_DIR/mainnet_leverage.txt"
MEGAETH_TMP="$TMP_DIR/megaeth.txt"
ARBITRUM_TMP="$TMP_DIR/arbitrum.txt"
BASE_TMP="$TMP_DIR/base.txt"
ALL_PAIRS="$TMP_DIR/all_pairs.txt"

# Extract oracle data from v4 format (oracles object)
extract_oracles() {
  local file="$1"
  local output="$2"
  if [[ -f "$file" ]]; then
    jq -r '.oracles | to_entries[] | "\(.value.name)|\(.value.address)|\(.value.deprecated // false)"' "$file" > "$output" 2>/dev/null || true
  fi
}

# Extract oracle data from v3-aggregators format (proxies object)
extract_v3_aggregators() {
  local file="$1"
  local output="$2"
  if [[ -f "$file" ]]; then
    jq -r '.proxies | to_entries[] | "\(.key)|\(.value.address)|false"' "$file" > "$output" 2>/dev/null || true
  fi
}

extract_oracles "$MAINNET_V4" "$MAINNET_TMP"
extract_v3_aggregators "$MAINNET_V3" "$MAINNET_V3_TMP"
extract_oracles "$MAINNET_LEVERAGE" "$MAINNET_LEVERAGE_TMP"
extract_oracles "$MEGAETH_V4" "$MEGAETH_TMP"
extract_oracles "$ARBITRUM_V3" "$ARBITRUM_TMP"
extract_oracles "$BASE_V3" "$BASE_TMP"

# Merge all mainnet data (v4, v3, and leverage)
cat "$MAINNET_TMP" "$MAINNET_V3_TMP" "$MAINNET_LEVERAGE_TMP" 2>/dev/null > "$MAINNET_TMP.tmp" && mv "$MAINNET_TMP.tmp" "$MAINNET_TMP"

# Collect all unique oracle pairs
cat "$MAINNET_TMP" "$MEGAETH_TMP" "$ARBITRUM_TMP" "$BASE_TMP" 2>/dev/null | \
  cut -d'|' -f1 | sort -u > "$ALL_PAIRS"

# Helper function to find address for a pair
find_addr() {
  local pair="$1"
  local file="$2"
  grep "^${pair}|" "$file" 2>/dev/null | cut -d'|' -f2 | head -1
}

# Helper function to check if deprecated
is_deprecated() {
  local pair="$1"
  local file="$2"
  grep "^${pair}|" "$file" 2>/dev/null | cut -d'|' -f3 | grep -q "true" && echo "1" || echo ""
}

# Print table header
echo "## Deployment Matrix"
echo ""
echo "| Oracle Pair | Mainnet | Arbitrum | Base | MegaETH |"
echo "|-------------|---------|----------|------|---------|"

# Print each row
while IFS= read -r pair; do
  [[ -z "$pair" ]] && continue
  
  printf "| %s" "$pair"
  
  # Mainnet
  if addr=$(find_addr "$pair" "$MAINNET_TMP"); then
    if [[ -n "$(is_deprecated "$pair" "$MAINNET_TMP")" ]]; then
      printf " | ✅ (deprecated)"
    else
      printf " | ✅"
    fi
  else
    printf " | ❌"
  fi
  
  # Arbitrum
  if addr=$(find_addr "$pair" "$ARBITRUM_TMP"); then
    if [[ -n "$(is_deprecated "$pair" "$ARBITRUM_TMP")" ]]; then
      printf " | ✅ (deprecated)"
    else
      printf " | ✅"
    fi
  else
    printf " | ❌"
  fi
  
  # Base
  if addr=$(find_addr "$pair" "$BASE_TMP"); then
    if [[ -n "$(is_deprecated "$pair" "$BASE_TMP")" ]]; then
      printf " | ✅ (deprecated)"
    else
      printf " | ✅"
    fi
  else
    printf " | ❌"
  fi
  
  # MegaETH
  if addr=$(find_addr "$pair" "$MEGAETH_TMP"); then
    printf " | ✅"
  else
    printf " | ❌"
  fi
  
  echo " |"
done < "$ALL_PAIRS"

echo ""
echo "## Detailed Addresses"
echo ""

# Mainnet section
if [[ -s "$MAINNET_TMP" ]]; then
  echo "### Mainnet (Chain ID: 1)"
  echo ""
  echo "| Oracle | Address | Status | Version |"
  echo "|--------|---------|--------|---------|"
  while IFS='|' read -r pair addr deprecated; do
    status="Active"
    [[ "$deprecated" == "true" ]] && status="Deprecated"
    # Check if this pair exists in v3-aggregators or leverage
    version="v4"
    if grep -q "^${pair}|" "$MAINNET_V3_TMP" 2>/dev/null; then
      version="v3"
    elif grep -q "^${pair}|" "$MAINNET_LEVERAGE_TMP" 2>/dev/null; then
      version="v4 (leverage)"
    fi
    printf "| %s | \`%s\` | %s | %s |\n" "$pair" "$addr" "$status" "$version"
  done < "$MAINNET_TMP" | sort
  echo ""
fi

# MegaETH section
if [[ -f "$MEGAETH_V4" ]] && [[ -s "$MEGAETH_TMP" ]]; then
  echo "### MegaETH (Chain ID: 4326)"
  echo ""
  echo "| Oracle | Address | Status |"
  echo "|--------|---------|--------|"
  while IFS='|' read -r pair addr deprecated; do
    printf "| %s | \`%s\` | Active |\n" "$pair" "$addr"
  done < "$MEGAETH_TMP"
  echo ""
fi

# Arbitrum section
if [[ -f "$ARBITRUM_V3" ]] && [[ -s "$ARBITRUM_TMP" ]]; then
  echo "### Arbitrum (Chain ID: 42161)"
  echo ""
  echo "| Oracle | Address | Status |"
  echo "|--------|---------|--------|"
  while IFS='|' read -r pair addr deprecated; do
    status="Active"
    [[ "$deprecated" == "true" ]] && status="Deprecated"
    printf "| %s | \`%s\` | %s |\n" "$pair" "$addr" "$status"
  done < "$ARBITRUM_TMP"
  echo ""
fi

# Base section
if [[ -f "$BASE_V3" ]] && [[ -s "$BASE_TMP" ]]; then
  echo "### Base (Chain ID: 8453)"
  echo ""
  echo "| Oracle | Address | Status |"
  echo "|--------|---------|--------|"
  while IFS='|' read -r pair addr deprecated; do
    status="Active"
    [[ "$deprecated" == "true" ]] && status="Deprecated"
    printf "| %s | \`%s\` | %s |\n" "$pair" "$addr" "$status"
  done < "$BASE_TMP"
  echo ""
fi

# Summary statistics
mainnet_count=$(wc -l < "$MAINNET_TMP" 2>/dev/null || echo "0")
megaeth_count=$(wc -l < "$MEGAETH_TMP" 2>/dev/null || echo "0")
arbitrum_count=$(wc -l < "$ARBITRUM_TMP" 2>/dev/null || echo "0")
base_count=$(wc -l < "$BASE_TMP" 2>/dev/null || echo "0")
total_pairs=$(wc -l < "$ALL_PAIRS" 2>/dev/null || echo "0")

echo "## Summary Statistics"
echo ""
echo "- **Mainnet**: $mainnet_count oracles"
echo "- **MegaETH**: $megaeth_count oracles"
echo "- **Arbitrum**: $arbitrum_count oracles"
echo "- **Base**: $base_count oracles"
echo "- **Total Unique Pairs**: $total_pairs"
echo ""
echo "## Notes"
echo ""
echo "- Mainnet has v3, v4, and leverage v4 oracle contracts (v3 uses proxy pattern)"
echo "- MegaETH uses v4 oracle contracts"
echo "- Arbitrum and Base currently use v3 oracle contracts"
echo "- Deprecated oracles (XAU/XAG) have been replaced with GOLD/SILVER naming"
