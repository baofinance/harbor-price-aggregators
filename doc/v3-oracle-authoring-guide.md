# Harbor v3 Oracle Authoring Guide

This is a concise checklist for adding a new v3 oracle.

## Contract shape

Every v3 oracle:

- Inherits from `HarborPriceAggregator_v3`.
- Implements identity getters from `IHarborPriceAggregatorV3`:
  - `base() -> address`
  - `rateProvider() -> address`
  - `quoteName() -> string` (pure)
  - `oracleName() -> string` (pure)
  - `version() -> 3` (already provided by the base)
- Implements `IWrappedPriceOracle.latestAnswer()` and returns:
  - `(minPrice, maxPrice, minRate, maxRate)`
  - For deterministic oracles today: return `(price, price, rate, rate)`.

## Where code goes

- Formula contract: `src/price/oracles/Oracle_<BASE>_<QUOTE>.sol`
- Mainnet wiring contract: `src/price/oracles/Oracle_<BASE>_<QUOTE>_Mainnet.sol`
- Rate library: `src/price/rates/*RateLib.sol` (only if a new rate source is needed)
- Price library: `src/price/prices/*PriceLib.sol` (only if a new feed graph is needed)

## Steps

### 1) Define the oracle graph

Write a short “pair spec” before coding:

- Base asset identity (token address on the target chain).
- Quote symbol/name ("ETH", "BTC", "EUR", ...).
- Rate source:
  - fxSAVE-style vault rate (`FxSaveRateLib`), or
  - wstETH wrapper rate (`WstETHRateLib`), or
  - new rate source (requires a new `*RateLib`).
- Price source:
  - single Chainlink feed (use `SingleFeedPriceLib`), or
  - two-feed ratio (use `DoubleFeedPriceLib`).
- Price normalization:
  - `PRICE_DIVISOR` (e.g. `1` for most, `1e12` for MCAP-style feeds).
  - `INVERT_PRICE` (e.g. invert ETH/USD to get USD/ETH).
- Validation constraints:
  - `maxAnswerAge`
  - `maxPercentageDeviation`

If the pair cannot be expressed using the existing rate/price libraries, add a new library first.

### 2) Implement the formula contract (immutables)

Start from the existing patterns:

- Single feed + fxSAVE rate: `Oracle_fxUSD_ETH`
- Double feed + wstETH rate: `Oracle_stETH_BTC`

Constraints:

- Validate constructor inputs (zero address checks; divisor != 0).
- Store configuration as `immutable`.
- Do not add mutable per-oracle configuration setters.

Minimal skeleton:

```solidity
contract Oracle_EXAMPLE is HarborPriceAggregator_v3 {
    // immutables...

    constructor(/* addresses + bounds */) {
        // validate; assign immutables
    }

    function base() external view returns (address) { /* return base */ }
    function rateProvider() external view returns (address) { /* return provider */ }
    function quoteName() external pure returns (string memory) { return "QUOTE"; }
    function oracleName() external pure returns (string memory) { return "BASE/QUOTE"; }

    function latestAnswer() external view returns (uint256, uint256, uint256, uint256) {
        uint256 rate = /* from rate lib */;
        uint256 price = /* from price lib */;
        return (price, price, rate, rate);
    }
}
```

Notes:

- Rate:
  - fxSAVE: `using FxSaveRateLib for IFxSAVE;` then `uint256 rate = FXSAVE.getRate();`
  - wstETH: `using WstETHRateLib for IWstETH;` then `uint256 rate = WSTETH.getRate();`
- Price:
  - Use `PriceOracle_v1.Constraints` and pass bounds into `SingleFeedPriceLib.getPrice(...)` or `DoubleFeedPriceLib.getPrice(...)`.
- Feed decimals:
  - Cache `feed.decimals()` into an immutable `uint8` in the constructor.

### 3) Implement the chain wiring wrapper (0-arg)

This should be a tiny constructor wrapper that selects canonical addresses from `MainnetOracleAddresses`.

See:

- `Oracle_fxUSD_ETH_Mainnet`
- `Oracle_stETH_BTC_Mainnet`

Expectation: the wrapper has **no configuration logic**, just passes constants to the formula constructor.

### 4) Write the tests :-)
