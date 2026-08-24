# Chainlink Rate Source + Multi-Feed Design Notes (v3)

## Scope

This note captures the design intent discussed for:

- A **Chainlink-based rate source** library that can be used by bespoke oracle factories.
- The v3 equivalent of the legacy **Custom** aggregator, renamed conceptually to **Multi**.
- How this interacts with `PriceOracle_v1` and why the system should avoid a generic configurable wrapper.

This is intentionally high-level; it sketches API surfaces but avoids detailed implementation.

## What exists today

### `PriceOracle_v1` is already a shared primitive

`PriceOracle_v1` is used in both generations:

- v1/v2 aggregators use it to validate and normalize Chainlink feeds to 18 decimals.
- v3 price libraries (`SingleFeedPriceLib`, `DoubleFeedPriceLib`) and v3 oracles also use it.

This strongly suggests that a “Chainlink rate feed” should be modeled the same way as a “Chainlink price feed”: it is still an `AggregatorV3Interface` answer with constraints.

### Legacy rate source logic (v2 wrappers)

Legacy v2 wrappers include both:

- **contract-native rates** (e.g., `IWstETH.getStETHByWstETH(1e18)`, `IFxSAVE.convertToAssets(1e18)`), and
- **Chainlink-based rates** (e.g., `sUSDE/USDE`, `wstETH/stETH`) fetched via `latestRoundData()` and validated for:
  - positive answer,
  - non-staleness via `maxRateSourceAge`,
  - 18-decimal normalization,
  - basic domain bounds (e.g., `rate >= 0.9e18` or `0.9e18 <= rate <= 3e18`).

That Chainlink rate logic is duplicated across multiple contracts and is a good target to refactor into a library.

## Proposed building blocks

### 1) Chainlink rate feed library (generic)

**Intent:** provide a single, reusable way to treat “rate feeds” as constrained Chainlink observations.

Key points:

- Don’t create a configurable wrapper contract.
- Constraints are provided by the bespoke oracle (constructor/initializer), not governed by setters.
- Reuse `PriceOracle_v1` behavior where possible.

High-level API sketch:

- `ChainlinkRateFeedLib.getRate18(feed, feedDecimals, constraints) -> uint256`
  - returns 18-decimal rate
  - performs the same safety checks as `PriceOracle_v1` (staleness/deviation/non-negative)
  - optionally applies a domain bound check (min/max), if the caller supplies bounds

Implementation note: in practice this can be a thin wrapper over `PriceOracle_v1.Feed.latestAnswer(constraints)` because “rate” vs “price” is caller semantics.

### 2) Multi (replacement for Custom)

**Rename rationale:** the legacy “custom” aggregator is fundamentally about composing multiple feeds, not about being configurable.

Two distinct multi-feed needs came up:

1. **Multi as a feed-chain** (like “double”, but longer)
   - Example: `stETH -> ETH -> BTC`
   - Here the arrows represent _feeds_; mathematically it’s a product/ratio chain that converts from the first asset to the last.

2. **Multi as weighted composition of paths (optional)**
   - Example: take a weighted average of alternative conversion routes, such as combining:
     - `stETH -> ETH -> BTC` (Chainlink chain)
     - `stETH -> USDC -> BTC` (where some legs may not be Chainlink)

This “weighted routes” notion is different from the legacy custom aggregator (which aggregated a basket of prices and then converted via a USD feed). It should be treated as an explicit, separate concept.

High-level API sketches:

- `MultiFeedChainPriceLib.getPrice18(legs[], invert, divisor) -> uint256`
  - `legs[]` is an ordered list of feed observations (each observation already validated and normalized)
  - computes the end-to-end conversion from the first asset to the last

- `WeightedRoutePriceLib.getPrice18(routes[], weights[], divisor) -> uint256`
  - each `route` can be a chain
  - weights must be fixed at deployment (no governance setters)

## USD special treatment in legacy Custom (v1/v2)

Legacy “custom” had a _distinct USD feed_ with special handling:

- It stores `usdFeed` + `usdFeedDecimals` separately.
- It reserves a feed identifier slot for it: `feedIdentifiers[100] = usdFeed`.
- It keeps separate constraint update pathways (e.g., “set constraints for custom feeds by id” vs “update USD feed constraints”).

### How USD is used in pricing

Both versions compute an “aggregated basket price” from `customFeeds[]`:

- Fetch each custom feed price (via `PriceOracle_v1`), sum them, then divide by `aggregationDivisor`.

Then they use the USD feed as the conversion anchor.

#### v1 (multiplies by rate and uses USD feed as stETH/USD)

In v1 the output is described as “units of aggregated basket per 1 wstETH”. It does:

- `rate = _getRate()` (wstETH/stETH, or fxSAVE, or Chainlink rate feed)
- `usdFeedPrice = latestAnswer(usdFeed)`
- derives `wstETH/USD` as:
  - `wstEthUsdPrice = rate * usdFeedPrice`
- then converts from USD to basket units:
  - `basketPerWstETH = wstEthUsdPrice / normalizedAggregatedPrice`

So USD is special because it is treated as a _pivot currency_, and in v1 it is combined with the rate to form the “base asset price in USD”.

