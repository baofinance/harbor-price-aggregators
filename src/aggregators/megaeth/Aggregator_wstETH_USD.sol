// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @notice wstETH/USD oracle (rate: Chainlink wstETH/stETH feed, price: rate × ETH/USD).
/// @dev Since 1 stETH = 1 ETH, we use ETH/USD feed. Price = (wstETH/stETH) × (ETH/USD).
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wstETH_USD is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    AggregatorV3Interface public immutable RATE_FEED; // wstETH/stETH
    AggregatorV3Interface public immutable PRICE_FEED; // ETH/USD
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
        return "wstETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        // Rate: wstETH/stETH from Chainlink feed
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

        // Price: wstETH/USD = (wstETH/stETH) × (ETH/USD)
        // Since 1 stETH = 1 ETH, we use ETH/USD feed directly
        uint256 ethUsd = ChainlinkFeedLib.latestAnswerNormalized(PRICE_FEED, PRICE_FEED_DECIMALS, PRICE_FEED_HEARTBEAT);
        
        // Apply divisor and invert if needed
        uint256 feedPrice = ethUsd;
        if (INVERT_PRICE) {
            feedPrice = Math.mulDiv(1e18 * PRICE_DIVISOR, 1e18, feedPrice);
        } else {
            feedPrice = feedPrice / PRICE_DIVISOR;
        }

        // price = rate × feedPrice
        uint256 price = Math.mulDiv(rate, feedPrice, 1e18);

        return (price, price, rate, rate);
    }
}
