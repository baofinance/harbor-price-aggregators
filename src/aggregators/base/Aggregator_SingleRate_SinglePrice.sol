// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";

/// @notice Oracle with rate from one CL feed and price from one feed; reported price = rate * priceFeed (e.g. shMON/USD).
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
abstract contract Aggregator_SingleRate_SinglePrice is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

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

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);
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
