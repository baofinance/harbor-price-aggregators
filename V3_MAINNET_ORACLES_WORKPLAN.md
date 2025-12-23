# V3 Mainnet Oracles Workplan (Tracking Doc)

This document is the single source of truth for the remaining work to:

- Add **7 additional v3 mainnet oracle wrapper contracts** (thin wiring only; logic lives in libraries).
- Bring testing up to the same standard as the existing v2 comparison base classes.
- Add a standardized v3 test framework covering _price composition_ and _upgradeability_.
- Rename and tighten the Chainlink feed validation library currently named `PriceOracle_v1`.

## Scope and Constraints

### Hard constraints

- **No new base contracts are required for the new oracles.** New v3 oracles are thin wrappers that pass mainnet addresses/constants to existing library-backed implementations.
- Use the structure of:
  - `src/price/oracles/Oracle_fxUSD_ETH.sol` + `src/price/oracles/Oracle_fxUSD_ETH_Mainnet.sol`
  - `src/price/oracles/Oracle_stETH_BTC.sol` + `src/price/oracles/Oracle_stETH_BTC_Mainnet.sol`
- **Parameterization must come from the deployment script** (see: `script/deploy-harbor-oracles-v2-mainnet-new`).
  - Only exception: `Oracle_stETH_BTC_Mainnet` must use `MainnetOracleAddresses.STETH_USD_FEED` as the 3rd constructor arg.
    - This is already implemented in code.
- Do not drop requirements: this file enumerates every deliverable and acceptance criteria.

### Non-goals

- Refactoring v3 oracle logic internals (the logic is assumed to live in libraries; wrappers only).

## Inventory (Current State)

### Existing mainnet v3 wrappers

- `src/price/oracles/Oracle_fxUSD_ETH_Mainnet.sol`
- `src/price/oracles/Oracle_stETH_BTC_Mainnet.sol`

**Phase 0 (Prep) — Inventory validation**

- [ ] Confirm the repo still contains only the 2 existing mainnet v3 wrappers listed above.
- [ ] Confirm `MainnetOracleAddresses` contains (or can provide) all required feed addresses referenced by the deployment script.

### Deployment script source of truth

- `script/deploy-harbor-oracles-v2-mainnet-new`
  - This script currently documents the **9 v2** proxy deployments:
    - Single-feed: `FXUSD_ETH`, `FXUSD_BTC`, `FXUSD_EUR`, `FXUSD_XAU`, `FXUSD_MCAP`
    - Double-feed: `STETH_BTC`, `STETH_EUR`, `STETH_XAU`, `STETH_MCAP`
  - For v3 mainnet wrappers, we will treat this script as the canonical list of _pairs_ and their _wiring parameters_ (feeds, divisor, invert, etc.), adapting to v3 constructor signatures.

## Deliverables

### D1 — Re-study `Oracle_stETH_BTC_Mainnet`

- Confirm the wiring is correct vs the deployment script’s intent.
- Confirm the constructor parameters correspond to:
  - assets (stETH / wstETH)
  - feeds (stETH/USD + BTC/USD)
  - divisor/invert flags
  - max age/dev constants

**Acceptance criteria**

- The constructor arguments match the deployment spec and existing v2 behavior expectations.

**Phase 1 (Validate existing) — Checklist**

- [ ] Compare `Oracle_stETH_BTC_Mainnet` constructor args against `script/deploy-harbor-oracles-v2-mainnet-new`.
- [ ] Confirm the intentional exception is present: 3rd arg is `MainnetOracleAddresses.STETH_USD_FEED`.
- [ ] Confirm no other parameter drift exists (divisor, invert, max ages, etc.).

### D2 — Add 7 more v3 mainnet wrapper contracts

We already have 2:

- `fxUSD/ETH`
- `stETH/BTC`

We must add the remaining **7 wrappers**:

