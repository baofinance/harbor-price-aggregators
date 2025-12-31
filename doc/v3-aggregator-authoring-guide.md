# Harbor v3 Aggregator Authoring Guide

This is a concise checklist for adding a new v3 aggregator.

## Contract shape

Every v3 aggregator:

- Inherits from `HarborAggregator_v3`.
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

| Component | Location | Example |
|-----------|----------|---------|
| Formula contract | `src/aggregators/Aggregator_<BASE>_<QUOTE>.sol` | `Aggregator_fxUSD_ETH.sol` |
| Mainnet wiring | `src/Aggregator_<BASE>_<QUOTE>_mainnet.sol` | `Aggregator_fxUSD_ETH_mainnet.sol` |
| Rate library | `src/rates/*RateLib.sol` | `FxSaveRateLib.sol`, `WstETHRateLib.sol` |
| Price library | `src/prices/*PriceLib.sol` | `SingleFeedPriceLib.sol`, `DoubleFeedPriceLib.sol` |
| Feed addresses | `src/feeds/chainlink/mainnet/<PAIR>.sol` | `ETH_USD.sol`, `BTC_USD.sol` |

## Steps

### 1) Define the oracle graph

Write a short "pair spec" before coding:

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
- Feed configuration:
  - `PRICE_FEED_HEARTBEAT` from the feed library (e.g. `ETH_USD.HEARTBEAT`).

If the pair cannot be expressed using the existing rate/price libraries, add a new library first.

### 2) Implement the formula contract (immutables)

Start from the existing patterns:

- Single feed + fxSAVE rate: `Aggregator_fxUSD_ETH`
- Double feed + wstETH rate: `Aggregator_stETH_BTC`

Constraints:

- Validate constructor inputs (zero address checks; divisor != 0).
- Store configuration as `immutable`.
- Do not add mutable per-oracle configuration setters.

Minimal skeleton:

```solidity
contract Aggregator_EXAMPLE is HarborAggregator_v3 {
    using FxSaveRateLib for IFxSAVE;  // or WstETHRateLib for IWstETH

    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    IFxSAVE public immutable FXSAVE;
    AggregatorV3Interface public immutable PRICE_FEED;
    uint8 public immutable PRICE_FEED_DECIMALS;
    uint256 public immutable PRICE_FEED_HEARTBEAT;
    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address fxsave_,
        address priceFeed_,
        uint256 priceFeedHeartbeat_,
        uint256 divisor_,
        bool invertPrice_
    ) {
        if (fxsave_ == address(0)) revert InvalidAddress(fxsave_);
        if (priceFeed_ == address(0)) revert InvalidAddress(priceFeed_);
        if (divisor_ == 0) revert InvalidDivisor(divisor_);

        FXSAVE = IFxSAVE(fxsave_);
        PRICE_FEED = AggregatorV3Interface(priceFeed_);
        PRICE_FEED_DECIMALS = PRICE_FEED.decimals();
        PRICE_FEED_HEARTBEAT = priceFeedHeartbeat_;
        PRICE_DIVISOR = divisor_;
        INVERT_PRICE = invertPrice_;
    }

    function base() external view returns (address) { return address(FXSAVE); }
    function rateProvider() external view returns (address) { return address(FXSAVE); }
    function quoteName() external pure returns (string memory) { return "QUOTE"; }
    function oracleName() external pure returns (string memory) { return "BASE/QUOTE"; }

    function latestAnswer() external view returns (uint256, uint256, uint256, uint256) {
        uint256 rate = FXSAVE.getRate();
        uint256 price = SingleFeedPriceLib.getPrice(
            PRICE_FEED, PRICE_FEED_DECIMALS, PRICE_FEED_HEARTBEAT, PRICE_DIVISOR, INVERT_PRICE
        );
        return (price, price, rate, rate);
    }
}
```

Notes:

- Rate:
  - fxSAVE: `using FxSaveRateLib for IFxSAVE;` then `uint256 rate = FXSAVE.getRate();`
  - wstETH: `using WstETHRateLib for IWstETH;` then `uint256 rate = WSTETH.getRate();`
- Price:
  - Single feed: `SingleFeedPriceLib.getPrice(feed, decimals, heartbeat, divisor, invert)`
  - Double feed: `DoubleFeedPriceLib.getPrice(feed1, dec1, hb1, feed2, dec2, hb2, divisor, invert)`
- Feed decimals:
  - Cache `feed.decimals()` into an immutable `uint8` in the constructor.

### 3) Implement the chain wiring wrapper (0-arg constructor)

This is a tiny contract that passes canonical addresses to the formula constructor.

Feed addresses are in `src/feeds/chainlink/mainnet/`:
- `ETH_USD.FEED`, `ETH_USD.HEARTBEAT`
- `BTC_USD.FEED`, `BTC_USD.HEARTBEAT`
- etc.

Rate sources are in `src/rates/mainnet/`:
- `MainnetRateSources.FXSAVE`
- `MainnetRateSources.WSTETH`

Example:

```solidity
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_fxUSD_ETH} from "@harbor-price/oracles/Aggregator_fxUSD_ETH.sol";

contract Aggregator_fxUSD_ETH_mainnet is Aggregator_fxUSD_ETH {
    constructor() Aggregator_fxUSD_ETH(
        MainnetRateSources.FXSAVE,
        ETH_USD.FEED,
        ETH_USD.HEARTBEAT,
        1,      // divisor
        true    // invert (ETH/USD → USD/ETH)
    ) {}
}
```

Expectation: the wrapper has **no configuration logic**, just passes constants to the formula constructor.

### 4) Add feed library (if needed)

If using a new Chainlink feed, add a library to `src/feeds/chainlink/mainnet/`:

```solidity
// src/feeds/chainlink/mainnet/NEW_FEED.sol
library NEW_FEED {
    address constant FEED = 0x...;      // Chainlink feed address
    uint256 constant HEARTBEAT = 3600;  // From Chainlink docs
}
```

### 5) Write the tests

- Unit tests: `test/aggregators/Aggregator_<BASE>_<QUOTE>.t.sol`
- Follow existing patterns (see `Aggregator_fxUSD_ETH.t.sol`, `Aggregator_stETH_BTC.t.sol`)
- Required tests:
  - Constructor validation (zero address, zero divisor)
  - `latestAnswer()` returns valid tuple
  - Stale feed handling
  - Rate bounds handling
  - Identity getters (`base()`, `quoteName()`, `oracleName()`, `rateProvider()`)
  - UUPS upgrade test
