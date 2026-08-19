// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DoubleFeedPriceLib} from "@harbor-price/prices/DoubleFeedPriceLib.sol";

/// @notice Oracle with two price feeds and fixed rate 1e18 (e.g. MON/BTC, MON/ETH, MON/XAU).
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
abstract contract Aggregator_DoubleFeed_NoRate is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    uint256 public constant FIXED_RATE = 1e18;

    AggregatorV3Interface public immutable FIRST_FEED;
    uint8 public immutable FIRST_FEED_DECIMALS;
    uint256 public immutable FIRST_FEED_HEARTBEAT;
    AggregatorV3Interface public immutable SECOND_FEED;
    uint8 public immutable SECOND_FEED_DECIMALS;
    uint256 public immutable SECOND_FEED_HEARTBEAT;
    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address firstFeed_,
        uint256 firstHeartbeat_,
        address secondFeed_,
        uint256 secondHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (firstFeed_ == address(0)) revert InvalidAddress(firstFeed_);
        if (secondFeed_ == address(0)) revert InvalidAddress(secondFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        FIRST_FEED = AggregatorV3Interface(firstFeed_);
        FIRST_FEED_DECIMALS = FIRST_FEED.decimals();
        FIRST_FEED_HEARTBEAT = firstHeartbeat_;
        SECOND_FEED = AggregatorV3Interface(secondFeed_);
        SECOND_FEED_DECIMALS = SECOND_FEED.decimals();
        SECOND_FEED_HEARTBEAT = secondHeartbeat_;
        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function rateProvider() external pure returns (address) {
        return address(0);
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
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
        return (price, price, FIXED_RATE, FIXED_RATE);
    }
}
