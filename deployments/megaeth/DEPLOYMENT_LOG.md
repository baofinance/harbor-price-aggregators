# MegaETH Deployment Log

## Latest Deployment

- Date (UTC): `2026-04-27`
- Network: `megaeth` (chain ID `4326`)
- Salt: `harbor_megaeth_v1`
- State file: `deployments/megaeth/v4-aggregators-harbor_megaeth_v1.json`
- Active convenience copy: `deployments/megaeth/v4-aggregators.json`

### Deployed pairs

- `USDM/ETH`
- `USDM/BTC`
- `USDE/ETH`
- `USDE/BTC`
- `stETH/USD`

## Reusable Runbook

### 1) Set vars

```bash
export NETWORK=megaeth
export ACCOUNT=deployer
export SALT=harbor_megaeth_v1
export PAIRS="USDM/ETH USDM/BTC USDE/ETH USDE/BTC stETH/USD"
export TS=$(date -u +%Y%m%d-%H%M%S)
```

### 2) Archive current state

```bash
mkdir -p deployments/megaeth/archive
cp deployments/megaeth/v4-aggregators.json "deployments/megaeth/archive/v4-aggregators.${TS}.json"
```

### 3) Deploy implementations

```bash
script/deploy-impl --network "$NETWORK" --account "$ACCOUNT" --salt "$SALT" $PAIRS
```

### 4) Deploy proxies

```bash
script/deploy-proxy --network "$NETWORK" --account "$ACCOUNT" --salt "$SALT" $PAIRS
```

### 5) Verify (MegaETH-specific scripts)

Use one of the following verification flows.

```bash
# Direct Etherscan API (recommended for MegaETH chain 4326)
script/megaeth/verify/verify-megaeth-direct-api.sh
script/megaeth/verify/verify-megaeth-proxies.sh etherscan
```

```bash
# Blockscout flow
script/megaeth/verify/verify-megaeth-v4-oracles.sh blockscout
script/megaeth/verify/verify-megaeth-proxies.sh blockscout
```

### 6) Read output values

```bash
script/read-latest-answer --network megaeth --state-file "deployments/megaeth/v4-aggregators-${SALT}.json"
```

### 7) Optional owner check

```bash
script/megaeth/verify/verify-megaeth-oracle-ownership.sh
```

## Notes

- MegaETH verify scripts default to `deployments/megaeth/v4-aggregators.json`.
- After deploying with a new salt, copy the salted file if needed:

```bash
cp "deployments/megaeth/v4-aggregators-${SALT}.json" "deployments/megaeth/v4-aggregators.json"
```
