// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborAggregator_v3} from "@harbor-price/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {MultiFeedNormalizedPriceLib} from "@harbor-price/prices/MultiFeedNormalizedPriceLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice stETH/BOM5 oracle (rate: Chainlink wstETH/stETH feed, price: (stETH/USD) / (normalized basket sum)).
/// @dev BOM5 = Bag of Memes 5 (DOGE, SHIB, PEPE, TRUMP, WIF) with supply normalization.
///      This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_BOM5 is HarborAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidFeedCount(uint256 count);

    struct FeedConfig {
        address feed;
        uint256 heartbeat;
        uint256 normFactor;
    }

    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable BASE_USD_FEED; // stETH/USD feed
    uint8 public immutable BASE_USD_FEED_DECIMALS;
    uint256 public immutable BASE_USD_FEED_HEARTBEAT;

    // Individual feed immutables for BOM5 (5 feeds)
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

    // Normalization factors (18 decimals)
    uint256 public immutable NORM_FACTOR_0;
    uint256 public immutable NORM_FACTOR_1;
    uint256 public immutable NORM_FACTOR_2;
    uint256 public immutable NORM_FACTOR_3;
    uint256 public immutable NORM_FACTOR_4;

    uint256 public constant FEED_COUNT = 5;

    constructor(
        address rateFeed_,
        address baseUsdFeed_,
        uint256 baseUsdFeedHeartbeat_,
        FeedConfig[5] memory feedConfigs_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (baseUsdFeed_ == address(0)) revert InvalidAddress(baseUsdFeed_);

        for (uint256 i = 0; i < 5; i++) {
            if (feedConfigs_[i].feed == address(0)) revert InvalidAddress(feedConfigs_[i].feed);
            if (feedConfigs_[i].normFactor == 0) revert InvalidFeedCount(0);
        }

        RATE_FEED = AggregatorV3Interface(rateFeed_);
        BASE_USD_FEED = AggregatorV3Interface(baseUsdFeed_);
        BASE_USD_FEED_DECIMALS = BASE_USD_FEED.decimals();
        BASE_USD_FEED_HEARTBEAT = baseUsdFeedHeartbeat_;

        FEED_0 = AggregatorV3Interface(feedConfigs_[0].feed);
        FEED_0_DECIMALS = FEED_0.decimals();
        FEED_0_HEARTBEAT = feedConfigs_[0].heartbeat;
        NORM_FACTOR_0 = feedConfigs_[0].normFactor;
        FEED_1 = AggregatorV3Interface(feedConfigs_[1].feed);
        FEED_1_DECIMALS = FEED_1.decimals();
        FEED_1_HEARTBEAT = feedConfigs_[1].heartbeat;
        NORM_FACTOR_1 = feedConfigs_[1].normFactor;
        FEED_2 = AggregatorV3Interface(feedConfigs_[2].feed);
        FEED_2_DECIMALS = FEED_2.decimals();
        FEED_2_HEARTBEAT = feedConfigs_[2].heartbeat;
        NORM_FACTOR_2 = feedConfigs_[2].normFactor;
        FEED_3 = AggregatorV3Interface(feedConfigs_[3].feed);
        FEED_3_DECIMALS = FEED_3.decimals();
        FEED_3_HEARTBEAT = feedConfigs_[3].heartbeat;
        NORM_FACTOR_3 = feedConfigs_[3].normFactor;
        FEED_4 = AggregatorV3Interface(feedConfigs_[4].feed);
        FEED_4_DECIMALS = FEED_4.decimals();
        FEED_4_HEARTBEAT = feedConfigs_[4].heartbeat;
        NORM_FACTOR_4 = feedConfigs_[4].normFactor;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_FEED);
    }

    function _baseName() internal pure override returns (string memory) {
        return "stETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "BOM5";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

        // Get base asset USD price (stETH/USD)
        uint256 baseUsdPrice = SingleFeedPriceLib.getPrice(
            BASE_USD_FEED,
            BASE_USD_FEED_DECIMALS,
            BASE_USD_FEED_HEARTBEAT,
            1,
            false
        );

        // Build arrays for MultiFeedNormalizedPriceLib
        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](5);
        uint8[] memory decimals = new uint8[](5);
        uint256[] memory heartbeats = new uint256[](5);
        uint256[] memory normalizationFactors = new uint256[](5);

        feeds[0] = FEED_0;
        decimals[0] = FEED_0_DECIMALS;
        heartbeats[0] = FEED_0_HEARTBEAT;
        normalizationFactors[0] = NORM_FACTOR_0;
        feeds[1] = FEED_1;
        decimals[1] = FEED_1_DECIMALS;
        heartbeats[1] = FEED_1_HEARTBEAT;
        normalizationFactors[1] = NORM_FACTOR_1;
        feeds[2] = FEED_2;
        decimals[2] = FEED_2_DECIMALS;
        heartbeats[2] = FEED_2_HEARTBEAT;
        normalizationFactors[2] = NORM_FACTOR_2;
        feeds[3] = FEED_3;
        decimals[3] = FEED_3_DECIMALS;
        heartbeats[3] = FEED_3_HEARTBEAT;
        normalizationFactors[3] = NORM_FACTOR_3;
        feeds[4] = FEED_4;
        decimals[4] = FEED_4_DECIMALS;
        heartbeats[4] = FEED_4_HEARTBEAT;
        normalizationFactors[4] = NORM_FACTOR_4;

        uint256 normalizedBasketAverage = MultiFeedNormalizedPriceLib.getPrice(
            feeds,
            decimals,
            heartbeats,
            normalizationFactors
        );

        // Price = (base/USD) / (normalized basket average) = stETH per BOM5 unit
        // Formula: (baseUsdPrice * 1e18) / normalizedBasketAverage
        // Note: normalizedBasketAverage is the average of normalized prices (sum / 5)
        uint256 price = Math.mulDiv(baseUsdPrice, 1e18, normalizedBasketAverage);

        return (price, price, rate, rate);
    }
}
