# Deployment Scripts Guide

Scripts for deploying and verifying Harbor v3 aggregator implementations and proxies using CREATE3 deterministic deployment.

## Overview

Harbor v3 uses an upgradeable proxy pattern via BaoFactory. Each aggregator has two components:

- **Implementation**: The contract logic (deployed first)
- **Proxy**: ERC1967 proxy that points to the implementation (deployed second)

The scripts manage both lifecycle stages and maintain state in JSON files.

## State File

All deployments are tracked in network-specific state files:

```
deployments/<network>/v3-aggregators.json
```

Local test deployments use:

```
deployments/local/<network>/v3-aggregators.json
```

### State File Structure

```json
{
  "schemaVersion": 1,
  "version": "v3",
  "network": "mainnet",
  "chainId": 1,
  "baoFactory": "0xD696E56b3A054734d4C6DCBD32E11a278b0EC458",
  "implementations": {
    "<address>": {
      "pair": "fxUSD/ETH",
      "contractSource": "src/mainnet/Aggregator_fxUSD_ETH_mainnet.sol",
      "contractType": "Aggregator_fxUSD_ETH_mainnet",
      "deploymentTime": "2025-12-31T09:42:41Z"
    }
  },
  "proxies": {
    "fxUSD/ETH": {
      "address": "0xea5292c58288DcE24C52C1dB13ca048275665EbC",
      "implementation": "0x78D74eA76Fbfd476A06c1678dC89c025595c8536",
      "salt": "harbor_v1::fxUSD::ETH::wrappedPriceAggregator",
      "deploymentTime": "2026-01-03T13:03:38Z"
    }
  }
}
```

**Key points:**

- `implementations`: Keyed by address, tracks deployed contract logic
- `proxies`: Keyed by pair name, tracks proxy addresses and which implementation they point to
- `salt`: CREATE3 salt used for deterministic proxy address generation
- All timestamps are ISO 8601 UTC format

## Scripts

### deploy-impl

Deploys implementation contract(s) and records them in the state file.

**Basic usage:**

```bash
script/deploy-impl --network mainnet --account deployer fxUSD/ETH
```

**Deploy multiple implementations:**

```bash
script/deploy-impl --network arbitrum --account deployer USDE/ETH USDE/BTC
```

**Local testing (anvil):**

```bash
script/deploy-impl --network mainnet --local fxUSD/ETH
```

**Local testing with network state copy:**

```bash
script/deploy-impl --network mainnet --local --copy-network fxUSD/ETH
```

**Custom salt prefix:**

```bash
script/deploy-impl --network mainnet --account deployer --salt harbor_v2 fxUSD/ETH
```

**Options:**

- `--network <name>`: Required. Network name (mainnet, arbitrum, base)
- `--account <name>`: Required for non-local. Foundry keystore account name
- `--local`: Use local anvil RPC with test key (no password prompt)
- `--copy-network`: With `--local`, copy network state to local before deploying
- `--salt <prefix>`: Salt prefix (default: `harbor_v1`)

**What it does:**

1. Deploys implementation via `forge create`
2. Records deployment in state file under `implementations`
3. If proxy already exists, outputs Safe transaction data for `upgradeToAndCall`

### deploy-proxy

Deploys proxy contract(s) via BaoFactory CREATE3 and records them in the state file.

**Basic usage:**

```bash
script/deploy-proxy --network mainnet --account deployer fxUSD/ETH
```

**Deploy proxies for all implementations without proxies:**

```bash
script/deploy-proxy --network mainnet --account deployer --use-state-file
```

**Local testing:**

```bash
script/deploy-proxy --network mainnet --local --use-state-file
```

**Options:**

- `--network <name>`: Required. Network name
- `--account <name>`: Required for non-local. Foundry keystore account name
- `--local`: Use local anvil RPC
- `--copy-network`: With `--local`, copy network state before deploying
- `--salt <prefix>`: Salt prefix for CREATE3 (default: `harbor_v1`)
- `--use-state-file`: Deploy proxies for all implementations without proxies

**What it does:**

1. Reads implementation address from state file
2. Deploys ERC1967 proxy via BaoFactory.deploy()
3. Records proxy in state file under `proxies`

**Important:** Implementation must be deployed first. Use `deploy-impl` before `deploy-proxy`.

### verify-impl

Verifies implementation contract(s) on Etherscan.

**Verify all implementations:**

```bash
script/verify-impl --network mainnet --use-state-file
```

**Verify specific pairs:**

```bash
script/verify-impl --network mainnet fxUSD/ETH
script/verify-impl --network arbitrum USDE/ETH USDE/BTC
```

**Dry run (print commands without executing):**

