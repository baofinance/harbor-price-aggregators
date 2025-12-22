# HarborPriceAggregator_v3 Reorganization Plan

## Executive Summary

Refactor v2 oracles into a library-based architecture with:

1. **Factored libraries** for rate fetching and price calculation
2. **Flexible call formats** - libraries don't bake in bounds or signatures
3. **All configuration as immutables** - new proxies will be deployed
4. **Minimal initialize():** just owner
5. **`version()` returns 3**

Additional hard requirements:

- **Single virtual hook:** concrete oracles override `latestAnswer()` to return `(minPrice, maxPrice, minRate, maxRate)`.
- **Identity getters:** `base()` (base asset address), `rateProvider()` (address of rate provider, e.g. fxSAVE / wstETH), and `quoteName()` (e.g. "ETH", "BTC").
- **Name is derived, not stored:** `oracleName()` is derived from base/quote identity and is not owner-updatable.
- **Namespaced storage:** any mutable v3 storage must live in a namespaced storage slot; the goal is for v3 itself to have _no_ mutable state beyond inherited upgrade/ownership state.

## Analysis: Two Example Oracles

### FXUSD_ETH (Single Feed)

| Aspect       | Implementation                       |
| ------------ | ------------------------------------ |
| Base Asset   | fxUSD                                |
| Rate Source  | fxSAVE.convertToAssets(1e18)         |
| Rate Bounds  | min 0.9, no max                      |
| Quote Asset  | ETH                                  |
| Price Source | ETH/USD Chainlink feed, **inverted** |
| Feed Count   | 1                                    |

### STETH_BTC (Double Feed)

| Aspect       | Implementation                |
| ------------ | ----------------------------- |
| Base Asset   | stETH (wstETH wrapper)        |
| Rate Source  | wstETH.getStETHByWstETH(1e18) |
| Rate Bounds  | min 1.0, max 2.0              |
| Quote Asset  | BTC                           |
| Price Source | ETH/USD ÷ BTC/USD             |
| Feed Count   | 2                             |

### Key Insight

Rate logic and price logic are **independent computations**:

- Rate: fetch conversion rate from a source (fxSAVE, wstETH, Chainlink)
- Price: fetch price from Chainlink feeds (single or double)

Each is implemented as a **library** - pure computation that doesn't bake in a call format. Concrete oracles call the appropriate library functions with their immutable configuration.

## Future Variations & Extension Points

This design should survive “unknown downstream” changes by keeping **extension points in libraries** and keeping the **base contract stable**.

### Variation Axes We Expect

- **New rate sources:** ERC-4626 style vaults, LST wrappers, Chainlink rates, non-Chainlink rates (e.g. Pyth / Redstone / custom).
  Extension: add a new `*RateLib` (and optionally a policy struct) — no changes to the base contract.

- **New price graphs beyond 1-feed and 2-feed:** multi-hop conversions (A/USD → USD/B → B/C), basket/weighted indexes, or feeds that require extra normalization.
  Extension: add a new price library (e.g. `CompositePriceLib`) that takes a list of steps and computes the final 18-decimal price.

- **Different validation policies:** staleness rules, deviation rules, min/max bounds, “sentinel” feeds, pausing/kill-switches.
  Extension: keep libraries exposing **raw fetch** and **validated fetch**, so downstream can validate differently without rewriting fetch logic.

- **Non-deterministic bounds:** future oracles may want to return a conservative range rather than a single point.
  Extension: have the base contract work in **min/max bounds** internally so deterministic oracles just return `(x, x)`.

- **Rounding policy:** some downstream integrations care whether we round up or down.
  Extension: price libraries should accept a rounding mode or document a consistent rounding convention.

## Alternatives Considered

- **Abstract mixins via inheritance (rate mixins + price mixins):** rejected because it bakes the oracle call format and validation policy into inheritance, couples composition order to class hierarchy, and makes reuse in non-oracle contexts awkward.
- **Keep the v2 “single implementation + config in storage” pattern:** rejected because it centralizes configuration in mutable state, creates large if/else selection logic, and makes deterministic deployment + minimal init harder to reason about.

