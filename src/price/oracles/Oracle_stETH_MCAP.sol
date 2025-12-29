// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";
import {WstETHRateLib} from "@harbor-price/price/rates/WstETHRateLib.sol";
import {DoubleFeedPriceLib} from "@harbor-price/price/prices/DoubleFeedPriceLib.sol";

/// @notice stETH/MCAP oracle (rate: wstETH, price: (ETH/USD)/(MCAP/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
contract Oracle_stETH_MCAP is HarborPriceAggregator_v3 {
    using WstETHRateLib for IWstETH;

    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    IWstETH public immutable WSTETH;
    string public BASE_NAME;

    AggregatorV3Interface public immutable FIRST_FEED;
    uint8 public immutable FIRST_FEED_DECIMALS;
    AggregatorV3Interface public immutable SECOND_FEED;
    uint8 public immutable SECOND_FEED_DECIMALS;

    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        string memory baseName_,
        address wsteth_,
        address firstFeed_,
        address secondFeed_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (wsteth_ == address(0)) revert InvalidAddress(wsteth_);
        if (firstFeed_ == address(0)) revert InvalidAddress(firstFeed_);
        if (secondFeed_ == address(0)) revert InvalidAddress(secondFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        BASE_NAME = baseName_;
        WSTETH = IWstETH(wsteth_);

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
            SECOND_FEED,
            SECOND_FEED_DECIMALS,
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        return (price, price, rate, rate);
    }
}
