// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {IFxSAVE} from "@harbor-price/interfaces/IFxSAVE.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {FxSaveRateLib} from "@harbor-price/price/rates/FxSaveRateLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/price/prices/SingleFeedPriceLib.sol";

/// @notice fxUSD/ETH oracle (rate: fxSAVE, price: inverted ETH/USD).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
contract Oracle_fxUSD_ETH is HarborPriceAggregator_v3 {
    using FxSaveRateLib for IFxSAVE;

    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    IFxSAVE public immutable FXSAVE;
    string public BASE_NAME;

    AggregatorV3Interface public immutable PRICE_FEED;
    uint8 public immutable PRICE_FEED_DECIMALS;
    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(string memory baseName_,
        address fxsave_,
        address priceFeed_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (fxsave_ == address(0)) revert InvalidAddress(fxsave_);
        if (priceFeed_ == address(0)) revert InvalidAddress(priceFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        FXSAVE = IFxSAVE(fxsave_);
        BASE_NAME = baseName_;

        PRICE_FEED = AggregatorV3Interface(priceFeed_);
        PRICE_FEED_DECIMALS = PRICE_FEED.decimals();
        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function base() external view returns (string memory) {
        return BASE_NAME;
    }

    function rateProvider() external view returns (address) {
        return address(FXSAVE);
    }

    function quoteName() external pure returns (string memory) {
        return "ETH";
    }

    function oracleName() external pure returns (string memory) {
        return "fxUSD/ETH";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = FXSAVE.getRate();

        uint256 price = SingleFeedPriceLib.getPrice(
            PRICE_FEED,
            PRICE_FEED_DECIMALS,
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        return (price, price, rate, rate);
    }
}