Chosen approach: **internal libraries for computation + per-oracle immutable wiring**, with `initialize(owner)` as the only proxy-time configuration.

## Detailed Design: Library Approach

### Abstract Base Contract

```solidity
/// @notice v3 oracle interface: IWrappedPriceOracle + identity.
/// @dev All v3 oracles must implement these functions.
interface IHarborPriceAggregatorV3 is IWrappedPriceOracle {
  function base() external view returns (address);
  function rateProvider() external view returns (address);
  function quoteName() external pure returns (string memory);
  function oracleName() external pure returns (string memory);
  function version() external pure returns (uint256);
}

abstract contract HarborPriceAggregator_v3 is
  IHarborPriceAggregatorV3,
  UUPSUpgradeable,
  ReentrancyGuardTransientUpgradeable,
  BaoOwnable
{
  // ─── STORAGE (namespaced) ─────────────────────────────────────
  // v3 is intended to have no mutable storage of its own.
  // If future variants add mutable state, it must live behind a namespaced slot.

  /// @custom:storage-location erc7201:harbor.storage.PriceAggregatorV3
  struct HarborPriceAggregatorV3Storage {
    // Intentionally empty (reserved).
  }

  /// @notice The storage hash for the shared-with-proxy storage
  // chisel eval 'keccak256(abi.encode(uint256(keccak256("harbor.storage.PriceAggregatorV3")) - 1)) & ~bytes32(uint256(0xff))'
  bytes32 private constant _PRICE_AGGREGATOR_V3_STORAGE =
    0x22d39e01e70b6e32f8072ab8cd3f39c930a110555d014e358a68416cde8e3200;

  /// @notice Returns a reference to the contract state
  function _getPriceAggregatorV3Storage() private pure returns (HarborPriceAggregatorV3Storage storage $) {
    assembly {
      $.slot := _PRICE_AGGREGATOR_V3_STORAGE
    }
  }

  // ─── IDENTITY (required) ─────────────────────────────────────

  /// @notice Base asset address (e.g. fxUSD token).
  function base() public view virtual returns (address);

  /// @notice Address of the rate provider used by this oracle (e.g. fxSAVE / wstETH).
  function rateProvider() public view virtual returns (address);

  /// @notice Quote name (e.g. "ETH", "BTC", "EUR").
  function quoteName() public pure virtual returns (string memory);

  /// @notice Derived name (not stored, not updatable).
  /// @dev Concrete oracles should override this as a constant string to avoid external calls.
  function oracleName() public pure virtual returns (string memory);

  function version() external pure virtual returns (uint256) {
    return 3;
  }

  function initialize(address owner_) external initializer {
    __UUPSUpgradeable_init();
    __ReentrancyGuardTransient_init();
    _initializeOwner(owner_);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
}
```

### Rate Libraries

```solidity
// ─── FxSave Rate Library ─────────────────────────────────────────

library FxSaveRateLib {
  error InvalidRate(uint256 rate);

  uint256 constant DEFAULT_MIN_RATE = 9e17; // 0.9

  /// @notice Raw fetch (no validation).
  /// @dev Accepts an amount to support future callers that want non-1e18 sizing.
  function getRaw(IFxSAVE fxsave, uint256 shares) internal view returns (uint256) {
    return fxsave.convertToAssets(shares);
  }

  /// @notice Validated fetch with default policy.
  function getRate(IFxSAVE fxsave) internal view returns (uint256) {
    return getRate(fxsave, DEFAULT_MIN_RATE);
  }

  /// @notice Validated fetch with custom minimum bound.
  function getRate(IFxSAVE fxsave, uint256 minRate) internal view returns (uint256) {
    uint256 rate = getRaw(fxsave, 1e18);
    if (rate < minRate) revert InvalidRate(rate);
    return rate;
  }
}

// ─── WstETH Rate Library ─────────────────────────────────────────

library WstETHRateLib {
  error InvalidRate(uint256 rate);

  uint256 constant DEFAULT_MIN_RATE = 1e18; // 1.0
  uint256 constant DEFAULT_MAX_RATE = 2e18; // 2.0

  /// @notice Raw fetch (no validation).
  function getRaw(IWstETH wsteth, uint256 wstethAmount) internal view returns (uint256) {
    return wsteth.getStETHByWstETH(wstethAmount);
  }

  /// @notice Validated fetch with default bounds.
  function getRate(IWstETH wsteth) internal view returns (uint256) {
    return getRate(wsteth, DEFAULT_MIN_RATE, DEFAULT_MAX_RATE);
  }

  /// @notice Validated fetch with custom bounds.
  function getRate(IWstETH wsteth, uint256 minRate, uint256 maxRate) internal view returns (uint256) {
    uint256 rate = getRaw(wsteth, 1e18);
    if (rate < minRate || rate > maxRate) revert InvalidRate(rate);
    return rate;
  }
}

Notes:

- All library functions are `internal` to avoid external library linking.
- The library API should expose both **raw** and **validated** reads so validation policies can vary without duplicating read logic.
```

