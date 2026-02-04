// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @notice wBTC/USD oracle (price: (wBTC/BTC) * (BTC/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wBTC_USD is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    AggregatorV3Interface public immutable FIRST_FEED; // wBTC/BTC
    uint8 public immutable FIRST_FEED_DECIMALS;
    uint256 public immutable FIRST_FEED_HEARTBEAT;
    AggregatorV3Interface public immutable SECOND_FEED; // BTC/USD
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

    function _baseName() internal pure override returns (string memory) {
        return "wBTC";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        // wBTC/USD = (wBTC/BTC) * (BTC/USD)
        // We need to multiply, but DoubleFeedPriceLib divides, so we compute manually
        uint256 wbtcBtc = ChainlinkFeedLib.latestAnswerNormalized(FIRST_FEED, FIRST_FEED_DECIMALS, FIRST_FEED_HEARTBEAT);
        uint256 btcUsd = ChainlinkFeedLib.latestAnswerNormalized(SECOND_FEED, SECOND_FEED_DECIMALS, SECOND_FEED_HEARTBEAT);
        
        // price = (wBTC/BTC) * (BTC/USD) / divisor
        uint256 price = Math.mulDiv(wbtcBtc, btcUsd, PRICE_DIVISOR);

        return (price, price, 0, 0);
    }
}