```bash
script/verify-impl --network mainnet --use-state-file --local
```

**Options:**

- `--network <name>`: Required. Network name
- `--use-state-file`: Verify all implementations in state file
- `--salt <prefix>`: Salt prefix (default: `harbor_v1`)
- `--local`: Dry run mode (uses local state file, prints commands only)

**What it does:**

1. Reads implementation(s) from state file
2. Verifies each on Etherscan via `forge verify-contract`

**Requirements:**

- `ETHERSCAN_API_KEY` environment variable must be set
- Implementations must exist in state file

### verify-proxy

Verifies proxy contract(s) on Etherscan.

**Verify all proxies:**

```bash
script/verify-proxy --network mainnet --use-state-file
```

**Verify specific pairs:**

```bash
script/verify-proxy --network mainnet fxUSD/ETH
script/verify-proxy --network arbitrum USDE/ETH USDE/BTC
```

**Dry run:**

```bash
script/verify-proxy --network mainnet --use-state-file --local
```

**Options:**

Same as `verify-impl`.

**What it does:**

1. Reads proxy(s) from state file
2. Verifies proxy contract (ERC1967Proxy) on Etherscan

### check-blockchain

Validates on-chain deployment state for all aggregators.

**Basic usage:**

```bash
script/check-blockchain --network mainnet
```

**Local testing:**

```bash
script/check-blockchain --network mainnet --local
```

**Local testing with network state copy:**

```bash
script/check-blockchain --network mainnet --local --copy-network
```

**Options:**

