// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";

/// @notice tBTC/USD oracle (price: tBTC/USD feed).
/// @dev This is the formula contract; wiring (feed/address) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_tBTC_USD is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    AggregatorV3Interface public immutable PRICE_FEED;
    uint8 public immutable PRICE_FEED_DECIMALS;
    uint256 public immutable PRICE_FEED_HEARTBEAT;
    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address priceFeed_,
        uint256 priceHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (priceFeed_ == address(0)) revert InvalidAddress(priceFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        PRICE_FEED = AggregatorV3Interface(priceFeed_);
        PRICE_FEED_DECIMALS = PRICE_FEED.decimals();
        PRICE_FEED_HEARTBEAT = priceHeartbeat_;
        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function rateProvider() external pure returns (address) {
        return address(0);
    }

    function _baseName() internal pure override returns (string memory) {
        return "tBTC";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 price = SingleFeedPriceLib.getPrice(
            PRICE_FEED,
            PRICE_FEED_DECIMALS,
            PRICE_FEED_HEARTBEAT,
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        return (price, price, 0, 0);
    }
}
