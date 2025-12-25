# HarborPriceAggregator_v3 Design (Current State)

This document explains the v3 oracle design as it exists in this repository today: what it is, why it is shaped this way (including rejected alternatives), and how it is validated.

This is intended to be read alongside `doc/v3-oracle-authoring-guide.md`.

## Goals

- Make each oracle’s behavior explicit in its bytecode via immutables (feeds, bounds, math choices).
- Keep `initialize()` minimal: `initialize(owner)` only.
- Reduce “configuration surface area” and governance complexity by removing mutable per-oracle config.
- Keep the base contract stable while new rate sources or price graphs are added as libraries.

## Non-goals

- Supporting multiple variants for the same `(base, quote)` under `harbor_v1` identity.
- Runtime reconfiguration of constraints/feeds via admin setters.

## Design overview

### High-level model

v3 is split into three layers:

1. **Base upgradeable contract** (`HarborPriceAggregator_v3`)
2. **Internal computation libraries** (rate + price)
3. **Per-oracle formula contracts** with immutables + 0-arg chain wiring wrappers

The proxy-time configuration is always just `initialize(owner)`.

### Contract & library map

- Base:
  - `src/price/HarborPriceAggregator_v3.sol`
  - `src/interfaces/IHarborPriceAggregatorV3.sol`
- Rate libraries:
  - `src/price/rates/FxSaveRateLib.sol`
  - `src/price/rates/WstETHRateLib.sol`
- Price libraries:
  - `src/price/prices/SingleFeedPriceLib.sol`
  - `src/price/prices/DoubleFeedPriceLib.sol`
- Feed validation:
  - `src/price/PriceOracle_v1.sol` (validates and normalizes Chainlink to 18 decimals)
- Example formula contracts:
  - `src/price/oracles/Oracle_fxUSD_ETH.sol`
  - `src/price/oracles/Oracle_stETH_BTC.sol`
- Mainnet wiring (0-arg wrappers):
  - `src/Oracle_fxUSD_ETH_mainnet.sol`
  - `src/Oracle_stETH_BTC_mainnet.sol`

### Base contract

`HarborPriceAggregator_v3` provides:

- UUPS upgradeability, reentrancy guard, and ownership.
- `initialize(owner)`.
- `version() == 3`.
- An ERC-7201 namespaced storage slot reserved for future v3 mutable state.

What it does _not_ do:

- It does not implement any oracle math.
- It does not store per-oracle configuration.
- It does not define a “menu” of rate sources or feed graphs.

### Identity

v3 oracles implement `IHarborPriceAggregatorV3`:

- `base()` and `rateProvider()` are `view` and typically return immutables.
- `quoteName()` and `oracleName()` are `pure` and return constant strings.

This makes the oracle identity non-updatable and non-storage-backed.

### Computation libraries

Rate and price are treated as independent computations:

- Rate libs fetch and (optionally) validate a rate, returning a single 18-decimal value.
- Price libs fetch and validate Chainlink feeds via `PriceOracle_v1`, then compute a single 18-decimal price.

The formula contract composes them and returns `(price, price, rate, rate)`.

### Formula + wiring split

Each oracle pair is written as:

- A **formula contract** with constructor args and immutables (portable across chains).
- A **chain wiring wrapper** (e.g. `_mainnet`) that hardcodes canonical addresses from `MainnetOracleAddresses`.

This keeps formula code reusable while making deployments deterministic and reviewable on a given chain.

## Rejected alternatives (and why)

### v2 style: “single implementation + config in storage”

v2 uses a small number of implementations and stores per-oracle configuration in proxy storage (feeds, bounds, enums selecting rate source and price type, and setters).

Rejected for v3 because it:

- Centralizes critical configuration into mutable storage.
- Requires selection logic (`if/else` / enums) that grows as new variants are added.
- Makes “what this oracle does” harder to audit from bytecode alone.
- Conflicts with the deployment model where the proxy address is a stable identity (changing config changes semantics).

### Inheritance mixins (rate mixins + price mixins)

Rejected because it:

- Couples composition order and behavior to the inheritance graph.
- Bakes validation and call formats into base classes.
- Makes it harder to reuse the computation outside “oracle contracts”.

### “One giant v3 base that knows all graphs”

Rejected because it recreates v2’s scaling problem: adding a new rate source or graph means changing the shared base, increasing upgrade/coordination risk.

## Validation: zero-tolerance fork comparisons

### What “validated” means

For each oracle pair where a v2 deployed reference exists, we validate by comparing `latestAnswer()` outputs across a sampled block range on a mainnet fork.

We require **exact equality** of all four returned values:

- `minPrice`, `maxPrice`, `minRate`, `maxRate`

Any mismatch fails the test.

### Test mechanism

- Test runner: `test/price/AllOracleComparisons.t.sol`
- Comparison engine: `test/price/OracleComparisonBase.sol`

Key properties:

- Fork is pinned at a fixed end block for determinism.
- The test rolls the fork forward across blocks and compares outputs.
- v3 candidates are deployed behind an ERC1967 proxy and initialized with `initialize(owner)`.

### How to run

- Full suite: `yarn test`

Comparisons run batched and single-threaded to reduce RPC burstiness.

## Extending v3

- New rate source: add a new `src/price/rates/*RateLib.sol` and use it from a formula contract.
- New price graph: add a new `src/price/prices/*PriceLib.sol` and use it from a formula contract.
- New oracle pair: add `Oracle_<BASE>_<QUOTE>.sol` + chain wiring wrapper, then add comparison cases to `AllOracleComparisons`.
