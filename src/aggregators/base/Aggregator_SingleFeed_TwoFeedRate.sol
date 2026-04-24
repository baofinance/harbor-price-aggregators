// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {TwoFeedRatioRateLib} from "@harbor-price/rates/TwoFeedRatioRateLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";

/// @notice Oracle with rate from two CL feeds and price from one feed; reported price = rate * priceFeed (wrapped asset in quote).
/// @dev Use for wstETH/USD or sUSDe/USD when rate = wrapper_USD / base_USD and price feed is base/USD.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
abstract contract Aggregator_SingleFeed_TwoFeedRate is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    AggregatorV3Interface public immutable RATE_NUMERATOR_FEED;
    AggregatorV3Interface public immutable RATE_DENOMINATOR_FEED;
    uint256 public immutable RATE_HEARTBEAT;

    AggregatorV3Interface public immutable PRICE_FEED;
    uint8 public immutable PRICE_FEED_DECIMALS;
    uint256 public immutable PRICE_FEED_HEARTBEAT;
    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address rateNumFeed_,
        address rateDenomFeed_,
        uint256 rateHeartbeat_,
        address priceFeed_,
        uint256 priceHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (rateNumFeed_ == address(0)) revert InvalidAddress(rateNumFeed_);
        if (rateDenomFeed_ == address(0)) revert InvalidAddress(rateDenomFeed_);
        if (priceFeed_ == address(0)) revert InvalidAddress(priceFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        RATE_NUMERATOR_FEED = AggregatorV3Interface(rateNumFeed_);
        RATE_DENOMINATOR_FEED = AggregatorV3Interface(rateDenomFeed_);
        RATE_HEARTBEAT = rateHeartbeat_;

        PRICE_FEED = AggregatorV3Interface(priceFeed_);
        PRICE_FEED_DECIMALS = PRICE_FEED.decimals();
        PRICE_FEED_HEARTBEAT = priceHeartbeat_;
        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_NUMERATOR_FEED);
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = TwoFeedRatioRateLib.getRate(RATE_NUMERATOR_FEED, RATE_DENOMINATOR_FEED, RATE_HEARTBEAT);
        uint256 basePrice = SingleFeedPriceLib.getPrice(
            PRICE_FEED,
            PRICE_FEED_DECIMALS,
            PRICE_FEED_HEARTBEAT,
            PRICE_DIVISOR,
            INVERT_PRICE
        );
        uint256 price = Math.mulDiv(rate, basePrice, 1e18);
        return (price, price, rate, rate);
    }
}
