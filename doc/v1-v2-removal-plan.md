# V1/V2 Code Removal Plan

This document outlines all v1 and v2 code that should be removed, leaving only v3 code.

## Overview

The v3 architecture replaces v1/v2 with:

- Immutable constructor-based configuration (no storage slots)
- Separate library files for rates, prices, and feed handling
- Per-oracle concrete contracts with explicit parameters

## Files to Delete

### Source Files (`src/`)

| File                                                 | Reason                                                                                  |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `src/price/HarborCustomFeedAndRateAggregator_v1.sol` | v1 implementation                                                                       |
| `src/price/HarborCustomFeedAndRateAggregator_v2.sol` | v2 implementation                                                                       |
| `src/price/HarborDoubleFeedAndRateAggregator_v1.sol` | v1 implementation                                                                       |
| `src/price/HarborDoubleFeedAndRateAggregator_v2.sol` | v2 implementation                                                                       |
| `src/price/HarborSingleFeedAndRateAggregator_v1.sol` | v1 implementation                                                                       |
| `src/price/HarborSingleFeedAndRateAggregator_v2.sol` | v2 implementation                                                                       |
| `src/price/PriceOracle_v1.sol`                       | v1 library used by v2                                                                   |
| `src/price/MainnetOracleAddresses.sol`               | Old address constants (v3 uses `src/feeds/chainlink/mainnet/` and `src/rates/mainnet/`) |

### Interface Files (`src/interfaces/`)

**Delete:**

| File                                                    | Reason          |
| ------------------------------------------------------- | --------------- |
| `src/interfaces/IHarborCustomFeedAndRateAggregator.sol` | v1/v2 interface |
| `src/interfaces/IHarborDoubleFeedAndRateAggregator.sol` | v1/v2 interface |
| `src/interfaces/IHarborSingleFeedAndRateAggregator.sol` | v1/v2 interface |
| `src/interfaces/IPriceOracle.sol`                       | v1 interface    |

**Keep:** (used by v3)

| File                           | Reason                           |
| ------------------------------ | -------------------------------- |
| `IHarborPriceAggregatorV3.sol` | v3 interface                     |
| `IFxSAVE.sol`                  | Used by v3 rate libraries        |
| `IWrappedPriceOracle.sol`      | Used by v3 mainnet wrappers      |
| `IPriceOracleErrors.sol`       | Inherited by IWrappedPriceOracle |

### Test Files (`test/`)

| File                                                    | Reason                                  |
| ------------------------------------------------------- | --------------------------------------- |
| `test/price/HarborCustomFeedAndRateAggregator_v1.t.sol` | v1 tests                                |
| `test/price/HarborCustomFeedAndRateAggregator_v2.t.sol` | v2 tests                                |
| `test/price/HarborDoubleFeedAndRateAggregator_v1.t.sol` | v1 tests                                |
| `test/price/HarborDoubleFeedAndRateAggregator_v2.t.sol` | v2 tests                                |
| `test/price/HarborSingleFeedAndRateAggregator_v1.t.sol` | v1 tests                                |
| `test/price/HarborSingleFeedAndRateAggregator_v2.t.sol` | v2 tests                                |
| `test/price/bases/SingleFeedAggregatorTestBase.sol`     | Old test base (v3 uses `test/oracles/`) |

**Keep and Adapt:**

- `test/price/Aggregator_v3.t.sol` - v3 integration tests
- `test/price/OracleComparisonBase.sol` - Comparison engine (adapt for v3)
- `test/price/AllOracleComparisons.t.sol` - Comparison tests (adapt for v3)

The comparison framework has useful infrastructure for forked mainnet testing and will be
adapted to compare v3 oracles against external data sources rather than deleted.

### Script Files (`script/`)

**Delete:**

| File                                          | Reason               |
| --------------------------------------------- | -------------------- |
| `script/historical/OracleDeployDumpV2.t.sol`  | v2 deployment dump   |
| `script/deploy-harbor-oracles-v2-mainnet-new` | v2 deployment script |

**Adapt to v3:**

