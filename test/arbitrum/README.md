# Arbitrum Oracle Tests

Tests for Arbitrum oracle contracts (stETH and USDE). Includes both unit tests (with mocks) and fork tests (against live Arbitrum mainnet).

## Test Structure

### Unit Tests

Unit tests use mocks and follow the mainnet test pattern:
- **Double-feed aggregators**: `Aggregator_stETH_*.t.sol`, `Aggregator_USDE_*.t.sol` (AAPL, AMZN, GOOGL, META, MSFT, NVDA, SPY, TSLA)
- **Multi-feed aggregators**: `Aggregator_stETH_MAG7.t.sol`, `Aggregator_USDE_MAG7.t.sol`, `Aggregator_stETH_MAG7i26.t.sol`, `Aggregator_USDE_MAG7i26.t.sol`
- **Test base classes**: `ArbitrumDoubleFeedAggregatorTestBase.sol`, `ArbitrumMultiFeedSumAggregatorTestBase.sol`, `ArbitrumMultiFeedIndexAggregatorTestBase.sol`

Unit tests are fast, deterministic, and don't require an RPC endpoint. They test:
- Constructor validation (zero address/parameter checks)
- Interface compliance (baseName, quoteName, oracleName, version, rateProvider)
- Price and rate calculations
- Staleness checks for all feeds
- Rate validation (min/max bounds)
- UUPS upgrade functionality

### Fork Tests

Fork tests run against live Arbitrum mainnet and test the actual wiring contracts:
- **Double-feed oracles**: `ArbitrumOraclesFork.t.sol`, `ArbitrumSUSDEOraclesFork.t.sol`
- **Multi-feed oracles**: `ArbitrumMAG7OraclesFork.t.sol`, `ArbitrumMAG7i26OraclesFork_stETH.t.sol`, `ArbitrumMAG7i26OraclesFork_USDE.t.sol`

Fork tests verify that the deployed contracts work correctly with real Chainlink feeds on Arbitrum.

## Running Tests

### Unit Tests (No RPC Required)

Run all unit tests:

```bash
forge test --match-path "test/arbitrum/Aggregator_*.t.sol" -vvv
```

Run specific test suites:

```bash
# Run all double-feed unit tests
forge test --match-path "test/arbitrum/Aggregator_stETH_*.t.sol" --match-path "test/arbitrum/Aggregator_USDE_*.t.sol" -vvv

# Run MAG7 unit tests
forge test --match-path "test/arbitrum/*MAG7.t.sol" -vvv

# Run MAG7i26 unit tests
forge test --match-path "test/arbitrum/*MAG7i26.t.sol" -vvv

# Run a specific aggregator test
forge test --match-path "test/arbitrum/Aggregator_stETH_AAPL.t.sol" -vvv
```

### Fork Tests (Requires RPC)

Run all fork tests on an Arbitrum fork:

```bash
forge test --match-path "test/arbitrum/*Fork.t.sol" --fork-url $arbitrum -vvv
```

Or specify the RPC URL directly (ensure `ARBITRUM_RPC_URL` is set in your environment):

```bash
forge test --match-path "test/arbitrum/*Fork.t.sol" --fork-url ${ARBITRUM_RPC_URL} -vvv
```

Run specific fork tests:

```bash
# Run all stETH double-feed oracle tests
forge test --match-path "test/arbitrum/ArbitrumOraclesFork.t.sol" --match-test "test_AllOracles_RateAndPrice" --fork-url $arbitrum -vvv

# Run all USDE double-feed oracle tests
forge test --match-path "test/arbitrum/ArbitrumSUSDEOraclesFork.t.sol" --match-test "test_AllOracles_RateAndPrice" --fork-url $arbitrum -vvv

# Run MAG7 fork tests
forge test --match-path "test/arbitrum/ArbitrumMAG7OraclesFork.t.sol" --fork-url $arbitrum -vvv

# Run MAG7i26 fork tests (split into separate files to reduce rate limiting)
forge test --match-path "test/arbitrum/ArbitrumMAG7i26OraclesFork_stETH.t.sol" --fork-url $arbitrum -vvv
forge test --match-path "test/arbitrum/ArbitrumMAG7i26OraclesFork_USDE.t.sol" --fork-url $arbitrum -vvv
```

**Note:** Make sure to set `ARBITRUM_RPC_URL` in your `.env` file (see `.env.example` for reference).

### Utility Scripts

Get MAG7 index price (sum of 7 stock feeds):
```bash
forge script script/GetMAG7IndexPrice.s.sol:GetMAG7IndexPrice --rpc-url $arbitrum -vvv
```

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
- Oracle metadata (base, rateProvider, quoteName, oracleName)
- For MAG7/MAG7i26: feed count and index price information

This allows verification of the oracle values against on-chain data.
