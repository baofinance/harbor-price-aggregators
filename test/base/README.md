# Base Oracle Tests

Fork tests for Base oracle contracts (stETH/BOM5).

## Running Tests

To run these tests on a Base fork, you can use the RPC endpoint from `foundry.toml`:

```bash
forge test --match-path "test/base/*.t.sol" --fork-url $base -vvv
```

Or specify the RPC URL directly (ensure `BASE_RPC_URL` is set in your environment):

```bash
forge test --match-path "test/base/*.t.sol" --fork-url ${BASE_RPC_URL} -vvv
```

To run a specific test:

```bash
# Run BOM5 oracle test
forge test --match-path "test/base/BaseBOM5OracleFork.t.sol" --match-test "test_BOM5_RateAndPrice" --fork-url $base -vvv
```

**Note:** Make sure to set `BASE_RPC_URL` in your `.env` file (see `.env.example` for reference).

## Test Output

The tests will output:
- Bid/Ask Price (18 decimals)
- Bid/Ask Rate (18 decimals) 
- Oracle metadata (base, rateProvider, quoteName, oracleName, feedCount)
- Normalization factors for each meme coin (DOGE, SHIB, PEPE, TRUMP, WIF)

This allows verification of the oracle values against on-chain data.

