// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuardTransientUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BaoOwnable} from "@bao/BaoOwnable.sol";
import {IFxSAVE} from "src/interfaces/IFxSAVE.sol";
import {PriceOracle_v1} from "./PriceOracle_v1.sol";
import {IWrappedPriceOracle} from "src/interfaces/IWrappedPriceOracle.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";

/// @title Harbor Custom Feed with Per-Feed Normalization V2
/// @notice Generic oracle for custom feed aggregations with per-feed normalization factors
/// @dev Each feed can have its own normalization factor applied before aggregation
///      V2: Price calculation does NOT multiply by rate - uses feed prices directly
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract HarborCustomFeedNormalization_v2 is
    IWrappedPriceOracle,
    UUPSUpgradeable,
    ReentrancyGuardTransientUpgradeable,
    BaoOwnable
{
    using PriceOracle_v1 for PriceOracle_v1.Feed;

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    enum RateSource {
        WSTETH,
        FXSAVE,
        SUSDE_CHAINLINK,
        WSTETH_CHAINLINK
    }

    /*//////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice wstETH contract address (if using wstETH rate source)
    address public immutable WSTETH;

    /// @notice fxsave contract address (if using fxsave rate source)
    IFxSAVE public immutable FXSAVE;

    /// @notice sUSDE/USDE Chainlink feed address (if using SUSDE_CHAINLINK rate source)
    address public immutable SUSDE_USDE_FEED;

    /// @notice wstETH/stETH Chainlink feed address (if using WSTETH_CHAINLINK rate source)
    address public immutable WSTETH_STETH_FEED;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Oracle name/description
    string public oracleName;

    /// @notice Rate source configuration
    RateSource public rateSource;

    /// @notice Array of custom feed addresses (e.g., DOGE/USD, SHIB/USD, PEPE/USD, TRUMP/USD, WIF/USD)
    address[] public customFeeds;

    /// @notice USD feed address for final conversion
    address public usdFeed;

    /// @notice Divisor for aggregated price normalization after summing (e.g., 5 for average of 5 feeds)
    uint256 public aggregationDivisor;

    /// @notice Normalization factor for each feed (in 18 decimals)
    /// @dev For factors >= 1e18: divide price by factor (e.g., 168.2e18 means divide by 168.2)
    ///      For factors < 1e18: multiply price by (1e18 / factor) (e.g., 0.2e18 means multiply by 5)
    mapping(address => uint256) public feedNormalizationFactors;

    /// @notice Decimals of USD feed
    uint8 public usdFeedDecimals;

    /// @notice Decimals of each custom feed (indexed by feed position)
    mapping(address => uint8) public feedDecimals;

    /// @notice Feed validation constraints
    mapping(address => PriceOracle_v1.Constraints) public feedConstraints;

    /// @notice Numeric identifiers for feeds (1+ = custom feeds, 100 = USD feed)
    mapping(uint8 => address) public feedIdentifiers;

    /// @notice Maximum age for rate source feeds (configurable, defaults to 1 day)
    /// @dev Only applies to Chainlink rate sources (SUSDE_CHAINLINK, WSTETH_CHAINLINK)
    ///      Direct contract calls (WSTETH, FXSAVE) are always current
    uint64 public maxRateSourceAge = 1 days;

    /// @notice Whether to invert the price conversion (default: false)
    /// @dev When true, converts from aggregated custom feeds to USD instead of USD to aggregated custom feeds
    bool public invertPrice;

    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidPriceSource(address source);
    error InvalidRateSource(address source);
    error InvalidMaxPriceAge(uint64 value);
    error InvalidMaxRelativeDeviation(uint256 value);
    error InvalidFeedDecimals(address source);
    error InvalidPrice(address source, int256 answer);
    error InvalidRate(uint256 rate);
    error InvalidFeedIdentifier(uint8 identifier);
    error ConstraintsNotSet(address feed);
    error InvalidRateSourceConfig();
    error StaleRateSource(address source, uint256 updatedAt);
    error EmptyCustomFeeds();
    error InvalidCustomFeedCount(uint256 count);
    error InvalidAggregationDivisor(uint256 divisor);
    error InvalidNormalizationFactor(address feed, uint256 factor);
    error NormalizationFactorMismatch(uint256 feedsLength, uint256 factorsLength);

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the contract is initialized
    /// @param owner The owner address
    event Initialized(address indexed owner);

    /// @notice Emitted when the contract is upgraded
    /// @param newImplementation The new implementation address
    event Upgraded(address indexed newImplementation);

    /// @notice Emitted when constraints for a feed are updated
    /// @param feed The feed address
    /// @param maxAge New maximum age in seconds
    /// @param maxDev New maximum deviation (1e18 precision)
    event ConstraintsUpdated(address indexed feed, uint64 maxAge, uint256 maxDev);

    /// @notice Emitted when max rate source age is updated
    /// @param maxAge New maximum age in seconds
    event MaxRateSourceAgeUpdated(uint64 maxAge);

    /// @notice Emitted when price inversion setting is updated
    /// @param invertPrice New inversion setting
    event InvertPriceUpdated(bool invertPrice);

    /// @notice Emitted when normalization factor for a feed is updated
    /// @param feed The feed address
    /// @param factor New normalization factor (18 decimals)
    event NormalizationFactorUpdated(address indexed feed, uint256 factor);

    /// @notice Constructor sets immutable values and disables initializers
    /// @param wsteth_ wstETH contract address
    /// @param fxsave_ fxsave contract address
    /// @param susdeUsdeFeed_ sUSDE/USDE Chainlink feed address
    /// @param wstethStethFeed_ wstETH/stETH Chainlink feed address
    constructor(address wsteth_, address fxsave_, address susdeUsdeFeed_, address wstethStethFeed_) {
        _disableInitializers();
        WSTETH = wsteth_;
        FXSAVE = IFxSAVE(fxsave_);
        SUSDE_USDE_FEED = susdeUsdeFeed_;
        WSTETH_STETH_FEED = wstethStethFeed_;
    }

    /*//////////////////////////////////////////////////////////////
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes upgradeability and ownership (proxy)
    /// @param owner_ The owner address
    /// @param oracleName_ The oracle name/description
    /// @param rateSource_ Rate source (0 = wstETH, 1 = fxsave, etc.)
    /// @param customFeeds_ Array of custom feed addresses (e.g., meme coin price feeds)
    /// @param normalizationFactors_ Array of normalization factors (one per feed, in 18 decimals)
    /// @param usdFeed_ USD feed address for final conversion
    /// @param aggregationDivisor_ Divisor for aggregated price normalization after summing (e.g., 5)
    /// @param customFeedMaxAge_ Max age for custom feeds (seconds)
    /// @param customFeedMaxDev_ Max deviation for custom feeds (1e18)
    /// @param usdFeedMaxAge_ Max age for USD feed (seconds)
    /// @param usdFeedMaxDev_ Max deviation for USD feed (1e18)
    /// @param invertPrice_ Whether to invert the price conversion (default: false)
    function initialize(
        address owner_,
        string memory oracleName_,
        RateSource rateSource_,
        address[] memory customFeeds_,
        uint256[] memory normalizationFactors_,
        address usdFeed_,
        uint256 aggregationDivisor_,
        uint64 customFeedMaxAge_,
        uint256 customFeedMaxDev_,
        uint64 usdFeedMaxAge_,
        uint256 usdFeedMaxDev_,
        bool invertPrice_
    ) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuardTransient_init();
        _initializeOwner(owner_);

        // Validate inputs
        if (bytes(oracleName_).length == 0) revert("Invalid oracle name");
        if (customFeeds_.length == 0) revert EmptyCustomFeeds();
        if (customFeeds_.length > 50) revert InvalidCustomFeedCount(customFeeds_.length);
        if (customFeeds_.length != normalizationFactors_.length)
            revert NormalizationFactorMismatch(customFeeds_.length, normalizationFactors_.length);
        if (usdFeed_ == address(0)) revert InvalidPriceSource(usdFeed_);
        if (aggregationDivisor_ == 0) revert InvalidAggregationDivisor(aggregationDivisor_);
        if (customFeedMaxAge_ == 0) revert InvalidMaxPriceAge(customFeedMaxAge_);
        if (usdFeedMaxAge_ == 0) revert InvalidMaxPriceAge(usdFeedMaxAge_);
        if (customFeedMaxDev_ == 0 || customFeedMaxDev_ > 1e18) revert InvalidMaxRelativeDeviation(customFeedMaxDev_);
        if (usdFeedMaxDev_ == 0 || usdFeedMaxDev_ > 1e18) revert InvalidMaxRelativeDeviation(usdFeedMaxDev_);

        // Validate rate source configuration
        if (rateSource_ == RateSource.WSTETH && WSTETH == address(0)) revert InvalidRateSource(WSTETH);
        if (rateSource_ == RateSource.FXSAVE && address(FXSAVE) == address(0))
            revert InvalidRateSource(address(FXSAVE));
        if (rateSource_ == RateSource.SUSDE_CHAINLINK && SUSDE_USDE_FEED == address(0))
            revert InvalidRateSource(SUSDE_USDE_FEED);
        if (rateSource_ == RateSource.WSTETH_CHAINLINK && WSTETH_STETH_FEED == address(0))
            revert InvalidRateSource(WSTETH_STETH_FEED);

        // Set storage variables
        oracleName = oracleName_;
        rateSource = rateSource_;
        customFeeds = customFeeds_;
        usdFeed = usdFeed_;
        aggregationDivisor = aggregationDivisor_;
        invertPrice = invertPrice_;

        // Validate and set custom feeds with normalization factors
        for (uint256 i = 0; i < customFeeds_.length; i++) {
            address feed = customFeeds_[i];
            uint256 factor = normalizationFactors_[i];

            if (feed == address(0)) revert InvalidPriceSource(feed);
            if (factor == 0) revert InvalidNormalizationFactor(feed, factor);

            AggregatorV3Interface feedInterface = AggregatorV3Interface(feed);
            uint8 feedDecimalsValue = feedInterface.decimals();
            if (feedDecimalsValue == 0) revert InvalidFeedDecimals(feed);

            feedDecimals[feed] = feedDecimalsValue;
            feedNormalizationFactors[feed] = factor;
            feedIdentifiers[uint8(i + 1)] = feed;
        }

        // Validate and set USD feed
        AggregatorV3Interface usdFeedInterface = AggregatorV3Interface(usdFeed_);
        uint8 usdDecimals = usdFeedInterface.decimals();
        if (usdDecimals == 0) revert InvalidFeedDecimals(usdFeed_);
        usdFeedDecimals = usdDecimals;
        feedIdentifiers[100] = usdFeed_;

        // Set initial constraints for all feeds
        for (uint256 i = 0; i < customFeeds_.length; i++) {
            _setFeedConstraints(customFeeds_[i], customFeedMaxAge_, customFeedMaxDev_);
        }
        _setFeedConstraints(usdFeed_, usdFeedMaxAge_, usdFeedMaxDev_);

        emit Initialized(owner_);
    }

    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        emit Upgraded(newImpl);
    }

    /*//////////////////////////////////////////////////////////////
                            ORACLE INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IWrappedPriceOracle
    /// @notice Returns validated oracle price information
    /// @dev Returns (price, price, rate, rate) for compatibility with IWrappedPriceOracle interface
    ///      First two values are the final normalized price, always 18 decimals
    ///      Last two values are the raw rate (wstETH/stETH conversion rate), always 18 decimals
    ///      Min/max values are identical as this oracle provides deterministic pricing
    /// @return minUnderlyingPrice The validated min price, 18 decimals
    /// @return maxUnderlyingPrice The validated max price, 18 decimals
    /// @return minWrappedRate The min rate (wstETH/stETH conversion rate), 18 decimals
    /// @return maxWrappedRate The max rate (wstETH/stETH conversion rate), 18 decimals
    function latestAnswer() external view returns (uint256, uint256, uint256, uint256) {
        uint256 price = _getPrice();
        uint256 rate = _getRate();
        return (price, price, rate, rate);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the current price
    /// @dev Uses internal logic to avoid external call overhead
    /// @return price The current price, always 18 decimals
    function getPrice() external view returns (uint256 price) {
        price = _getPrice();
    }

    /// @notice Get the current rate from the configured rate source
    /// @return rate The current rate (wstETH/stETH, fxSAVE/assets, etc.), always 18 decimals
    function getRate() external view returns (uint256 rate) {
        return _getRate();
    }

    /// @notice Get the normalized price for a specific feed address
    /// @param feedAddress The address of the custom feed to query
    /// @return normalizedPrice The normalized price for the feed (after applying normalization factor), always 18 decimals
    function getNormalizedFeedPrice(address feedAddress) external view returns (uint256 normalizedPrice) {
        // Check if feed is in customFeeds array
        bool isCustomFeed = false;
        for (uint256 i = 0; i < customFeeds.length; i++) {
            if (customFeeds[i] == feedAddress) {
                isCustomFeed = true;
                break;
            }
        }
        if (!isCustomFeed) revert InvalidPriceSource(feedAddress);

        // Validate constraints are set
        if (feedConstraints[feedAddress].maxAnswerAge == 0) revert ConstraintsNotSet(feedAddress);

        // Get feed price
        AggregatorV3Interface feedInterface = AggregatorV3Interface(feedAddress);
        PriceOracle_v1.Feed memory feedData = PriceOracle_v1.Feed({
            priceFeed: feedInterface,
            decimals: feedDecimals[feedAddress]
        });

        uint256 feedPrice = feedData.latestAnswer(feedConstraints[feedAddress]);
        // forge-lint: disable-next-line(unsafe-typecast) // Safe: only checking for zero
        if (feedPrice == 0) revert InvalidPrice(feedAddress, int256(feedPrice));

        // Apply normalization factor
        uint256 normalizationFactor = feedNormalizationFactors[feedAddress];
        normalizedPrice = Math.mulDiv(feedPrice, normalizationFactor, 1e18);

        return normalizedPrice;
    }

    /// @notice Get the number of custom feeds
    function getCustomFeedCount() external view returns (uint256) {
        return customFeeds.length;
    }

    /// @notice Get the normalized aggregated price (average of all normalized feed prices)
    /// @dev This returns the average normalized price of all custom feeds, before the final USD feed conversion
    /// @return normalizedAggregatedPrice The average normalized price (18 decimals)
    function getNormalizedAggregatedPrice() external view returns (uint256 normalizedAggregatedPrice) {
        // Validate all constraints are set
        for (uint256 i = 0; i < customFeeds.length; i++) {
            if (feedConstraints[customFeeds[i]].maxAnswerAge == 0) revert ConstraintsNotSet(customFeeds[i]);
        }

        // Aggregate all custom feed prices with per-feed normalization
        uint256 aggregatedPrice = 0;

        for (uint256 i = 0; i < customFeeds.length; i++) {
            address feed = customFeeds[i];
            AggregatorV3Interface feedInterface = AggregatorV3Interface(feed);
            PriceOracle_v1.Feed memory feedData = PriceOracle_v1.Feed({
                priceFeed: feedInterface,
                decimals: feedDecimals[feed]
            });

            uint256 feedPrice = feedData.latestAnswer(feedConstraints[feed]);
            // forge-lint: disable-next-line(unsafe-typecast) // Safe: only checking for zero
            if (feedPrice == 0) revert InvalidPrice(feed, int256(feedPrice));

            // Apply normalization factor
            uint256 normalizationFactor = feedNormalizationFactors[feed];
            uint256 normalizedPrice = Math.mulDiv(feedPrice, normalizationFactor, 1e18);

            aggregatedPrice += normalizedPrice;
        }

        // Divide aggregated price by divisor to get average
        normalizedAggregatedPrice = aggregatedPrice / aggregationDivisor;
    }

    /// @notice Internal function to get the current price
    /// @dev V2: Price does NOT multiply by rate - uses feed prices directly with per-feed normalization
    ///      Formula when invertPrice=false: (usdFeedPrice * 1e18) / normalizedAggregatedPrice
    ///      Formula when invertPrice=true: (normalizedAggregatedPrice * 1e18) / usdFeedPrice
    /// @return price The current price, always 18 decimals
    function _getPrice() internal view returns (uint256 price) {
        // Validate all constraints are set
        for (uint256 i = 0; i < customFeeds.length; i++) {
            if (feedConstraints[customFeeds[i]].maxAnswerAge == 0) revert ConstraintsNotSet(customFeeds[i]);
        }
        if (feedConstraints[usdFeed].maxAnswerAge == 0) revert ConstraintsNotSet(usdFeed);

        // Aggregate all custom feed prices with per-feed normalization
        uint256 aggregatedPrice = 0;
        AggregatorV3Interface usdFeedInterface = AggregatorV3Interface(usdFeed);

        for (uint256 i = 0; i < customFeeds.length; i++) {
            address feed = customFeeds[i];
            AggregatorV3Interface feedInterface = AggregatorV3Interface(feed);
            PriceOracle_v1.Feed memory feedData = PriceOracle_v1.Feed({
                priceFeed: feedInterface,
                decimals: feedDecimals[feed]
            });

            uint256 feedPrice = feedData.latestAnswer(feedConstraints[feed]);
            // forge-lint: disable-next-line(unsafe-typecast) // Safe: only checking for zero
            if (feedPrice == 0) revert InvalidPrice(feed, int256(feedPrice));

            // Apply normalization factor
            // Factor represents the multiplier to normalize to WIF supply
            // Formula: normalizedPrice = (feedPrice * normalizationFactor) / 1e18
            // - For multiplication (factor >= 1e18): e.g., price * 168.2 = price * 168.2e18 / 1e18 ✓
            // - For multiplication (factor < 1e18): e.g., price * 5 = price * 5e18 / 1e18, but stored as 0.2e18 (1/5) requires inverse
            // Since we store multipliers directly, use: normalizedPrice = (feedPrice * normalizationFactor) / 1e18
            uint256 normalizationFactor = feedNormalizationFactors[feed];
            uint256 normalizedPrice = Math.mulDiv(feedPrice, normalizationFactor, 1e18);

            aggregatedPrice += normalizedPrice;
        }

        // Divide aggregated price by divisor to get average
        uint256 normalizedAggregatedPrice = aggregatedPrice / aggregationDivisor;

        // Get USD feed price
        PriceOracle_v1.Feed memory usdFeedData = PriceOracle_v1.Feed({
            priceFeed: usdFeedInterface,
            decimals: usdFeedDecimals
        });

        uint256 usdFeedPrice = usdFeedData.latestAnswer(feedConstraints[usdFeed]);
        // forge-lint: disable-next-line(unsafe-typecast) // Safe: only checking for zero
        if (usdFeedPrice == 0) revert InvalidPrice(usdFeed, int256(usdFeedPrice));

        uint256 finalPrice;
        if (invertPrice) {
            // Invert: Calculate units of USD per 1 aggregated basket
            // Formula: (normalizedAggregatedPrice * 1e18) / usdFeedPrice
            finalPrice = Math.mulDiv(normalizedAggregatedPrice, 1e18, usdFeedPrice);
        } else {
            // Direct: Calculate units of aggregated basket per 1 USD
            // Formula: (usdFeedPrice * 1e18) / normalizedAggregatedPrice
            finalPrice = Math.mulDiv(usdFeedPrice, 1e18, normalizedAggregatedPrice);
        }

        return finalPrice;
    }

    function _getRate() internal view returns (uint256) {
        if (rateSource == RateSource.WSTETH) {
            // For wstETH, get the conversion rate from wstETH to stETH
            uint256 rate = IWstETH(WSTETH).getStETHByWstETH(1e18);
            // Validate rate is within sane bounds (wstETH/stETH should be between 1.0 and 2.0)
            if (rate < 1e18 || rate > 2e18) revert InvalidRate(rate);
            return rate;
        } else if (rateSource == RateSource.FXSAVE) {
            // For fxsave, get the conversion rate
            uint256 rate = FXSAVE.convertToAssets(1e18);
            // Validate rate is within sane bounds (fxSAVE should be >= 0.9x underlying)
            if (rate < 9e17) revert InvalidRate(rate);
            return rate;
        } else if (rateSource == RateSource.SUSDE_CHAINLINK) {
            // For SUSDE_CHAINLINK, get the sUSDE/USDE rate from Chainlink feed
            AggregatorV3Interface feed = AggregatorV3Interface(SUSDE_USDE_FEED);
            uint8 rateFeedDecimals = feed.decimals();
            (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();

            // Validate answer is positive
            if (answer <= 0) revert InvalidPrice(SUSDE_USDE_FEED, answer);

            // Validate feed is not stale (uses configurable maxRateSourceAge)
            // slither-disable-next-line timestamp
            if (block.timestamp - updatedAt > maxRateSourceAge) revert StaleRateSource(SUSDE_USDE_FEED, updatedAt);

            // Normalize to 18 decimals
            uint256 rate;
            if (rateFeedDecimals <= 18) {
                rate = uint256(answer) * (10 ** (18 - rateFeedDecimals));
            } else {
                rate = uint256(answer) / (10 ** (rateFeedDecimals - 18));
            }

            // Validate rate is within sane bounds (sUSDE/USDE should be >= 0.9x)
            if (rate < 9e17) revert InvalidRate(rate);
            return rate;
        } else {
            // For WSTETH_CHAINLINK, get the wstETH/stETH rate from Chainlink feed
            AggregatorV3Interface feed = AggregatorV3Interface(WSTETH_STETH_FEED);
            uint8 rateFeedDecimals = feed.decimals();
            (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();

            // Validate answer is positive
            if (answer <= 0) revert InvalidPrice(WSTETH_STETH_FEED, answer);

            // Validate feed is not stale (uses configurable maxRateSourceAge)
            // slither-disable-next-line timestamp
            if (block.timestamp - updatedAt > maxRateSourceAge) revert StaleRateSource(WSTETH_STETH_FEED, updatedAt);

            // Normalize to 18 decimals
            uint256 rate;
            if (rateFeedDecimals <= 18) {
                rate = uint256(answer) * (10 ** (18 - rateFeedDecimals));
            } else {
                rate = uint256(answer) / (10 ** (rateFeedDecimals - 18));
            }

            // Validate rate is within sane bounds (wstETH/stETH should be between 1.0 and 2.0)
            if (rate < 1e18 || rate > 2e18) revert InvalidRate(rate);
            return rate;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice Set constraints for a specific feed by identifier (1+ = custom feeds, 100 = USD feed)
    function setFeedConstraints(uint8 identifier, uint64 maxAge, uint256 maxDev) external onlyOwner {
        address feed = feedIdentifiers[identifier];
        if (feed == address(0)) revert InvalidFeedIdentifier(identifier);
        _setFeedConstraints(feed, maxAge, maxDev);
    }

    /// @notice Update constraints for all feeds in one call
    function updateFeedConstraints(
        uint64 customFeedMaxAge,
        uint256 customFeedMaxDev,
        uint64 usdFeedMaxAge,
        uint256 usdFeedMaxDev
    ) external onlyOwner {
        for (uint256 i = 0; i < customFeeds.length; i++) {
            _setFeedConstraints(customFeeds[i], customFeedMaxAge, customFeedMaxDev);
        }
        _setFeedConstraints(usdFeed, usdFeedMaxAge, usdFeedMaxDev);
    }

    /// @notice Update normalization factor for a specific feed
    /// @param feed The feed address
    /// @param factor New normalization factor (18 decimals, >= 1e18 for division, < 1e18 for multiplication)
    function setNormalizationFactor(address feed, uint256 factor) external onlyOwner {
        bool isCustomFeed = false;
        for (uint256 i = 0; i < customFeeds.length; i++) {
            if (customFeeds[i] == feed) {
                isCustomFeed = true;
                break;
            }
        }
        if (!isCustomFeed) revert InvalidPriceSource(feed);
        if (factor == 0) revert InvalidNormalizationFactor(feed, factor);

        feedNormalizationFactors[feed] = factor;
        emit NormalizationFactorUpdated(feed, factor);
    }

    /// @notice Update max rate source age
    function setMaxRateSourceAge(uint64 maxAge) external onlyOwner {
        if (maxAge == 0) revert InvalidMaxPriceAge(maxAge);
        maxRateSourceAge = maxAge;
        emit MaxRateSourceAgeUpdated(maxAge);
    }

    /// @notice Update price inversion setting
    /// @param invertPrice_ New inversion setting
    function setInvertPrice(bool invertPrice_) external onlyOwner {
        invertPrice = invertPrice_;
        emit InvertPriceUpdated(invertPrice_);
    }

    /// @dev Internal setter with validation and event emission
    function _setFeedConstraints(address feed, uint64 maxAge, uint256 maxDev) internal {
        // Validate feed exists
        bool isValidFeed = (feed == usdFeed);
        if (!isValidFeed) {
            for (uint256 i = 0; i < customFeeds.length; i++) {
                if (customFeeds[i] == feed) {
                    isValidFeed = true;
                    break;
                }
            }
        }
        if (!isValidFeed) revert InvalidPriceSource(feed);

        if (maxAge == 0) revert InvalidMaxPriceAge(maxAge);
        if (maxDev == 0 || maxDev > 1e18) revert InvalidMaxRelativeDeviation(maxDev);

        feedConstraints[feed].maxAnswerAge = maxAge;
        feedConstraints[feed].maxPercentageDeviation = maxDev;
        feedConstraints[feed].maxAbsoluteDeviation = type(uint256).max; // Disable absolute deviation checks (use percentage instead)
        feedConstraints[feed].maxTrendReversalDeviation = type(uint256).max; // Disable trend reversal checks
        emit ConstraintsUpdated(feed, maxAge, maxDev);
    }
}
