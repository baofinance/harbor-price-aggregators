# Mainnet deployment state

JSON files in this directory record deployed oracle addresses for mainnet.

## Deprecated: XAU / XAG

**Oracle keys and entries named XAU or XAG (e.g. `SUSDE_XAU`, `SUSDE_XAG`, `FXUSD_XAU`, `FXUSD_XAG`, `STETH_XAU`, `STETH_XAG`) are deprecated.** Use **GOLD** and **SILVER** instead (same feeds, external naming). Entries in `v3-oracles.json`, `v4-oracles.json`, or `v3-aggregators.json` that refer to XAU/XAG may be marked with `"deprecated": true`; deploy and verify scripts use GOLD/SILVER only.
