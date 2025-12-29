// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/price/rates/ChainlinkRateLib.sol";
import {MultiFeedSumPriceLib} from "@harbor-price/price/prices/MultiFeedSumPriceLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/price/prices/SingleFeedPriceLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice USDE/MAG7.i26 oracle (rate: Chainlink sUSDE/USDE feed, price: (1 USDE in USD) / ((sum of 7 stocks) / index price)).
/// @dev Indexed to 1-1-2026 prices. This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
contract Oracle_USDE_MAG7i26 is HarborPriceAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidIndexPrice(uint256 indexPrice);

    string public BASE_NAME;

    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable BASE_USD_FEED; // USDE/USD feed
    uint8 public immutable BASE_USD_FEED_DECIMALS;
    uint256 public immutable INDEX_PRICE; // Sum of 7 stocks on 1-1-2026
    
    // Individual feed immutables for MAG7 (7 feeds)
    AggregatorV3Interface public immutable FEED_0;
    uint8 public immutable FEED_0_DECIMALS;
    AggregatorV3Interface public immutable FEED_1;
    uint8 public immutable FEED_1_DECIMALS;
    AggregatorV3Interface public immutable FEED_2;
    uint8 public immutable FEED_2_DECIMALS;
    AggregatorV3Interface public immutable FEED_3;
    uint8 public immutable FEED_3_DECIMALS;
    AggregatorV3Interface public immutable FEED_4;
    uint8 public immutable FEED_4_DECIMALS;
    AggregatorV3Interface public immutable FEED_5;
    uint8 public immutable FEED_5_DECIMALS;
    AggregatorV3Interface public immutable FEED_6;
    uint8 public immutable FEED_6_DECIMALS;

    constructor(
        string memory baseName_,
        address rateFeed_,
        address baseUsdFeed_,
        uint256 indexPrice_,
        address feed0_,
        address feed1_,
        address feed2_,
        address feed3_,
        address feed4_,
        address feed5_,
        address feed6_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (baseUsdFeed_ == address(0)) revert InvalidAddress(baseUsdFeed_);
        if (indexPrice_ == 0) revert InvalidIndexPrice(indexPrice_);
        if (feed0_ == address(0)) revert InvalidAddress(feed0_);
        if (feed1_ == address(0)) revert InvalidAddress(feed1_);
        if (feed2_ == address(0)) revert InvalidAddress(feed2_);
        if (feed3_ == address(0)) revert InvalidAddress(feed3_);
        if (feed4_ == address(0)) revert InvalidAddress(feed4_);
        if (feed5_ == address(0)) revert InvalidAddress(feed5_);
        if (feed6_ == address(0)) revert InvalidAddress(feed6_);

        BASE_NAME = baseName_;
        RATE_FEED = AggregatorV3Interface(rateFeed_);
        BASE_USD_FEED = AggregatorV3Interface(baseUsdFeed_);
        BASE_USD_FEED_DECIMALS = BASE_USD_FEED.decimals();
        INDEX_PRICE = indexPrice_;

        FEED_0 = AggregatorV3Interface(feed0_);
        FEED_0_DECIMALS = FEED_0.decimals();
        FEED_1 = AggregatorV3Interface(feed1_);
        FEED_1_DECIMALS = FEED_1.decimals();
        FEED_2 = AggregatorV3Interface(feed2_);
        FEED_2_DECIMALS = FEED_2.decimals();
        FEED_3 = AggregatorV3Interface(feed3_);
        FEED_3_DECIMALS = FEED_3.decimals();
        FEED_4 = AggregatorV3Interface(feed4_);
        FEED_4_DECIMALS = FEED_4.decimals();
        FEED_5 = AggregatorV3Interface(feed5_);
        FEED_5_DECIMALS = FEED_5.decimals();
        FEED_6 = AggregatorV3Interface(feed6_);
        FEED_6_DECIMALS = FEED_6.decimals();
    }

    function base() external view returns (string memory) {
        return BASE_NAME;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_FEED);
    }

    function quoteName() external pure returns (string memory) {
        return "MAG7.i26";
    }

    function oracleName() external pure returns (string memory) {
        return "USDE/MAG7.i26";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

        // Build arrays for MultiFeedSumPriceLib to get sum of 7 stocks
        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](7);
        uint8[] memory decimals = new uint8[](7);
        
        feeds[0] = FEED_0;
        decimals[0] = FEED_0_DECIMALS;
        feeds[1] = FEED_1;
        decimals[1] = FEED_1_DECIMALS;
        feeds[2] = FEED_2;
        decimals[2] = FEED_2_DECIMALS;
        feeds[3] = FEED_3;
        decimals[3] = FEED_3_DECIMALS;
        feeds[4] = FEED_4;
        decimals[4] = FEED_4_DECIMALS;
        feeds[5] = FEED_5;
        decimals[5] = FEED_5_DECIMALS;
        feeds[6] = FEED_6;
        decimals[6] = FEED_6_DECIMALS;

        uint256 currentSum = MultiFeedSumPriceLib.getPrice(feeds, decimals);

        // Indexed value = currentSum / INDEX_PRICE
        uint256 indexedValue = Math.mulDiv(currentSum, 1e18, INDEX_PRICE);

        // Price = (1 USDE in USD) / indexedValue = USDE per MAG7.i26
        // Get USDE/USD price (should be ~1)
        uint256 usdeUsdPrice = SingleFeedPriceLib.getPrice(BASE_USD_FEED, BASE_USD_FEED_DECIMALS, 1, false);
        uint256 price = Math.mulDiv(usdeUsdPrice, 1e18, indexedValue);

        return (price, price, rate, rate);
    }
}

