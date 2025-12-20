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

/// @title Harbor Custom Feed and Rate Aggregator V2
/// @notice Generic oracle for custom feed aggregations (e.g., wstETH to aggregated stock prices)
/// @dev V2: Price calculation does NOT multiply by rate - uses feed prices directly
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract HarborCustomFeedAndRateAggregator_v2 is
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

    /// @notice Array of custom feed addresses (e.g., AAPL, GOOGLE, NVDA, AMZN, MSFT, META)
    address[] public customFeeds;

    /// @notice USD feed address for final conversion
    address public usdFeed;

    /// @notice Divisor for aggregated price normalization (e.g., 7)
    uint256 public aggregationDivisor;

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
    error InvalidAggregationDivisor(uint256 divisor);
    error EmptyCustomFeeds();
    error InvalidCustomFeedCount(uint256 count);
    error FeedNotFound(address feed);
    error StaleRateSource(address source, uint256 updatedAt);

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
    /// @param customFeeds_ Array of custom feed addresses (e.g., stock price feeds)
    /// @param usdFeed_ USD feed address for final conversion
    /// @param aggregationDivisor_ Divisor for aggregated price normalization (e.g., 7)
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

        // Set storage variables first to reduce stack depth
        oracleName = oracleName_;
        rateSource = rateSource_;
        customFeeds = customFeeds_;
        usdFeed = usdFeed_;
        aggregationDivisor = aggregationDivisor_;
        invertPrice = invertPrice_;

        // Validate inputs (reduce stack by grouping validations)
        _validateInitializeInputs(
            oracleName_,
            customFeeds_,
            usdFeed_,
            aggregationDivisor_,
            customFeedMaxAge_,
            customFeedMaxDev_,
            usdFeedMaxAge_,
            usdFeedMaxDev_,
            rateSource_
        );

        // Validate and set custom feeds (reduce stack by using local variable)
        uint256 customFeedsLength = customFeeds_.length;
        for (uint256 i = 0; i < customFeedsLength; i++) {
            address feed = customFeeds_[i];
            if (feed == address(0)) revert InvalidPriceSource(feed);
            AggregatorV3Interface feedInterface = AggregatorV3Interface(feed);
            uint8 feedDecimalsValue = feedInterface.decimals();
            if (feedDecimalsValue == 0) revert InvalidFeedDecimals(feed);
            feedDecimals[feed] = feedDecimalsValue;
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

    /// @notice Internal function to validate initialize inputs (reduces stack depth)
    function _validateInitializeInputs(
        string memory oracleName_,
        address[] memory customFeeds_,
        address usdFeed_,
        uint256 aggregationDivisor_,
        uint64 customFeedMaxAge_,
        uint256 customFeedMaxDev_,
        uint64 usdFeedMaxAge_,
        uint256 usdFeedMaxDev_,
        RateSource rateSource_
    ) internal view {
        if (bytes(oracleName_).length == 0) revert("Invalid oracle name");
        if (customFeeds_.length == 0) revert EmptyCustomFeeds();
        if (customFeeds_.length > 50) revert InvalidCustomFeedCount(customFeeds_.length);
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
    }

    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        emit Upgraded(newImpl);
    }

    /// @notice Initializes feed identifiers and constraints for proxy storage
    /// @dev This function is only needed if feeds were not initialized in initialize()
    ///      Checks that feeds array is populated before setting identifiers
    function initializeFeeds(
        uint64 customFeedMaxAge,
        uint256 customFeedMaxDev,
        uint64 usdFeedMaxAge,
        uint256 usdFeedMaxDev
    ) external onlyOwner {
        if (feedIdentifiers[1] != address(0)) revert("Feeds already initialized");
        if (customFeeds.length == 0) revert EmptyCustomFeeds();
        if (usdFeed == address(0)) revert InvalidPriceSource(usdFeed);

        for (uint256 i = 0; i < customFeeds.length; i++) {
            feedIdentifiers[uint8(i + 1)] = customFeeds[i];
            _setFeedConstraints(customFeeds[i], customFeedMaxAge, customFeedMaxDev);
        }
        feedIdentifiers[100] = usdFeed;
        _setFeedConstraints(usdFeed, usdFeedMaxAge, usdFeedMaxDev);
    }

    /*//////////////////////////////////////////////////////////////
                            ORACLE INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IWrappedPriceOracle
    /// @notice Returns validated oracle price information
    /// @dev Returns (price, price, rate, rate) for compatibility with IWrappedPriceOracle interface
    ///      First two values are the final normalized price (units of aggregated basket per 1 unit), always 18 decimals
    ///      Last two values are the raw rate (wstETH/stETH conversion rate), always 18 decimals
    ///      Min/max values are identical as this oracle provides deterministic pricing
    /// @return minUnderlyingPrice The validated min price (units of aggregated basket per 1 unit), 18 decimals
    /// @return maxUnderlyingPrice The validated max price (units of aggregated basket per 1 unit), 18 decimals
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

    /// @notice Get the current price (units of aggregated basket per 1 unit)
    /// @dev Uses internal logic to avoid external call overhead
    /// @return price The current price, always 18 decimals
    function getPrice() external view returns (uint256 price) {
        price = _getPrice();
    }

    /// @notice Internal function to get the current price
    /// @dev V2: Price does NOT multiply by rate - uses USD feed and aggregated prices directly
    /// @return price The current price, always 18 decimals
    function _getPrice() internal view returns (uint256 price) {
        // Validate constraints are set
        if (feedConstraints[usdFeed].maxAnswerAge == 0) revert ConstraintsNotSet(usdFeed);
        for (uint256 i = 0; i < customFeeds.length; i++) {
            if (feedConstraints[customFeeds[i]].maxAnswerAge == 0) revert ConstraintsNotSet(customFeeds[i]);
        }

        // Aggregate all custom feed prices
        uint256 aggregatedPrice = 0;
        AggregatorV3Interface usdFeedInterface = AggregatorV3Interface(usdFeed);

        for (uint256 i = 0; i < customFeeds.length; i++) {
            AggregatorV3Interface feedInterface = AggregatorV3Interface(customFeeds[i]);
            PriceOracle_v1.Feed memory feedData = PriceOracle_v1.Feed({
                priceFeed: feedInterface,
                decimals: feedDecimals[customFeeds[i]]
            });

            uint256 feedPrice = feedData.latestAnswer(feedConstraints[customFeeds[i]]);
            // forge-lint: disable-next-line(unsafe-typecast) // Safe: only checking for zero
            if (feedPrice == 0) revert InvalidPrice(customFeeds[i], int256(feedPrice));

            aggregatedPrice += feedPrice;
        }

        // Divide aggregated price by divisor
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
            // Invert: Calculate units of USD per 1 aggregated stock basket
            // Formula: (normalizedAggregatedPrice * 1e18) / usdFeedPrice
            finalPrice = Math.mulDiv(normalizedAggregatedPrice, 1e18, usdFeedPrice);
        } else {
            // V2: Direct conversion without rate multiplication
            // Calculate units of aggregated stock basket per 1 USD: USD / aggregated_stock_price
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
            uint8 feedDecimalsValue = feed.decimals();
            (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();

            // Validate answer is positive
            if (answer <= 0) revert InvalidPrice(SUSDE_USDE_FEED, answer);

            // Validate feed is not stale (uses configurable maxRateSourceAge)
            // slither-disable-next-line timestamp
            if (block.timestamp - updatedAt > maxRateSourceAge) revert StaleRateSource(SUSDE_USDE_FEED, updatedAt);

            // Normalize to 18 decimals
            uint256 rate;
            if (feedDecimalsValue <= 18) {
                rate = uint256(answer) * (10 ** (18 - feedDecimalsValue));
            } else {
                rate = uint256(answer) / (10 ** (feedDecimalsValue - 18));
            }

            // Validate rate is within sane bounds (sUSDE/USDE should be >= 0.9x)
            if (rate < 9e17) revert InvalidRate(rate);
            return rate;
        } else {
            // For WSTETH_CHAINLINK, get the wstETH/stETH rate from Chainlink feed
            AggregatorV3Interface feed = AggregatorV3Interface(WSTETH_STETH_FEED);
            uint8 feedDecimalsValue = feed.decimals();
            (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();

            // Validate answer is positive
            if (answer <= 0) revert InvalidPrice(WSTETH_STETH_FEED, answer);

            // Validate feed is not stale (uses configurable maxRateSourceAge)
            // slither-disable-next-line timestamp
            if (block.timestamp - updatedAt > maxRateSourceAge) revert StaleRateSource(WSTETH_STETH_FEED, updatedAt);

            // Normalize to 18 decimals
            uint256 rate;
            if (feedDecimalsValue <= 18) {
                rate = uint256(answer) * (10 ** (18 - feedDecimalsValue));
            } else {
                rate = uint256(answer) / (10 ** (feedDecimalsValue - 18));
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

    /// @notice Update constraints for all custom feeds in one call
    function updateCustomFeedConstraints(uint64 customFeedMaxAge, uint256 customFeedMaxDev) external onlyOwner {
        for (uint256 i = 0; i < customFeeds.length; i++) {
            _setFeedConstraints(customFeeds[i], customFeedMaxAge, customFeedMaxDev);
        }
    }

    /// @notice Update constraints for USD feed
    function updateUsdFeedConstraints(uint64 usdFeedMaxAge, uint256 usdFeedMaxDev) external onlyOwner {
        _setFeedConstraints(usdFeed, usdFeedMaxAge, usdFeedMaxDev);
    }

    /// @notice Return constraints for a feed by identifier
    function getConstraints(uint8 identifier) external view returns (uint64 maxAge, uint256 maxDev) {
        address feed = feedIdentifiers[identifier];
        if (feed == address(0)) revert InvalidFeedIdentifier(identifier);
        PriceOracle_v1.Constraints memory c = feedConstraints[feed];
        return (c.maxAnswerAge, c.maxPercentageDeviation);
    }

    /// @notice Get the number of custom feeds
    function getCustomFeedCount() external view returns (uint256) {
        return customFeeds.length;
    }

    /// @notice Get a custom feed address by index
    function getCustomFeed(uint256 index) external view returns (address) {
        if (index >= customFeeds.length) revert FeedNotFound(address(0));
        return customFeeds[index];
    }

    /// @notice Get the current rate from the configured rate source
    /// @return rate The current rate (wstETH/stETH, fxSAVE/assets, etc.), always 18 decimals
    function getRate() external view returns (uint256 rate) {
        return _getRate();
    }

    /// @notice Get the number of decimals for the price output
    /// @dev Always returns 18 decimals for consistency
    /// @return decimals Always returns 18
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @notice Returns a human-readable description of the oracle
    /// @dev Standard Chainlink oracle interface function
    /// @return description The oracle description/name
    function description() external view returns (string memory) {
        return oracleName;
    }

    /// @notice Returns the version of the oracle contract
    /// @dev Standard Chainlink oracle interface function
    /// @return version The contract version (always 2 for v2)
    function version() external pure returns (uint256) {
        return 2;
    }

    /// @notice Set the maximum age for rate source feeds
    /// @dev Only applies to Chainlink rate sources (SUSDE_CHAINLINK, WSTETH_CHAINLINK)
    ///      Direct contract calls (WSTETH, FXSAVE) are always current and don't use this
    /// @param maxAge Maximum age in seconds (e.g., 1 days = 86400, 7 days = 604800)
    function setMaxRateSourceAge(uint64 maxAge) external onlyOwner {
        if (maxAge == 0) revert InvalidMaxPriceAge(maxAge);
        maxRateSourceAge = maxAge;
        emit MaxRateSourceAgeUpdated(maxAge);
    }

    /// @notice Set whether to invert the price conversion
    /// @dev When true, converts from aggregated custom feeds to USD instead of USD to aggregated custom feeds
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
                if (feed == customFeeds[i]) {
                    isValidFeed = true;
                    break;
                }
            }
        }
        if (!isValidFeed) revert FeedNotFound(feed);

        if (maxAge == 0) revert InvalidMaxPriceAge(maxAge);
        if (maxDev == 0 || maxDev > 1e18) revert InvalidMaxRelativeDeviation(maxDev);

        feedConstraints[feed] = PriceOracle_v1.Constraints({
            maxAnswerAge: maxAge,
            maxPercentageDeviation: maxDev,
            maxAbsoluteDeviation: type(uint256).max,
            maxTrendReversalDeviation: type(uint256).max
        });

        emit ConstraintsUpdated(feed, maxAge, maxDev);
    }
}
