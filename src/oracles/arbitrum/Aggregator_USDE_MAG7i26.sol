// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborAggregator_v3} from "@harbor-price/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {MultiFeedSumPriceLib} from "@harbor-price/prices/MultiFeedSumPriceLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice USDE/MAG7.i26 oracle (rate: Chainlink sUSDE/USDE feed, price: (1 USDE in USD) / ((sum of 7 stocks) / index price)).
/// @dev Indexed to 1-1-2026 prices. This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_MAG7i26 is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidIndexPrice(uint256 indexPrice);

    struct FeedConfig {
        address feed;
        uint256 heartbeat;
    }

    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable BASE_USD_FEED; // USDE/USD feed
    uint8 public immutable BASE_USD_FEED_DECIMALS;
    uint256 public immutable BASE_USD_FEED_HEARTBEAT;
    uint256 public immutable INDEX_PRICE; // Sum of 7 stocks on 1-1-2026

    // Individual feed immutables for MAG7 (7 feeds)
    AggregatorV3Interface public immutable FEED_0;
    uint8 public immutable FEED_0_DECIMALS;
    uint256 public immutable FEED_0_HEARTBEAT;
    AggregatorV3Interface public immutable FEED_1;
    uint8 public immutable FEED_1_DECIMALS;
    uint256 public immutable FEED_1_HEARTBEAT;
    AggregatorV3Interface public immutable FEED_2;
    uint8 public immutable FEED_2_DECIMALS;
    uint256 public immutable FEED_2_HEARTBEAT;
    AggregatorV3Interface public immutable FEED_3;
    uint8 public immutable FEED_3_DECIMALS;
    uint256 public immutable FEED_3_HEARTBEAT;
    AggregatorV3Interface public immutable FEED_4;
    uint8 public immutable FEED_4_DECIMALS;
    uint256 public immutable FEED_4_HEARTBEAT;
    AggregatorV3Interface public immutable FEED_5;
    uint8 public immutable FEED_5_DECIMALS;
    uint256 public immutable FEED_5_HEARTBEAT;
    AggregatorV3Interface public immutable FEED_6;
    uint8 public immutable FEED_6_DECIMALS;
    uint256 public immutable FEED_6_HEARTBEAT;

    constructor(
        address rateFeed_,
        address baseUsdFeed_,
        uint256 baseUsdFeedHeartbeat_,
        uint256 indexPrice_,
        FeedConfig[7] memory feedConfigs_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (baseUsdFeed_ == address(0)) revert InvalidAddress(baseUsdFeed_);
        if (indexPrice_ == 0) revert InvalidIndexPrice(indexPrice_);

        for (uint256 i = 0; i < 7; i++) {
            if (feedConfigs_[i].feed == address(0)) revert InvalidAddress(feedConfigs_[i].feed);
        }

        RATE_FEED = AggregatorV3Interface(rateFeed_);
        BASE_USD_FEED = AggregatorV3Interface(baseUsdFeed_);
        BASE_USD_FEED_DECIMALS = BASE_USD_FEED.decimals();
        BASE_USD_FEED_HEARTBEAT = baseUsdFeedHeartbeat_;
        INDEX_PRICE = indexPrice_;

        FEED_0 = AggregatorV3Interface(feedConfigs_[0].feed);
        FEED_0_DECIMALS = FEED_0.decimals();
        FEED_0_HEARTBEAT = feedConfigs_[0].heartbeat;
        FEED_1 = AggregatorV3Interface(feedConfigs_[1].feed);
        FEED_1_DECIMALS = FEED_1.decimals();
        FEED_1_HEARTBEAT = feedConfigs_[1].heartbeat;
        FEED_2 = AggregatorV3Interface(feedConfigs_[2].feed);
        FEED_2_DECIMALS = FEED_2.decimals();
        FEED_2_HEARTBEAT = feedConfigs_[2].heartbeat;
        FEED_3 = AggregatorV3Interface(feedConfigs_[3].feed);
        FEED_3_DECIMALS = FEED_3.decimals();
        FEED_3_HEARTBEAT = feedConfigs_[3].heartbeat;
        FEED_4 = AggregatorV3Interface(feedConfigs_[4].feed);
        FEED_4_DECIMALS = FEED_4.decimals();
        FEED_4_HEARTBEAT = feedConfigs_[4].heartbeat;
        FEED_5 = AggregatorV3Interface(feedConfigs_[5].feed);
        FEED_5_DECIMALS = FEED_5.decimals();
        FEED_5_HEARTBEAT = feedConfigs_[5].heartbeat;
        FEED_6 = AggregatorV3Interface(feedConfigs_[6].feed);
        FEED_6_DECIMALS = FEED_6.decimals();
        FEED_6_HEARTBEAT = feedConfigs_[6].heartbeat;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_FEED);
    }

    function _baseName() internal pure override returns (string memory) {
        return "USDE";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "MAG7i26";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

        // Build arrays for MultiFeedSumPriceLib to get sum of 7 stocks
        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](7);
        uint8[] memory decimals = new uint8[](7);
        uint256[] memory heartbeats = new uint256[](7);

        feeds[0] = FEED_0;
        decimals[0] = FEED_0_DECIMALS;
        heartbeats[0] = FEED_0_HEARTBEAT;
        feeds[1] = FEED_1;
        decimals[1] = FEED_1_DECIMALS;
        heartbeats[1] = FEED_1_HEARTBEAT;
        feeds[2] = FEED_2;
        decimals[2] = FEED_2_DECIMALS;
        heartbeats[2] = FEED_2_HEARTBEAT;
        feeds[3] = FEED_3;
        decimals[3] = FEED_3_DECIMALS;
        heartbeats[3] = FEED_3_HEARTBEAT;
        feeds[4] = FEED_4;
        decimals[4] = FEED_4_DECIMALS;
        heartbeats[4] = FEED_4_HEARTBEAT;
        feeds[5] = FEED_5;
        decimals[5] = FEED_5_DECIMALS;
        heartbeats[5] = FEED_5_HEARTBEAT;
        feeds[6] = FEED_6;
        decimals[6] = FEED_6_DECIMALS;
        heartbeats[6] = FEED_6_HEARTBEAT;

        uint256 currentSum = MultiFeedSumPriceLib.getPrice(feeds, decimals, heartbeats);

        // Indexed value = currentSum / INDEX_PRICE
        uint256 indexedValue = Math.mulDiv(currentSum, 1e18, INDEX_PRICE);

        // Price = (1 USDE in USD) / indexedValue = USDE per MAG7.i26
        // Get USDE/USD price (should be ~1)
        uint256 usdeUsdPrice = SingleFeedPriceLib.getPrice(
            BASE_USD_FEED,
            BASE_USD_FEED_DECIMALS,
            BASE_USD_FEED_HEARTBEAT,
            1,
            false
        );
        uint256 price = Math.mulDiv(usdeUsdPrice, 1e18, indexedValue);

        return (price, price, rate, rate);
    }
}