- fxUSD/BTC
- fxUSD/EUR
- fxUSD/XAU
- fxUSD/MCAP
- stETH/EUR
- stETH/XAU
- stETH/MCAP

**Implementation rules**

- Each wrapper is a single constructor that forwards mainnet constants from `MainnetOracleAddresses` into the corresponding v3 oracle implementation constructor.
- No new oracle base classes.

**Acceptance criteria**

- Each wrapper compiles and mirrors the template structure of the existing two.
- Wrapper constructor parameters are sourced from the deployment script definitions.

**Phase 2 (Implement wrappers) — Checklist**

- [ ] Add `fxUSD/BTC` wrapper.
- [ ] Add `fxUSD/EUR` wrapper.
- [ ] Add `fxUSD/XAU` wrapper.
- [ ] Add `fxUSD/MCAP` wrapper.
- [ ] Add `stETH/EUR` wrapper.
- [ ] Add `stETH/XAU` wrapper.
- [ ] Add `stETH/MCAP` wrapper.

- [ ] Ensure all wrapper parameters are taken from the deployment script (except the already-known stETH/BTC feed arg exception).
- [ ] Ensure the new wrappers follow the same shape as `Oracle_fxUSD_ETH_Mainnet` / `Oracle_stETH_BTC_Mainnet` (thin wiring only).

### D3 — Update deployment script(s) for v3 wrappers

- Add the new v3 wrapper contracts to deploy.

**Acceptance criteria**

- Script lists all 9 v3 wrappers explicitly, with their intended parameters clearly visible.

**Phase 3 (Deploy wiring) — Checklist**

- [ ] Add all 7 new v3 wrapper contracts to the deployment flow.
- [ ] Ensure all 9 v3 wrappers appear explicitly (no implicit loops that hide parameters).
- [ ] Ensure the parameters are reviewable directly in the script output/diff.

### D4 — Parity tests: v3 wrappers vs v2 proxies

Goal: for each pair (e.g. `FXUSD_BTC`), compare:

- v2 proxy output (existing deployed proxy addresses)
- v3 wrapper deployed fresh on fork (v3 implementation + proxy)

Use and extend the existing framework:

- `test/price/OracleComparisonBase.sol`

**Acceptance criteria**

- A test suite exists that runs comparisons for all 9 pairs.
- Mismatch output includes block+UTC timestamp (already supported by `OracleComparisonBase`).
- Tests are deterministic (fixed fork block) and bounded (iterations configurable).

**Phase 4 (Parity coverage) — Checklist**

- [ ] For each of the 9 pairs, add a parity test comparing v2 proxy output vs a freshly-deployed v3 wrapper (impl + proxy).
- [ ] Ensure mismatches print a precise diagnostic (pair, block, UTC time, both values).
- [ ] Ensure tests are deterministic: fixed fork block + controlled iteration count.

### D5 — Feed + rate library tests brought up to v2 standard

Interpretation: for the libraries that back v3 oracles (price feed validation, rate logic), add/upgrade tests so they match the rigor and structure of the v2 base-class driven tests.

**Acceptance criteria**

- Tests exist that cover:
  - stale feed
  - invalid / negative answer
  - deviation constraints
  - rate invalidity
  - boundary conditions for round transitions (where applicable)

**Phase 5 (Library test completeness) — Checklist**

- [ ] Identify the exact library modules used by the v3 oracle implementations (feed validation + rate logic).
- [ ] Add missing tests to reach v2-standard rigor for all failure modes listed above.
- [ ] Hit 100% line+branch coverage for the touched libraries.

### D6 — Standardized v3 test framework

Separate from parity tests, we want a standardized framework for:

- price composition correctness (single feed, double feed, divisor, inversion)
- upgradeability behavior (proxy wiring, initialization correctness)

**Acceptance criteria**

- A reusable base test exists for v3 oracles built from existing libraries, with minimal per-oracle boilerplate.

**Phase 6 (Framework) — Checklist**

