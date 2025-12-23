// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";
import {WstETHRateLib} from "@harbor-price/price/rates/WstETHRateLib.sol";
import {DoubleFeedPriceLib} from "@harbor-price/price/prices/DoubleFeedPriceLib.sol";
import {PriceOracle_v1} from "@harbor-price/price/PriceOracle_v1.sol";

/// @notice stETH/MCAP oracle (rate: wstETH, price: (ETH/USD)/(MCAP/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
contract Oracle_stETH_MCAP is HarborPriceAggregator_v3 {
    using WstETHRateLib for IWstETH;

    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    IWstETH public immutable WSTETH;
    address public immutable BASE;

    AggregatorV3Interface public immutable FIRST_FEED;
    uint8 public immutable FIRST_FEED_DECIMALS;
    AggregatorV3Interface public immutable SECOND_FEED;
    uint8 public immutable SECOND_FEED_DECIMALS;

    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    uint64 public immutable FIRST_MAX_ANSWER_AGE;
    uint256 public immutable FIRST_MAX_PERCENT_DEVIATION;
    uint64 public immutable SECOND_MAX_ANSWER_AGE;
    uint256 public immutable SECOND_MAX_PERCENT_DEVIATION;

    constructor(
        address steth_,
        address wsteth_,
        address firstFeed_,
        address secondFeed_,
        uint256 priceDivisor_,
        bool invertPrice_,
        uint64 firstMaxAnswerAge_,
        uint256 firstMaxPercentDeviation_,
        uint64 secondMaxAnswerAge_,
        uint256 secondMaxPercentDeviation_
    ) {
        if (steth_ == address(0)) revert InvalidAddress(steth_);
        if (wsteth_ == address(0)) revert InvalidAddress(wsteth_);
        if (firstFeed_ == address(0)) revert InvalidAddress(firstFeed_);
        if (secondFeed_ == address(0)) revert InvalidAddress(secondFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        BASE = steth_;
        WSTETH = IWstETH(wsteth_);

        FIRST_FEED = AggregatorV3Interface(firstFeed_);
        FIRST_FEED_DECIMALS = FIRST_FEED.decimals();
        SECOND_FEED = AggregatorV3Interface(secondFeed_);
        SECOND_FEED_DECIMALS = SECOND_FEED.decimals();

        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;

        FIRST_MAX_ANSWER_AGE = firstMaxAnswerAge_;
        FIRST_MAX_PERCENT_DEVIATION = firstMaxPercentDeviation_;
        SECOND_MAX_ANSWER_AGE = secondMaxAnswerAge_;
        SECOND_MAX_PERCENT_DEVIATION = secondMaxPercentDeviation_;
    }

    function base() external view returns (address) {
        return BASE;
    }

    function rateProvider() external view returns (address) {
        return address(WSTETH);
    }

    function quoteName() external pure returns (string memory) {
        return "MCAP";
    }

    function oracleName() external pure returns (string memory) {
        return "stETH/MCAP";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = WSTETH.getRate();

        uint256 price = DoubleFeedPriceLib.getPrice(
            FIRST_FEED,
            FIRST_FEED_DECIMALS,
            PriceOracle_v1.Constraints({
                maxAnswerAge: FIRST_MAX_ANSWER_AGE,
                maxPercentageDeviation: FIRST_MAX_PERCENT_DEVIATION,
                maxAbsoluteDeviation: type(uint256).max,
                maxTrendReversalDeviation: type(uint256).max
            }),
            SECOND_FEED,
            SECOND_FEED_DECIMALS,
            PriceOracle_v1.Constraints({
                maxAnswerAge: SECOND_MAX_ANSWER_AGE,
                maxPercentageDeviation: SECOND_MAX_PERCENT_DEVIATION,
                maxAbsoluteDeviation: type(uint256).max,
                maxTrendReversalDeviation: type(uint256).max
            }),
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        return (price, price, rate, rate);
    }
}
