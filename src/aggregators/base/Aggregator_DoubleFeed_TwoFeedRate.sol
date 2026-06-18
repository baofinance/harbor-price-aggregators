// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {TwoFeedRatioRateLib} from "@harbor-price/rates/TwoFeedRatioRateLib.sol";
import {DoubleFeedPriceLib} from "@harbor-price/prices/DoubleFeedPriceLib.sol";

/// @notice Oracle with rate from two CL feeds (numerator/denominator) and price from two CL feeds.
/// @dev Use when there is no direct rate feed (e.g. Monad: wstETH/stETH = WSTETH_USD/STETH_USD).
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
abstract contract Aggregator_DoubleFeed_TwoFeedRate is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    AggregatorV3Interface public immutable RATE_NUMERATOR_FEED;
    AggregatorV3Interface public immutable RATE_DENOMINATOR_FEED;
    uint256 public immutable RATE_HEARTBEAT;

    AggregatorV3Interface public immutable FIRST_FEED;
    uint8 public immutable FIRST_FEED_DECIMALS;
    uint256 public immutable FIRST_FEED_HEARTBEAT;
    AggregatorV3Interface public immutable SECOND_FEED;
    uint8 public immutable SECOND_FEED_DECIMALS;
    uint256 public immutable SECOND_FEED_HEARTBEAT;

    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address rateNumFeed_,
        address rateDenomFeed_,
        uint256 rateHeartbeat_,
        address firstFeed_,
        uint256 firstHeartbeat_,
        address secondFeed_,
        uint256 secondHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (rateNumFeed_ == address(0)) revert InvalidAddress(rateNumFeed_);
        if (rateDenomFeed_ == address(0)) revert InvalidAddress(rateDenomFeed_);
        if (firstFeed_ == address(0)) revert InvalidAddress(firstFeed_);
        if (secondFeed_ == address(0)) revert InvalidAddress(secondFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        RATE_NUMERATOR_FEED = AggregatorV3Interface(rateNumFeed_);
        RATE_DENOMINATOR_FEED = AggregatorV3Interface(rateDenomFeed_);
        RATE_HEARTBEAT = rateHeartbeat_;

        FIRST_FEED = AggregatorV3Interface(firstFeed_);
        FIRST_FEED_DECIMALS = FIRST_FEED.decimals();
        FIRST_FEED_HEARTBEAT = firstHeartbeat_;
        SECOND_FEED = AggregatorV3Interface(secondFeed_);
        SECOND_FEED_DECIMALS = SECOND_FEED.decimals();
        SECOND_FEED_HEARTBEAT = secondHeartbeat_;

        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_NUMERATOR_FEED);
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = TwoFeedRatioRateLib.getRate(RATE_NUMERATOR_FEED, RATE_DENOMINATOR_FEED, RATE_HEARTBEAT);
        uint256 price = DoubleFeedPriceLib.getPrice(
            FIRST_FEED,
            FIRST_FEED_DECIMALS,
            FIRST_FEED_HEARTBEAT,
            SECOND_FEED,
            SECOND_FEED_DECIMALS,
            SECOND_FEED_HEARTBEAT,
            PRICE_DIVISOR,
            INVERT_PRICE
        );
        return (price, price, rate, rate);
    }
}
