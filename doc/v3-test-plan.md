# v3 Oracle Test Plan

Coverage metrics alone don't guarantee correctness. This plan ensures:

1. Core math is tested in isolation (unit tests)
2. Component integration is verified (integration tests)
3. Edge cases and error paths are exercised

## Current State

### Already Covered

- [x] `ChainlinkFeedLib` normalization (8→18, 18→18 decimals)
- [x] `ChainlinkFeedLib` heartbeat/staleness validation
- [x] `ChainlinkFeedLib` negative price rejection
- [x] `ChainlinkFeedLib` never-updated feed rejection
- [x] v1/v2 aggregator tests (separate from v3)

### Existing Mocks

- `MockAggregatorV3` - Chainlink feed
- `MockFxSAVE` - fxSAVE rate provider
- `MockWstETH` - wstETH rate provider

---

## Unit Tests

Test pure/view library functions in isolation with controlled inputs.

### Rate Libraries (`test/rates/`) ✅

> **Note:** Coverage reports 87.5% due to Foundry `--ir-minimum` source mapping inaccuracies.
> The `return rate` statements are actually covered by passing tests but mapped incorrectly.

#### FxSaveRateLib.t.sol ✅

- [x] `getRate` returns correct value for valid rate
- [x] `getRate` reverts when rate < DEFAULT_MIN_RATE (0.9e18)
- [x] `getRate` with custom minRate threshold
- [x] `getRaw` returns raw convertToAssets result

#### WstETHRateLib.t.sol ✅

- [x] `getRate` returns correct value within bounds
- [x] `getRate` reverts when rate < DEFAULT_MIN_RATE (1e18)
- [x] `getRate` reverts when rate > DEFAULT_MAX_RATE (2e18)
- [x] `getRate` with custom min/max bounds
- [x] `getRaw` returns raw getStETHByWstETH result

### Price Libraries (`test/prices/`) ✅

#### SingleFeedPriceLib.t.sol ✅

- [x] `computeFromValidatedFeedPrice` divisor=1, invert=false (passthrough)
- [x] `computeFromValidatedFeedPrice` divisor>1, invert=false (division)
- [x] `computeFromValidatedFeedPrice` divisor=1, invert=true (1e36/price)
- [x] `computeFromValidatedFeedPrice` divisor>1, invert=true
- [x] Edge: very large feedPrice (near uint256 max / 1e18)
- [x] Edge: very small feedPrice (1 wei normalized)
- [x] Edge: divisor equals feedPrice (inverted should yield 1e18)

#### DoubleFeedPriceLib.t.sol ✅

- [x] Direct calculation (invert=false): firstFeed/secondFeed
- [x] Inverted calculation (invert=true): secondFeed/firstFeed
- [x] Divisor > 1 applied correctly
- [x] Different decimal combinations (8/8, 8/18, 18/8)
- [x] Edge: firstFeed = secondFeed (result ≈ 1 \* divisor)
- [x] Edge: very large price ratio
- [x] Edge: very small price ratio

---

## Integration Tests

Test aggregator contracts with mocked dependencies through public interface.

### v3 Aggregator Tests (`test/price/Aggregator_v3.t.sol`) ✅

#### Constructor Validation ✅

- [x] Reverts on zero fxsave/wsteth address
- [x] Reverts on zero feed address(es)
- [x] Reverts on zero divisor
- [x] Accepts valid constructor arguments

#### Immutable Configuration ✅

- [x] `FXSAVE` / `WSTETH` set correctly
- [x] `PRICE_FEED` / `FIRST_FEED` / `SECOND_FEED` set correctly
- [x] `PRICE_FEED_DECIMALS` matches feed.decimals()
- [x] `PRICE_FEED_HEARTBEAT` set correctly
- [x] `PRICE_DIVISOR` set correctly
- [x] `INVERT_PRICE` set correctly

#### Interface Compliance ✅

- [x] `baseName()` returns expected value
- [x] `quoteName()` returns expected value
- [x] `oracleName()` returns "baseName/quoteName"
- [x] `version()` returns 3
- [x] `rateProvider()` returns correct address

#### latestAnswer() Single Feed Pattern (Aggregator*fxUSD*\*) ✅

- [x] Returns correct 4-tuple (price, price, rate, rate)
- [x] Price calculation matches SingleFeedPriceLib formula
- [x] Rate from FxSaveRateLib applied correctly
- [x] Stale feed data propagates revert from ChainlinkFeedLib
- [x] Invalid rate propagates revert from FxSaveRateLib

#### latestAnswer() Double Feed Pattern (Aggregator*stETH*\*) ✅

- [x] Returns correct 4-tuple (price, price, rate, rate)
- [x] Price calculation matches DoubleFeedPriceLib formula
- [x] Rate from WstETHRateLib applied correctly
- [x] Stale first feed propagates revert
- [x] Stale second feed propagates revert
- [x] Invalid rate propagates revert from WstETHRateLib

#### UUPS Upgrade (HarborAggregator_v3 base)

- [ ] Owner can upgrade implementation
- [ ] Non-owner cannot upgrade
- [ ] `_disableInitializers()` prevents implementation initialization

---

## Test File Mapping

| Test File                                       | Tests For                                |
| ----------------------------------------------- | ---------------------------------------- |
| `test/rates/FxSaveRateLib.t.sol`                | FxSaveRateLib unit tests                 |
| `test/rates/WstETHRateLib.t.sol`                | WstETHRateLib unit tests                 |
| `test/prices/SingleFeedPriceLib.t.sol`          | SingleFeedPriceLib unit tests            |
| `test/prices/DoubleFeedPriceLib.t.sol`          | DoubleFeedPriceLib unit tests            |
| `test/price/Aggregator_v3.t.sol`                | v3 aggregator integration tests          |
| `test/oracles/SingleFeedAggregatorTestBase.sol` | Abstract base for fxUSD aggregator tests |
| `test/oracles/DoubleFeedAggregatorTestBase.sol` | Abstract base for stETH aggregator tests |
| `test/oracles/Aggregator_fxUSD_*.t.sol`         | Concrete tests for 5 fxUSD oracles       |
| `test/oracles/Aggregator_stETH_*.t.sol`         | Concrete tests for 4 stETH oracles       |

---

## Test Architecture

The oracle tests use an abstract base pattern to minimize boilerplate:

- **SingleFeedAggregatorTestBase** - 11 tests for fxUSD pattern (single Chainlink feed + FxSaveRateLib)
- **DoubleFeedAggregatorTestBase** - 14 tests for stETH pattern (two Chainlink feeds + WstETHRateLib)

Each concrete test file (~40 lines) just implements:

- `_contractName()` → `return type(Aggregator_XXX_YYY).name;`
- `_createAggregator(...)` → factory call
- `_createWithZeroX()` → revert test helpers

The base contracts parse `type(Contract).name` to derive expected `baseName`/`quoteName` automatically.

---

## Execution Order

1. Rate library unit tests (simplest, no external dependencies)
2. Price library unit tests (depends on understanding of ChainlinkFeedLib)
3. Aggregator integration tests (combines all components)

---

## Validation

After each section:

```bash
yarn test                    # All tests pass
yarn coverage               # Coverage increased for target files
```

Final validation:

```bash
yarn CI                     # Full CI passes
```
