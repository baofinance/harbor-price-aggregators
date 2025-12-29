# Arbitrum Oracle Tests

Fork tests for Arbitrum oracle contracts (stETH and USDE).

## Running Tests

To run these tests on an Arbitrum fork, you can use the RPC endpoint from `foundry.toml`:

```bash
forge test --match-path "test/arbitrum/*.t.sol" --fork-url $arbitrum -vvv
```

Or specify the RPC URL directly (ensure `ARBITRUM_RPC_URL` is set in your environment):

```bash
forge test --match-path "test/arbitrum/*.t.sol" --fork-url ${ARBITRUM_RPC_URL} -vvv
```

To run a specific test:

```bash
# Run all stETH oracle tests
forge test --match-path "test/arbitrum/ArbitrumOraclesFork.t.sol" --match-test "test_AllOracles_RateAndPrice" --fork-url $arbitrum -vvv

# Run all USDE oracle tests
forge test --match-path "test/arbitrum/ArbitrumSUSDEOraclesFork.t.sol" --match-test "test_AllOracles_RateAndPrice" --fork-url $arbitrum -vvv
```

**Note:** Make sure to set `ARBITRUM_RPC_URL` in your `.env` file (see `.env.example` for reference).

## Test Output

The tests will output:
- Bid/Ask Price (18 decimals)
- Bid/Ask Rate (18 decimals) 
- Human-readable Price (divided by 1e18)
- Human-readable Rate (divided by 1e18)

This allows verification of the oracle values against on-chain data.

