# Arbitrum Oracle Tests

Fork tests for Arbitrum oracle contracts.

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
forge test --match-path "test/arbitrum/*.t.sol" --match-test "test_AllOracles_RateAndPrice" --fork-url $arbitrum -vvv
```

## Test Output

The tests will output:
- Bid/Ask Price (18 decimals)
- Bid/Ask Rate (18 decimals) 
- Human-readable Price (divided by 1e18)
- Human-readable Rate (divided by 1e18)

This allows verification of the oracle values against on-chain data.