| File                                                         | Adaptation                                                              |
| ------------------------------------------------------------ | ----------------------------------------------------------------------- |
| `script/deployment/PriceAggregatorsDeploymentJsonScript.sol` | Replace v2 imports with v3, simplify `_deployPriceOracle()` (see below) |
| `script/Deploy.s.sol`                                        | Works once base is adapted (no changes needed)                          |
| `script/historical/ChainlinkStalenessAnalysis.t.sol`         | Replace `MainnetOracleAddresses` with v3 feed libraries                 |

**Keep as-is:**

- `script/historical/FxUsdEthV3Daily3YearDump.t.sol` - v3 related
- `script/historical/LatestAnswerErrorClassifier.sol` - No v2 dependencies

#### PriceAggregatorsDeploymentJsonScript Adaptation

The v3 aggregators have all config baked into concrete contracts, so deployment becomes trivial:

**Before (v2):** ~150 lines reading JSON config, mapping rate sources, building initData
**After (v3):** ~30 line switch statement

```solidity
// Replace v2 imports:
// import {HarborSingleFeedAndRateAggregator_v2} from "@harbor-price/price/...";
// import {HarborDoubleFeedAndRateAggregator_v2} from "@harbor-price/price/...";

// With v3 imports:
import { Aggregator_fxUSD_ETH } from "@harbor-price/oracles/Aggregator_fxUSD_ETH.sol";
import { Aggregator_fxUSD_BTC } from "@harbor-price/oracles/Aggregator_fxUSD_BTC.sol";
// ... all 9 aggregators

function _deployPriceOracle(string memory contractKey) internal {
  address impl;
  string memory implName;
  bytes memory creationCode;

  if (contractKey.eq(FXUSD_ETH_FEED)) {
    impl = address(new Aggregator_fxUSD_ETH());
    implName = type(Aggregator_fxUSD_ETH).name;
    creationCode = type(Aggregator_fxUSD_ETH).creationCode;
  } else if (contractKey.eq(FXUSD_BTC_FEED)) {
    // ... etc for all 9
  }

  // v3 has no initialize() - empty initData
  deployProxy(contractKey, "priceoracle", impl, "", implName, creationCode, deployer);
}
```

Most config keys in the constructor become unused (can be removed or kept as documentation).

#### ChainlinkStalenessAnalysis Adaptation

Simple import replacement:

```solidity
// Before:
import { MainnetOracleAddresses } from "@harbor-price/price/MainnetOracleAddresses.sol";
// ... MainnetOracleAddresses.ETH_USD_FEED

// After:
import { ETH_USD } from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import { BTC_USD } from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
// ... ETH_USD.FEED, BTC_USD.FEED
```

### Mock Files (`test/mock/`)

| File                           | Action                            |
| ------------------------------ | --------------------------------- |
| `test/mock/MockAggregator.sol` | Check if only used by v1/v2 tests |

**Keep:** `MockAggregatorV3.sol`, `MockFxSAVE.sol`, `MockWstETH.sol` (used by v3)

## Directories to Review

| Directory           | Action                                         |
| ------------------- | ---------------------------------------------- |
| `src/price/`        | Delete entire directory after removing files   |
| `test/price/bases/` | Delete directory (only contains old test base) |

## Execution Steps

### Phase 1: Verify No External Dependencies

- [x] Run `forge build` to establish baseline
- [x] Search for imports of v1/v2 files from v3 code:
  ```bash
  grep -r "PriceOracle_v1\|HarborCustomFeed\|HarborDoubleFeed\|HarborSingleFeed" src/oracles/ src/HarborAggregator_v3.sol
  ```

### Phase 2: Delete Test Files

- [x] `test/price/HarborCustomFeedAndRateAggregator_v1.t.sol`
- [x] `test/price/HarborCustomFeedAndRateAggregator_v2.t.sol`
- [x] `test/price/HarborDoubleFeedAndRateAggregator_v1.t.sol`
- [x] `test/price/HarborDoubleFeedAndRateAggregator_v2.t.sol`
- [x] `test/price/HarborSingleFeedAndRateAggregator_v1.t.sol`
- [x] `test/price/HarborSingleFeedAndRateAggregator_v2.t.sol`
- [x] `test/price/bases/` directory
- Keep: `OracleComparisonBase.sol`, `AllOracleComparisons.t.sol` (adapt in Phase 7)

### Phase 3: Delete Source Files

