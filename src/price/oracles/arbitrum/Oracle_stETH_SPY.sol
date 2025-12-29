// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/price/rates/ChainlinkRateLib.sol";
import {DoubleFeedPriceLib} from "@harbor-price/price/prices/DoubleFeedPriceLib.sol";

/// @notice stETH/SPY oracle (rate: Chainlink wstETH/stETH feed, price: (stETH/USD)/(SPY/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
contract Oracle_stETH_SPY is HarborPriceAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    string public BASE_NAME;

    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable FIRST_FEED;
    uint8 public immutable FIRST_FEED_DECIMALS;
    AggregatorV3Interface public immutable SECOND_FEED;
    uint8 public immutable SECOND_FEED_DECIMALS;

    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        string memory baseName_,
        address rateFeed_,
        address firstFeed_,
        address secondFeed_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (firstFeed_ == address(0)) revert InvalidAddress(firstFeed_);
        if (secondFeed_ == address(0)) revert InvalidAddress(secondFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        BASE_NAME = baseName_;
        RATE_FEED = AggregatorV3Interface(rateFeed_);

        FIRST_FEED = AggregatorV3Interface(firstFeed_);
        FIRST_FEED_DECIMALS = FIRST_FEED.decimals();
        SECOND_FEED = AggregatorV3Interface(secondFeed_);
        SECOND_FEED_DECIMALS = SECOND_FEED.decimals();

        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function base() external view returns (string memory) {
        return BASE_NAME;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_FEED);
    }

    function quoteName() external pure returns (string memory) {
        return "SPY";
    }

    function oracleName() external pure returns (string memory) {
        return "stETH/SPY";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

        uint256 price = DoubleFeedPriceLib.getPrice(
            FIRST_FEED,
            FIRST_FEED_DECIMALS,
            SECOND_FEED,
            SECOND_FEED_DECIMALS,
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        return (price, price, rate, rate);
    }
}