- [ ] Create a reusable base test harness for v3 oracles that covers composition correctness.
- [ ] Add upgradeability tests (proxy wiring + init correctness) as part of the same framework.
- [ ] Ensure per-oracle tests only need minimal wiring (addresses + constructor args).

### D7 — Rename and restrict `PriceOracle_v1`

Request:

- Rename `src/price/PriceOracle_v1.sol` to a name matching its behavior.
  - Candidate: `ChainlinkCheckedPriceFeed.sol` or `ChainlinkCheckedOracle.sol`
- Change all non-internal functions to **internal**.

**Acceptance criteria**

- No public entrypoints remain; consumers must call internally.
- All import sites updated.
- The new filename and library name match.

**Phase 6 (Rename + restrict) — Checklist**

- [ ] Pick the final name (e.g. `ChainlinkCheckedPriceFeed` vs `ChainlinkCheckedOracle`).
- [ ] Rename the file and library accordingly.
- [ ] Make all non-internal functions internal.
- [ ] Update all imports/usages across the repo.
- [ ] Ensure downstream tests still compile and run.

## Open Questions (Need Decisions)

1. “Parameters defined by the deployment script” for v3:

- Divisors/invert/etc. are **exactly as per v2**.
- All v2 feeds should be ported.

2. Parity definition:

- TBD (exact equality vs tolerated rounding).

3. Runtime constraints:

- Dropped (unclear requirement).

## Implementation Sequence (Proposed)

**Phase sequence (track here)**

- [ ] Phase 0: Parse deployment script → produce a table of the 9 oracles and wiring params.
- [ ] Phase 1: Validate existing wrappers (D1).
- [ ] Phase 2: Add the 7 wrapper contracts (D2).
- [ ] Phase 3: Update deployment scripts (D3).
- [ ] Phase 4: Add parity tests for all 9 (D4).
- [ ] Phase 5: Add standardized v3 framework + library tests (D5–D6).
- [ ] Phase 6: Rename/tighten `PriceOracle_v1` (D7).

## Mapping Table (To be filled)

| Pair       | Feed(s)               | Divisor | Invert | Rate source | Notes        |
| ---------- | --------------------- | ------- | ------ | ----------- | ------------ |
| fxUSD/ETH  | ETH/USD               | 1       | true   | FXSAVE      | exists       |
| fxUSD/BTC  | BTC/USD               | 1       | true   | FXSAVE      |              |
| fxUSD/EUR  | EUR/USD               | 1       | true   | FXSAVE      |              |
| fxUSD/XAU  | XAU/USD               | 1       | true   | FXSAVE      |              |
| fxUSD/MCAP | MCAP feed             | TBD     | true   | FXSAVE      | check script |
| stETH/BTC  | stETH/USD + BTC/USD   | 1       | false  | WSTETH      | exists       |
| stETH/EUR  | stETH/USD + EUR/USD   | 1       | false  | WSTETH      |              |
| stETH/XAU  | stETH/USD + XAU/USD   | 1       | false  | WSTETH      |              |
| stETH/MCAP | stETH/USD + MCAP feed | TBD     | false  | WSTETH      | check script |

**Phase 0 (Prep) — Mapping table completion**

- [ ] Fill in all `TBD` values (especially divisors) strictly from `script/deploy-harbor-oracles-v2-mainnet-new`.
- [ ] Replace “MCAP feed” placeholder with the exact feed address identifier used in `MainnetOracleAddresses`.

## Testing Standard

Target is **100% line and branch coverage**.

**Phase 4–5 (Testing) — Coverage checklist**

- [ ] All new tests target 100% line coverage.
- [ ] All new tests target 100% branch coverage.
- [ ] All `if/else` branches use `{}` blocks on separate lines.

To support accurate branch coverage reporting, when writing branching logic always format conditionals so both sides are explicit blocks on separate lines:

```solidity
if (cond) {
  ...
} else {
  ...
}
```
