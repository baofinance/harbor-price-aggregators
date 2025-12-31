# Arbitrum v3 Oracle Deployment Scripts (Unsalted)

## Overview

These scripts deploy and verify all Arbitrum v3 oracle contracts using **unsalted deployments** (regular addresses, not predictable). The v3 oracles are direct deployments (no proxies) with hardcoded wiring.

**Note:** For main deployments using predictable addresses (CREATE3), use the main deployment scripts.

## Scripts

### 1. `deploy-arbitrum-v3-oracles.sh`
Deploys all 20 Arbitrum v3 oracles and optionally verifies them at the end.

### 2. `verify-arbitrum-v3-oracles.sh`
Re-verifies all deployed contracts from the deployment JSON file.

## Required Environment Variables

Set these in your `.env` file or export them:

```bash
ARBITRUM_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/...
PRIVATE_KEY=0x...                    # Required for deployment
ETHERSCAN_API_KEY=...                # Required for verification
```

## Usage

### Deploy All Oracles

```bash
# Deploy with verification at the end (default)
./script/deploy-arbitrum-v3-oracles.sh

# Deploy without verification
VERIFY=false ./script/deploy-arbitrum-v3-oracles.sh

# Force redeploy all contracts
FORCE_REDEPLOY=true ./script/deploy-arbitrum-v3-oracles.sh

# Verify-only mode (reads from deployment file)
./script/deploy-arbitrum-v3-oracles.sh verify
```

### Re-verify All Contracts

```bash
./script/verify-arbitrum-v3-oracles.sh
```

## Deployment Output

All deployment addresses are saved to:
```
deployments/arbitrum/v3-oracles.json
```

## Oracle Contracts

The script deploys 20 oracles:

**USDE Oracles (10):**
- USDE/AAPL, USDE/AMZN, USDE/GOOGL, USDE/META, USDE/MSFT, USDE/NVDA, USDE/SPY, USDE/TSLA
- USDE/MAG7, USDE/MAG7.i26

**stETH Oracles (10):**
- stETH/AAPL, stETH/AMZN, stETH/GOOGL, stETH/META, stETH/MSFT, stETH/NVDA, stETH/SPY, stETH/TSLA
- stETH/MAG7, stETH/MAG7.i26

## Features

- ✅ Skips already deployed contracts (checks on-chain)
- ✅ Saves all addresses immediately to JSON file
- ✅ Verification runs at the END (after all deployments complete)
- ✅ Automatic verification with retries (uses --watch flag)
- ✅ Tests all oracles after deployment
- ✅ Handles "already verified" cases gracefully
- ✅ Progress tracking and summaries

## Deployment Flow

1. **Deploy all contracts** → Save addresses immediately
2. **Show deployment summary**
3. **Run verification at the END** (after all deployments, uses --watch)
4. **Test all oracles**
5. **Final summary**

## Troubleshooting

### Verification Fails

If verification fails, you can:
1. Run the verify script separately: `./script/verify-arbitrum-v3-oracles.sh`
2. Manually verify using the forge command shown in the error output
3. Check Arbiscan directly to see if the contract is already verified

### Contract Already Deployed

The script automatically skips contracts that are already deployed. If you need to redeploy:
1. Remove the address from `deployments/arbitrum/v3-oracles.json`
2. Or use `FORCE_REDEPLOY=true` to force redeployment
3. Or delete the deployment file to start fresh

### Network Issues

If you get network errors:
- Check your RPC URL is correct and accessible
- Ensure you have enough ETH for gas fees
- Try again after a few minutes (Arbiscan rate limiting)

### Verification is Slow

Verification uses the `--watch` flag and waits for completion. This is intentional to ensure all contracts are properly verified. The verification runs at the END after all deployments complete, so it won't block deployments.