#### v2 (does not multiply by rate; uses USD feed directly)

In v2 the comment explicitly states: “Price does NOT multiply by rate - uses USD feed and aggregated prices directly”. It computes:

- `normalizedAggregatedPrice` as before
- `usdFeedPrice = latestAnswer(usdFeed)`

Then it returns either:

- non-inverted: `basketPerUSD = usdFeedPrice / normalizedAggregatedPrice`
- inverted: `usdPerBasket = normalizedAggregatedPrice / usdFeedPrice`

So USD is special in v2 because it is the direct unit-of-account conversion feed for the aggregated basket.

## Configuration philosophy: immutable data + upgrades

### Why “no mutable config” is consistent (and testable)

You called out two practical points:

1. Testing upgrades: to change config via upgrades, tests must upgrade and then validate the new behavior/config.
2. Backtesting config: staleness/relative deviation thresholds depend on historical feed behavior and should be guided by offchain analysis.

This leads to a coherent operational model:

- **Immutable configuration per deployment** (no governance setters).
- **Configuration changes happen via new implementation + proxy upgrade**.
- **Backtesting is offchain** and produces a recommended config for the next implementation.
- Onchain tests validate:
  - correctness of math,
  - correctness of validation rules,
  - upgrade correctness (storage invariants and changed behavior).

### Testing implications

A “config-by-upgrade” workflow is testable:

- Deploy proxy pointing to implementation V1 (with config baked in).
- Validate key outputs and that invariants hold.
- Upgrade proxy to implementation V2 (different config baked in).
- Validate that:
  - storage state remains consistent,
  - outputs/validation behavior reflect the new config.

This is heavier than setters, but eliminates a large class of operational risk around post-deploy governance mistakes and surprise mutability.

## Mixed providers (Chainlink + others) and why composition should be provider-agnostic

### The problem

Current v3 price libraries are Chainlink-shaped because they accept `AggregatorV3Interface` feeds and depend on `PriceOracle_v1`.

As soon as you want a multi-leg conversion where some legs are not Chainlink, you run into:

- **interface mismatch** (non-Chainlink feeds don’t provide Chainlink rounds/timestamps), and
- **semantic mismatch** (even with an adapter, “round” semantics and timestamp meaning can be wrong or lossy).

### Recommended approach

Keep the _composition layer_ provider-agnostic.

- Provider-specific validation libraries produce a normalized, validated observation (value in 18 decimals + a timestamp / freshness signal).
- Composition libraries consume observations, not raw provider interfaces.

High-level API sketch:

- `ChainlinkObservationLib.read(feed, constraints) -> Observation`
- `PythObservationLib.read(feed, constraints) -> Observation` (example)
- `PriceChainLib.compute(observations[], invert, divisor) -> uint256`
- `WeightedRoutePriceLib.compute(routes[], weights[]) -> uint256`

This makes “mixed providers” an explicit, supported design: each leg is validated under the correct rules before being combined.

## Decision checklist

These are the main decisions to lock down before implementing libraries/factories.

### Multi semantics

- **Chain-only vs basket:** is “Multi” strictly a feed-chain (generalized “double”), or does it also cover basket aggregation (sum/average/weighted) of multiple assets?
- **Units and quoting:** are all legs required to be consistent in quote currency (recommended), or can legs mix quote currencies (e.g., USD and ETH) and rely on explicit conversion legs?
- **Invert model:** is inversion applied to the entire path output (recommended), or are per-leg inversions allowed?

### Weighted routes (optional)

- **In-scope now?** if weighted routes are not immediately needed, defer and keep Multi as “just feed chains”.
- **Weighting model:** if included, use fixed weights at deployment; define whether weights sum to 1e18 or use simple integer weights + divisor.
- **Route comparability:** require all routes to end in the same output asset/units before weighting.

### Constraints and configuration model

- **Immutability policy:** confirm “no setters”; all constraints/feeds/weights are immutable per implementation.
- **Upgrade workflow:** changes to constraints happen via new implementation + proxy upgrade; tests must cover upgrade behavior changes explicitly.
- **Backtesting responsibility:** define that config selection is offchain and produces a recommended constraint set per deployment/upgrade.

### Provider boundaries

- **Observation boundary:** decide that composition consumes normalized observations, not provider interfaces.
- **Provider adapters:** if adapters exist, they must guarantee meaningful timestamps/freshness semantics; otherwise they should not be used.
- **Minimum supported providers:** explicitly list what’s supported at v1 of the approach (e.g., Chainlink only) to avoid accidental mixed-provider assumptions.

## Summary

- `PriceOracle_v1` is already the shared Chainlink validation primitive across v2 and v3.
- A Chainlink-based rate feed library should reuse that primitive rather than duplicating `latestRoundData()` parsing.
- “Multi” should mean either:
  - a chain of feed legs (generalization of “double”), and/or
  - (optionally) weighted composition of routes.
- Legacy Custom treated USD as a special pivot feed:
  - v1 combined rate + USD feed to form a base-asset USD price,
  - v2 used USD feed directly for basket-per-USD (or inverted).
- Avoiding mutable config is consistent with an upgrade-based workflow; testing upgrades becomes a first-class requirement, and backtesting remains offchain.