- [x] `src/price/HarborCustomFeedAndRateAggregator_v1.sol`
- [x] `src/price/HarborCustomFeedAndRateAggregator_v2.sol`
- [x] `src/price/HarborDoubleFeedAndRateAggregator_v1.sol`
- [x] `src/price/HarborDoubleFeedAndRateAggregator_v2.sol`
- [x] `src/price/HarborSingleFeedAndRateAggregator_v1.sol`
- [x] `src/price/HarborSingleFeedAndRateAggregator_v2.sol`
- [x] `src/price/PriceOracle_v1.sol`
- [x] `src/price/MainnetOracleAddresses.sol`
- [x] `src/price/` directory

### Phase 4: Delete Interfaces

- [x] `src/interfaces/IHarborCustomFeedAndRateAggregator.sol`
- [x] `src/interfaces/IHarborDoubleFeedAndRateAggregator.sol`
- [x] `src/interfaces/IHarborSingleFeedAndRateAggregator.sol`
- [x] `src/interfaces/IPriceOracle.sol`
- Keep: `IPriceOracleErrors.sol`, `IWrappedPriceOracle.sol` (used by v3)

### Phase 5: Delete Scripts

- [x] `script/historical/OracleDeployDumpV2.t.sol` → converted to `OracleDeployDumpV3.t.sol`
- [x] `script/deploy-harbor-oracles-v2-mainnet-new`

### Phase 6: Adapt Scripts to v3

- [x] `script/deployment/PriceAggregatorsDeploymentJsonScript.sol`:
  - [x] Replace v2 imports with 9 v3 mainnet aggregator imports
  - [x] Simplify `_deployPriceOracle()` to switch on contractKey
  - [x] Remove unused config key registrations

- [x] `script/historical/ChainlinkStalenessAnalysis.t.sol`:
  - [x] Replace `MainnetOracleAddresses` import with v3 feed libraries
  - [x] Change `MainnetOracleAddresses.ETH_USD_FEED` → `ETH_USD.FEED`
  - [x] Change `MainnetOracleAddresses.BTC_USD_FEED` → `BTC_USD.FEED`

### Phase 7: Adapt Test Files

- [x] `test/price/OracleComparisonBase.sol`:
  - [x] Replace v2 imports with v3 feed libraries
  - [x] Remove v2 deployment helpers
  - [x] Keep comparison engine intact

- [x] `test/price/AllOracleComparisons.t.sol`:
  - [x] Update to compare v3 oracles only

### Phase 8: Review and Update

- [x] Check `test/mock/MockAggregator.sol` usage - deleted (unused)
- [x] Update documentation in `doc/` to remove v1/v2 references

### Phase 9: Verify

- [x] `forge build`
- [x] `forge test`

### Phase 10: Clean Up Documentation

- [x] `README.md` - no changes needed (only API URLs contain v2)
- [x] `DEPLOYMENT_CONFIG_OVERVIEW.md` - deleted (v2-only doc)
- [ ] `V3_MAINNET_ORACLES_WORKPLAN.md` - keep (has incomplete work items)
- [x] `doc/v3-reorganization-plan.md` - keep (documents current v3 architecture)

## Summary

| Category          | Delete                | Adapt              | Keep                  |
| ----------------- | --------------------- | ------------------ | --------------------- |
| `src/price/`      | 8 files (all)         | -                  | 0 (delete directory)  |
| `src/interfaces/` | 4 files               | -                  | 4 files               |
| `test/price/`     | 6 v1/v2 tests + bases | 2 comparison files | `Aggregator_v3.t.sol` |
| `script/`         | 2 files               | 3 files            | rest                  |
| **Total**         | ~20 files             | ~5 files           | -                     |

## Risk Assessment

- **Low risk**: All v3 contracts use new libraries in `src/feeds/`, `src/prices/`, `src/rates/`
- **Verify**: No v3 code imports from `src/price/` or old interfaces
- **Deployment state files**: Keep `deployment-state-v3-*.json`, can delete any v1/v2 state files if they exist

## Build Configuration Cleanup

After removing v1/v2 code, the `--ir-minimum` flag in coverage can be removed:

- **File**: `package.json`
- **Current**: `"coverage": "forge coverage --ir-minimum ..."`
- **Change to**: `"coverage": "forge coverage ..."`

The `--ir-minimum` flag was needed due to stack-too-deep issues in the v1/v2 code. With only v3 code remaining, standard compilation should work.
