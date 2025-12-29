// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/price/rates/ChainlinkRateLib.sol";
import {MultiFeedNormalizedPriceLib} from "@harbor-price/price/prices/MultiFeedNormalizedPriceLib.sol";
import {SingleFeedPriceLib} from "@harbor-price/price/prices/SingleFeedPriceLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @notice stETH/BOM5 oracle (rate: Chainlink wstETH/stETH feed, price: (stETH/USD) / (normalized basket sum)).
/// @dev BOM5 = Bag of Memes 5 (DOGE, SHIB, PEPE, TRUMP, WIF) with supply normalization.
///      This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
contract Oracle_stETH_BOM5 is HarborPriceAggregator_v3 {
    error InvalidAddress(address value);
    error InvalidFeedCount(uint256 count);

    string public BASE_NAME;

    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable BASE_USD_FEED; // stETH/USD feed
    uint8 public immutable BASE_USD_FEED_DECIMALS;
    
    // Individual feed immutables for BOM5 (5 feeds)
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
    
    // Normalization factors (18 decimals)
    uint256 public immutable NORM_FACTOR_0;
    uint256 public immutable NORM_FACTOR_1;
    uint256 public immutable NORM_FACTOR_2;
    uint256 public immutable NORM_FACTOR_3;
    uint256 public immutable NORM_FACTOR_4;
    
    uint256 public constant FEED_COUNT = 5;

    constructor(
        string memory baseName_,
        address rateFeed_,
        address baseUsdFeed_,
        address feed0_,
        address feed1_,
        address feed2_,
        address feed3_,
        address feed4_,
        uint256 normFactor0_,
        uint256 normFactor1_,
        uint256 normFactor2_,
        uint256 normFactor3_,
        uint256 normFactor4_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (baseUsdFeed_ == address(0)) revert InvalidAddress(baseUsdFeed_);
        if (feed0_ == address(0)) revert InvalidAddress(feed0_);
        if (feed1_ == address(0)) revert InvalidAddress(feed1_);
        if (feed2_ == address(0)) revert InvalidAddress(feed2_);
        if (feed3_ == address(0)) revert InvalidAddress(feed3_);
        if (feed4_ == address(0)) revert InvalidAddress(feed4_);
        if (normFactor0_ == 0) revert InvalidFeedCount(0);
        if (normFactor1_ == 0) revert InvalidFeedCount(0);
        if (normFactor2_ == 0) revert InvalidFeedCount(0);
        if (normFactor3_ == 0) revert InvalidFeedCount(0);
        if (normFactor4_ == 0) revert InvalidFeedCount(0);

        BASE_NAME = baseName_;
        RATE_FEED = AggregatorV3Interface(rateFeed_);
        BASE_USD_FEED = AggregatorV3Interface(baseUsdFeed_);
        BASE_USD_FEED_DECIMALS = BASE_USD_FEED.decimals();

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
        
        NORM_FACTOR_0 = normFactor0_;
        NORM_FACTOR_1 = normFactor1_;
        NORM_FACTOR_2 = normFactor2_;
        NORM_FACTOR_3 = normFactor3_;
        NORM_FACTOR_4 = normFactor4_;
    }

    function base() external view returns (string memory) {
        return BASE_NAME;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_FEED);
    }

    function quoteName() external pure returns (string memory) {
        return "BOM5";
    }

    function oracleName() external pure returns (string memory) {
        return "stETH/BOM5";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);

        // Get base asset USD price (stETH/USD)
        uint256 baseUsdPrice = SingleFeedPriceLib.getPrice(BASE_USD_FEED, BASE_USD_FEED_DECIMALS, 1, false);

        // Build arrays for MultiFeedNormalizedPriceLib
        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](5);
        uint8[] memory decimals = new uint8[](5);
        uint256[] memory normalizationFactors = new uint256[](5);
        
        feeds[0] = FEED_0;
        decimals[0] = FEED_0_DECIMALS;
        normalizationFactors[0] = NORM_FACTOR_0;
        
        feeds[1] = FEED_1;
        decimals[1] = FEED_1_DECIMALS;
        normalizationFactors[1] = NORM_FACTOR_1;
        
        feeds[2] = FEED_2;
        decimals[2] = FEED_2_DECIMALS;
        normalizationFactors[2] = NORM_FACTOR_2;
        
        feeds[3] = FEED_3;
        decimals[3] = FEED_3_DECIMALS;
        normalizationFactors[3] = NORM_FACTOR_3;
        
        feeds[4] = FEED_4;
        decimals[4] = FEED_4_DECIMALS;
        normalizationFactors[4] = NORM_FACTOR_4;

        uint256 normalizedBasketAverage = MultiFeedNormalizedPriceLib.getPrice(feeds, decimals, normalizationFactors);

        // Price = (base/USD) / (normalized basket average) = stETH per BOM5 unit
        // Formula: (baseUsdPrice * 1e18) / normalizedBasketAverage
        // Note: normalizedBasketAverage is the average of normalized prices (sum / 5)
        uint256 price = Math.mulDiv(baseUsdPrice, 1e18, normalizedBasketAverage);

        return (price, price, rate, rate);
    }
}

