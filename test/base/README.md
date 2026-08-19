# Base Oracle Tests

Tests for Base oracle contracts (stETH/BOM5). Includes both unit tests (with mocks) and fork tests (against live Base mainnet).

## Test Structure

### Unit Tests

Unit tests use mocks and follow the mainnet test pattern:

- **Normalized multi-feed aggregator**: `Aggregator_stETH_BOM5.t.sol`
- **Test base class**: `BaseMultiFeedNormalizedAggregatorTestBase.sol`

Unit tests are fast, deterministic, and don't require an RPC endpoint. They test:

- Constructor validation (zero address/parameter checks)
- Interface compliance (baseName, quoteName, oracleName, version, rateProvider)
- Price and rate calculations
- Staleness checks for all feeds
- Rate validation (min/max bounds)
- Normalization factor validation
- UUPS upgrade functionality

### Fork Tests

Fork tests run against live Base mainnet and test the actual wiring contract:

- **BOM5 oracle**: `BaseBOM5OracleFork.t.sol`

Fork tests verify that the deployed contract works correctly with real Chainlink feeds on Base.

## Running Tests

### Unit Tests (No RPC Required)

Run all unit tests:

```bash
forge test --match-path "test/base/Aggregator_*.t.sol" -vvv
```

Run the BOM5 unit test:

```bash
forge test --match-path "test/base/Aggregator_stETH_BOM5.t.sol" -vvv
```

### Fork Tests (Requires RPC)

Run fork tests on a Base fork:

```bash
forge test --match-path "test/base/*Fork.t.sol" --fork-url $base -vvv
```

Or specify the RPC URL directly (ensure `BASE_RPC_URL` is set in your environment):

```bash
forge test --match-path "test/base/*Fork.t.sol" --fork-url ${BASE_RPC_URL} -vvv
```

Run the BOM5 fork test:

```bash
# Run BOM5 oracle fork test
forge test --match-path "test/base/BaseBOM5OracleFork.t.sol" --match-test "test_BOM5_RateAndPrice" --fork-url $base -vvv
```

**Note:** Make sure to set `BASE_RPC_URL` in your `.env` file (see `.env.example` for reference).

## Test Output

### Unit Tests

Unit tests output console logs showing:

- Bid/Ask Price (18 decimals)
- Bid/Ask Rate (18 decimals)
- Oracle metadata (baseName, quoteName, oracleName, rateProvider)

### Fork Tests

Fork tests output:

- Bid/Ask Price (18 decimals)
- Bid/Ask Rate (18 decimals)
- Oracle metadata (base, rateProvider, quoteName, oracleName, feedCount)
- Normalization factors for each meme coin (DOGE, SHIB, PEPE, TRUMP, WIF)

This allows verification of the oracle values against on-chain data.