- `--network <name>`: Required. Network name (mainnet, arbitrum, base)
- `--local`: Use local RPC (http://localhost:8545)
- `--copy-network`: Copy production state to local before checking (requires `--local`)
- `--salt <prefix>`: Salt prefix (default: `harbor_v1`)

**What it does:**

1. Reads state file for network
2. For each proxy:
   - Confirms proxy contract has code deployed
   - Confirms proxy points to expected implementation address
   - Runs oracle introspection calls:
     - `oracleName()`, `baseName()`, `quoteName()`
     - `owner()`, `version()`, `rateProvider()`
     - `latestAnswer()` (validates non-zero price)
3. Generates pass/fail summary with counts

**Output example:**

```
══════════════════════════════════════════════════════════════
✓ Proxy fxUSD/ETH (0xea5292c58288DcE24C52C1dB13ca048275665EbC)
  Implementation on-chain: 0x78D74eA76Fbfd476A06c1678dC89c025595c8536 ✓
  oracleName: fxUSD/ETH
  baseName: fxUSD
  quoteName: ETH
  owner: 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2
  version: 1
  rateProvider: 0x98dF8E8D5B3Baf27aef3d826Ad09a84f8cD72B56
  latestAnswer:
    - price: 2,734.123456 (min == max)  [ETH/fxUSD = 0.000365]
    - rate:  1.057000 (min == max)
══════════════════════════════════════════════════════════════

Summary: 15/15 proxies passed ✓
```

**Use cases:**

- Validate deployments after running deploy scripts
- Smoke test that oracles are functional
- Confirm proxy→implementation linkage matches state file
- Troubleshoot oracle failures (shows which call failed)

### check-verify

Generates Etherscan verification report for all aggregators.

**Basic usage:**

```bash
script/check-verify --network mainnet
```

**Custom output file:**

```bash
script/check-verify --network mainnet --output deployments/mainnet/verification-report.md
```

**Local testing:**

```bash
script/check-verify --network mainnet --local
```

**Options:**

- `--network <name>`: Required. Network name (mainnet, arbitrum, base)
- `--local`: Use local RPC (skips Etherscan queries)
- `--copy-network`: Copy production state to local before checking (requires `--local`)
- `--salt <prefix>`: Salt prefix (default: `harbor_v1`)
- `--output <path>`: Markdown output path (default: `deployments/<network>/v3-aggregators.md`)

**What it does:**

1. Reads state file for network
2. For each proxy and implementation:
   - Queries Etherscan API for verification status
   - Checks proxy source verification
   - Checks implementation linking in proxy
   - Checks proxy flag
   - Checks implementation source verification
3. Writes markdown table with verification status and links

**Output format (markdown table):**

| Pair | Proxy | Source | Impl | Proxy Flag | Implementation | Impl Verified |
|------|-------|--------|------|------------|----------------|---------------|
| fxUSD/ETH | [0xea52...](link) | ✅ | ✅ | ✅ | [0x78D7...](link) | ✅ |
| fxUSD/BTC | [0xF765...](link) | ✅ | ✅ | ✅ | [0x9f62...](link) | ✅ |

**Verification columns:**

- **Source**: Proxy source code verified on Etherscan
- **Impl**: Proxy has implementation address linked
- **Proxy Flag**: Etherscan recognizes contract as a proxy
- **Impl Verified**: Implementation source code verified

**Use cases:**

- Generate verification status reports
- Identify unverified contracts after deployment
- Create documentation for deployments
- Audit verification completeness

**Requirements:**

- `ETHERSCAN_API_KEY` must be set (unless using `--local`)

## Common Workflows

### Deploy New Aggregator

Complete workflow for a new aggregator:

```bash
# 1. Deploy implementation
script/deploy-impl --network mainnet --account deployer fxUSD/ETH

# 2. Deploy proxy
script/deploy-proxy --network mainnet --account deployer fxUSD/ETH

# 3. Verify implementation
script/verify-impl --network mainnet fxUSD/ETH

# 4. Verify proxy
script/verify-proxy --network mainnet fxUSD/ETH

# 5. Validate on-chain deployment
script/check-blockchain --network mainnet

# 6. Generate verification report
script/check-verify --network mainnet
```

### Upgrade Existing Aggregator

To upgrade an aggregator to a new implementation:

```bash
# 1. Deploy new implementation
script/deploy-impl --network mainnet --account deployer fxUSD/ETH

# The script will output Safe transaction data for upgradeToAndCall
# 2. Use that data to submit a Safe transaction for the upgrade
```

### Deploy All Pending Proxies

If you have implementations without proxies:

```bash
script/deploy-proxy --network mainnet --account deployer --use-state-file
```

### Local Testing

Test deployment flow locally with anvil:

```bash
# 1. Start anvil in another terminal
anvil

# 2. Deploy with --local flag
script/deploy-impl --network mainnet --local --copy-network fxUSD/ETH
script/deploy-proxy --network mainnet --local fxUSD/ETH

# 3. Dry-run verification
script/verify-impl --network mainnet --local fxUSD/ETH
script/verify-proxy --network mainnet --local fxUSD/ETH

# 4. Validate on-chain state
script/check-blockchain --network mainnet --local

# 5. Check verification status (skips Etherscan queries)
script/check-verify --network mainnet --local
```

### Audit Existing Deployments

Check status of all deployed aggregators:

```bash
# Validate all proxies are functional
script/check-blockchain --network mainnet

# Generate verification status report
script/check-verify --network mainnet
```

## Environment Setup

### Required Environment Variables

For mainnet/testnet deployments:

```bash
export MAINNET_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY"
export ARBITRUM_RPC_URL="https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY"
export BASE_RPC_URL="https://base-mainnet.g.alchemy.com/v2/YOUR_KEY"
export ETHERSCAN_API_KEY="your_etherscan_api_key"
```

### Foundry Keystore

Scripts use Foundry's encrypted keystore for accounts:

```bash
# Create a new account
cast wallet import deployer --interactive

# Use it in scripts
script/deploy-impl --network mainnet --account deployer fxUSD/ETH
```

### Local Testing

For `--local` mode, scripts use Anvil's default test private key:

```
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

No account setup needed for local testing.

## Salt Prefix

The salt prefix determines the CREATE3 salt and affects proxy addresses. Format:

```
<salt_prefix>::<base>::<quote>::wrappedPriceAggregator
```

Example with default `harbor_v1`:

```
harbor_v1::fxUSD::ETH::wrappedPriceAggregator
```

**Why change it?**

- Different deployment versions (`harbor_v2`, etc.)
- Testing alternative configurations
- Maintaining multiple environments

**Note:** Changing the salt prefix creates new proxy addresses. The same implementation can have multiple proxies with different salts.

## Error Handling

### "No implementation found for pair"

The implementation must be deployed before the proxy. Run `deploy-impl` first.

### "Implementation address not found in state file"

Check that you're using the correct network and salt prefix. State files are network-specific.

### "Proxy already exists"

You can't redeploy a proxy at the same address (CREATE3 will revert). To upgrade, deploy a new implementation and use the Safe transaction output.

### Verification failures

Common causes:

- Contract not yet indexed by Etherscan (wait ~1 minute)
- Wrong `ETHERSCAN_API_KEY`
- Network mismatch between deployment and verification

## State File Safety

**Production state files** (`deployments/<network>/v3-aggregators.json`) are source-controlled and contain authoritative deployment records.

**Guidelines:**

- Never manually edit production state files
- Scripts append to state files atomically
- Keep state files in version control
- Review state file changes in PRs
- Use `--local` for testing to avoid polluting production state

## See Also

- [v3 Aggregator Authoring Guide](../doc/v3-aggregator-authoring-guide.md) - How to create new aggregator contracts
- [Main README](../README.md) - Project overview and testing
