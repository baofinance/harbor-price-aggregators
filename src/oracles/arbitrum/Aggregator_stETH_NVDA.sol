// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborAggregator_v3} from "@harbor-price/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {DoubleFeedPriceLib} from "@harbor-price/prices/DoubleFeedPriceLib.sol";

/// @notice stETH/NVDA oracle (rate: Chainlink wstETH/stETH feed, price: (stETH/USD)/(NVDA/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_NVDA is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable FIRST_FEED;
    uint8 public immutable FIRST_FEED_DECIMALS;
    uint256 public immutable FIRST_FEED_HEARTBEAT;
    AggregatorV3Interface public immutable SECOND_FEED;
    uint8 public immutable SECOND_FEED_DECIMALS;
    uint256 public immutable SECOND_FEED_HEARTBEAT;

    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address rateFeed_,
        address firstFeed_,
        uint256 firstHeartbeat_,
        address secondFeed_,
        uint256 secondHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (firstFeed_ == address(0)) revert InvalidAddress(firstFeed_);
        if (secondFeed_ == address(0)) revert InvalidAddress(secondFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        RATE_FEED = AggregatorV3Interface(rateFeed_);

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
        return address(RATE_FEED);
    }
    function _baseName() internal pure override returns (string memory) {
        return "stETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "NVDA";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

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