### Price Libraries

```solidity
// ─── Single Feed Price Library ───────────────────────────────────

library SingleFeedPriceLib {
  using PriceOracle_v1 for PriceOracle_v1.Feed;

  /// @notice Validated fetch + computation.
  /// @dev For future flexibility, keep this as a thin wrapper around fetch+compute.
  function getPrice(
    AggregatorV3Interface feed,
    uint8 feedDecimals,
    PriceOracle_v1.Constraints memory constraints,
    uint256 divisor,
    bool invert
  ) internal view returns (uint256) {
    PriceOracle_v1.Feed memory feedData = PriceOracle_v1.Feed({ priceFeed: feed, decimals: feedDecimals });
    uint256 feedPrice = feedData.latestAnswer(constraints);
    return computeFromValidatedFeedPrice(feedPrice, divisor, invert);
  }

  /// @notice Pure computation step (no feed reads).
  /// @dev Useful if future callers want different feed validation but the same math.
  function computeFromValidatedFeedPrice(
    uint256 feedPrice,
    uint256 divisor,
    bool invert
  ) internal pure returns (uint256) {
    if (invert) {
      return Math.mulDiv(1e18 * divisor, 1e18, feedPrice);
    }
    return feedPrice / divisor;
  }
}

// ─── Double Feed Price Library ───────────────────────────────────

library DoubleFeedPriceLib {
  using PriceOracle_v1 for PriceOracle_v1.Feed;

  function getPrice(
    AggregatorV3Interface firstFeed,
    uint8 firstDecimals,
    PriceOracle_v1.Constraints memory firstConstraints,
    AggregatorV3Interface secondFeed,
    uint8 secondDecimals,
    PriceOracle_v1.Constraints memory secondConstraints,
    uint256 divisor,
    bool invert
  ) internal view returns (uint256) {
    // ... same logic as v2 _getPrice() for double feed
    // Caller chooses constraints/divisor/invert to avoid a fixed “one-size-fits-all” config.
  }
}

/// @notice Future extension point for N-hop conversions.
/// @dev Not required for FxUSD/STETH today; added as a planned direction.
library CompositePriceLib {
  // struct Step { AggregatorV3Interface feed; uint8 decimals; PriceOracle_v1.Constraints constraints; Op op; }
  // enum Op { MUL, DIV }
  // function getPrice(Step[] memory steps, uint256 divisor, bool invert, ...) internal view returns (uint256);
}
```

### Concrete Oracle: FXUSD_ETH

Implemented using “Approach B” (formula + chain wiring):

- `Oracle_fxUSD_ETH`: formula contract with constructor args (rate provider, feed, divisor/invert, constraints)
- `Oracle_fxUSD_ETH_Mainnet`: 0-arg mainnet wiring contract that passes canonical Ethereum mainnet addresses/constants via `src/price/MainnetOracleAddresses.sol`

This keeps the core oracle logic portable (constructor args) while keeping deployments trivial on a given chain (a wrapper with no constructor args).

This is intentionally _not_ a promise that “other chains are address-only changes”. Supporting another chain should mean a new wrapper and potentially a different formula if the feed graph differs.

### Concrete Oracle: STETH_BTC

Implemented using the same “Approach B” split:

- `Oracle_stETH_BTC`: formula contract with constructor args (stETH + wstETH rate source, ETH/USD + BTC/USD feeds, divisor/invert, constraints)
- `Oracle_stETH_BTC_Mainnet`: 0-arg mainnet wiring contract that passes canonical Ethereum mainnet addresses/constants via `src/price/MainnetOracleAddresses.sol`

## Comparison Matrix

| Oracle    | Base Asset | Rate Library  | Quote Asset | Price Library      | Feeds |
| --------- | ---------- | ------------- | ----------- | ------------------ | ----- |
| FxUSD_ETH | fxUSD      | FxSaveRateLib | ETH         | SingleFeedPriceLib | 1     |
| FxUSD_BTC | fxUSD      | FxSaveRateLib | BTC         | SingleFeedPriceLib | 1     |
| FxUSD_EUR | fxUSD      | FxSaveRateLib | EUR         | SingleFeedPriceLib | 1     |
| StETH_BTC | stETH      | WstETHRateLib | BTC         | DoubleFeedPriceLib | 2     |
| StETH_EUR | stETH      | WstETHRateLib | EUR         | DoubleFeedPriceLib | 2     |

## File Structure

```
src/price/
├── PriceOracle_v1.sol                    # Existing - Chainlink validation
├── HarborPriceAggregator_v3.sol          # NEW - Abstract base
├── rates/                                 # NEW - Rate source libraries
│   ├── FxSaveRateLib.sol
│   ├── WstETHRateLib.sol
│   └── ChainlinkRateLib.sol               # For Chainlink-based rates
├── prices/                                # NEW - Price computation libraries
│   ├── SingleFeedPriceLib.sol
│   ├── DoubleFeedPriceLib.sol
│   └── CompositePriceLib.sol              # Optional future N-hop conversions
├── oracles/                               # NEW - Concrete implementations
│   ├── Oracle_fxUSD_ETH.sol
│   ├── Oracle_fxUSD_ETH_Mainnet.sol
│   ├── Oracle_stETH_BTC.sol
│   ├── Oracle_stETH_BTC_Mainnet.sol
│   └── ...
├── HarborSingleFeedAndRateAggregator_v2.sol   # Existing - keep
└── HarborDoubleFeedAndRateAggregator_v2.sol   # Existing - keep
```

## v2 vs v3 Comparison

| Aspect                | v2                           | v3                   |
| --------------------- | ---------------------------- | -------------------- |
| Rate source addresses | All 4 in every oracle        | Only the 1 needed    |
| Rate/Price selection  | if/else enum chains          | Library calls        |
| Adding new rate type  | Modify base contract         | Add new library      |
| Adding new price type | New contract (single/double) | Add new library      |
| Storage layout        | Complex mappings             | Only oracleName      |
| Governance            | setConstraints(), etc.       | Immutable - redeploy |
| version()             | Returns 2                    | Returns 3            |
| Proxy compatibility   | N/A                          | Deploy new proxies   |

## Implementation Order

1. **Create libraries first:**
   - FxSaveRateLib.sol
   - WstETHRateLib.sol
   - SingleFeedPriceLib.sol
   - DoubleFeedPriceLib.sol

2. **Create abstract base:** HarborPriceAggregator_v3.sol

3. **Create two proof-of-concept oracles in parallel:**

- Oracle_fxUSD_ETH (formula contract)
- Oracle_fxUSD_ETH_Mainnet (mainnet wiring)
- Oracle_stETH_BTC (formula contract)
- Oracle_stETH_BTC_Mainnet (mainnet wiring)

4. **Update comparison tests:** Add v3 candidate factories

5. **Validate:** Run comparison tests against deployed v2

6. **Create remaining oracles:** Other FxUSD and StETH variants

## Testing Strategy

Use the existing comparison test framework:

- Base: deployed v2 oracle
- Candidate: new v3 oracle with same configuration
- Verify identical `latestAnswer()` results across block range

## Risks

1. **Code Size:** Expected to stay small. Libraries are `internal` (inlined) and v3 reduces per-oracle storage/mappings.
2. **New Proxies Required:** Intended. v3 is a new family of implementations and should be deployed behind new proxies.

Non-goals for this phase:

- **Multiple per-pair variants under harbor_v1:** Not supported by design.
  The `harbor_v1` requirement is “one canonical v3 oracle endpoint per (base-name, quote-name)”.
  If we ever need multiple variants for the same pair (different graphs, constraints, or methodology), that is a `harbor_v2` concern and the identity mechanism must evolve.

## Deterministic Deployment (BaoFactory / CREATE3)

Deterministic proxy addresses are a hard deployment constraint.

- BaoFactory address (all supported chains): `0xD696E56b3A054734d4C6DCBD32E11a278b0EC458`
- Deploy mechanism: `IBaoFactory.deploy(bytes initCode, bytes32 salt)` (CREATE3)
- Predict mechanism: `IBaoFactory.predictAddress(bytes32 salt)`

### Salt Format (harbor_v1)

Using contracts attach to oracles using only `(base-name, quote-name)`.
Therefore the salt identity is fixed to:

`harbor_v1::Oracle_v3::<base-name>::<quote-name>`

Notes:

- No “variant” component exists in `harbor_v1`.
- The on-chain salt is `bytes32`, so the deployment script must derive it consistently (e.g. `keccak256(bytes(<salt-string>))`).
- `<base-name>` and `<quote-name>` must be canonical and stable (exact spelling/case) forever, otherwise the derived address changes.

### Proxy Model

- Each oracle has its own implementation contract (immutables baked into the bytecode).
- Each oracle endpoint is an ERC1967 proxy deployed via BaoFactory/CREATE3 at the deterministic address derived from the salt.
- Proxy init data is always `initialize(owner)` (v3 initialize is intentionally minimal).

### New Deployment Script (v3, Bash)

Add a new v3 deployment script modeled on `script/deploy-harbor-oracles-v2-mainnet-new`, but vastly simplified.
Suggested name: `script/deploy-harbor-oracles-v3-mainnet`.

Scope and simplifications versus v2:

- No “single vs double implementation” split: v3 uses per-oracle implementations.
- No per-proxy configuration calldata beyond `initialize(owner)`.
- Deterministic proxy deployment goes through BaoFactory (CREATE3), not direct `forge create` of proxies.

Suggested script behavior:

- Configuration (env / defaults): `RPC_URL`, `PRIVATE_KEY`, `OWNER`, `BAO_FACTORY` (default to the address above), `STATE_FILE` (default `deployment-state-v3.json`), `MODE` (`deploy|check|verify`).
- Deploy mode:
  - Deploy (or reuse from state) each v3 implementation (e.g. `Oracle_fxUSD_ETH_Mainnet`, `Oracle_stETH_BTC_Mainnet`, etc.).
  - For each oracle proxy:
    - Build salt string `harbor_v1::Oracle_v3::<base-name>::<quote-name>`.
    - Compute `bytes32 salt = keccak256(bytes(saltString))`.
    - Compute `predicted = IBaoFactory(BAO_FACTORY).predictAddress(salt)`.
    - If code exists at `predicted`, record it and skip deployment.
    - Else deploy an ERC1967 proxy via BaoFactory using `deploy(initCode, salt)` where `initCode` is the ERC1967Proxy creation code + constructor args `(implementation, initialize(owner) calldata)`.
  - Save state (implementations + proxies) as JSON via `jq`.
- Check mode:
  - Load state, print implementations/proxies, and check that each proxy has code and responds to `oracleName()`.
- Verify mode (optional):
  - Verify implementations on Etherscan.
  - Optionally verify proxies as `ERC1967Proxy` (constructor args are `(implementation, initData)`); deterministic deployment via BaoFactory does not change the constructor args.

## Success Criteria

- [ ] Each oracle holds only the addresses it uses
- [ ] No if/else chains on rate source or price type
- [ ] Libraries encapsulate rate and price logic
- [ ] v3 produces identical results to v2 in comparison tests
- [ ] No per-oracle mutable config in v3 (beyond inherited upgrade/ownership state)
- [ ] Initialize takes only `(owner)`
- [ ] version() returns 3
- [ ] Adding a new rate/price type only requires a new library
- [ ] Base contract stays stable as new variations are added
