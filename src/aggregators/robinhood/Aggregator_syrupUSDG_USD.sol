// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {IWrappedPriceOracle} from "@bao/interfaces/IWrappedPriceOracle.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";

/// @notice syrupUSDG/USD oracle (rate: syrupUSDG/USDG Chainlink, price: USDG/USD).
/// @dev Harbor Yield shape: `(price, price, rate, rate)` with invert false; consumer does price×rate/1e18.
///      Price is not pre-multiplied by the rate (unlike `Aggregator_SingleRate_SinglePrice`).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_syrupUSDG_USD is HarborAggregator_v3 {
    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable PRICE_FEED;
    uint8 public immutable PRICE_FEED_DECIMALS;
    uint256 public immutable PRICE_FEED_HEARTBEAT;
    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address rateFeed_,
        address priceFeed_,
        uint256 priceHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (priceFeed_ == address(0)) revert InvalidAddress(priceFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        RATE_FEED = AggregatorV3Interface(rateFeed_);
        PRICE_FEED = AggregatorV3Interface(priceFeed_);
        PRICE_FEED_DECIMALS = PRICE_FEED.decimals();
        PRICE_FEED_HEARTBEAT = priceHeartbeat_;
        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_FEED);
    }

    function _baseName() internal pure override returns (string memory) {
        return "syrupUSDG";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

        uint256 price = SingleFeedPriceLib.getPrice(
            PRICE_FEED,
            PRICE_FEED_DECIMALS,
            PRICE_FEED_HEARTBEAT,
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        return (price, price, rate, rate);
    }
}
