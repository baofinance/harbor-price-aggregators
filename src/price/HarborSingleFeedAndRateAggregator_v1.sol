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

/// @title Harbor Single Feed and Rate Aggregator
/// @notice Generic oracle for single feed conversions (e.g., wstETH to ETH)
/// @dev Supports both wstETH and fxsave rate sources with configurable feed constraints
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract HarborSingleFeedAndRateAggregator_v1 is IWrappedPriceOracle, UUPSUpgradeable, ReentrancyGuardTransientUpgradeable, BaoOwnable {
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

    /// @notice First feed address (e.g., ETH/USD)
    address public firstFeed;

    /// @notice Decimals of first feed
    uint8 public firstFeedDecimals;

    /// @notice Divisor for price normalization (default 1)
    uint256 public priceDivisor;

    /// @notice Feed validation constraints
    mapping(address => PriceOracle_v1.Constraints) public feedConstraints;

    /// @notice Numeric identifiers for feeds (1 = first feed)
    mapping(uint8 => address) public feedIdentifiers;

    /// @notice Maximum age for rate source feeds (configurable, defaults to 1 day)
    /// @dev Only applies to Chainlink rate sources (SUSDE_CHAINLINK, WSTETH_CHAINLINK)
    ///      Direct contract calls (WSTETH, FXSAVE) are always current
    uint64 public maxRateSourceAge = 1 days;

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
    /// @param rateSource_ Rate source (0 = wstETH, 1 = fxsave)
    /// @param firstFeed_ First feed address (e.g., ETH/USD)
    /// @param priceDivisor_ Divisor for price normalization (default 1)
    /// @param firstFeedMaxAge_ Max age for first feed (seconds)
    /// @param firstFeedMaxDev_ Max deviation for first feed (1e18)
    function initialize(
        address owner_,
        string memory oracleName_,
        RateSource rateSource_,
        address firstFeed_,
        uint256 priceDivisor_,
        uint64 firstFeedMaxAge_,
        uint256 firstFeedMaxDev_
    ) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuardTransient_init();
        _initializeOwner(owner_);
        
        // Validate inputs
        if (bytes(oracleName_).length == 0) revert("Invalid oracle name");
        if (firstFeed_ == address(0)) revert InvalidPriceSource(firstFeed_);
        if (priceDivisor_ == 0) revert("Invalid divisor");
        if (firstFeedMaxAge_ == 0) revert InvalidMaxPriceAge(firstFeedMaxAge_);
        if (firstFeedMaxDev_ == 0 || firstFeedMaxDev_ > 1e18) revert InvalidMaxRelativeDeviation(firstFeedMaxDev_);
        
        // Validate rate source configuration
        if (rateSource_ == RateSource.WSTETH && WSTETH == address(0)) revert InvalidRateSource(WSTETH);
        if (rateSource_ == RateSource.FXSAVE && address(FXSAVE) == address(0)) revert InvalidRateSource(address(FXSAVE));
        if (rateSource_ == RateSource.SUSDE_CHAINLINK && SUSDE_USDE_FEED == address(0)) revert InvalidRateSource(SUSDE_USDE_FEED);
        if (rateSource_ == RateSource.WSTETH_CHAINLINK && WSTETH_STETH_FEED == address(0)) revert InvalidRateSource(WSTETH_STETH_FEED);
        
        // Set storage variables
        oracleName = oracleName_;
        rateSource = rateSource_;
        firstFeed = firstFeed_;
        priceDivisor = priceDivisor_;
        firstFeedDecimals = AggregatorV3Interface(firstFeed_).decimals();
        
        if (firstFeedDecimals == 0) revert InvalidFeedDecimals(firstFeed_);
        
        // Store feed identifier
        feedIdentifiers[1] = firstFeed_;
        
        // Set initial constraints
        _setFeedConstraints(firstFeed_, firstFeedMaxAge_, firstFeedMaxDev_);
        
        emit Initialized(owner_);
    }

    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        emit Upgraded(newImpl);
    }

    /// @notice Initializes feed identifiers and constraints for proxy storage
    /// @dev This function is only needed if feeds were not initialized in initialize()
    ///      Checks that feed is populated before setting identifier
    function initializeFeeds(
        uint64 firstFeedMaxAge,
        uint256 firstFeedMaxDev
    ) external onlyOwner {
        if (feedIdentifiers[1] != address(0)) revert("Feeds already initialized");
        if (firstFeed == address(0)) revert InvalidPriceSource(firstFeed);
        feedIdentifiers[1] = firstFeed;
        _setFeedConstraints(firstFeed, firstFeedMaxAge, firstFeedMaxDev);
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

    /// @notice Internal function to get the current price
    /// @dev Reuses latestAnswer() logic without external call overhead
    /// @return price The current price, always 18 decimals
    function _getPrice() internal view returns (uint256 price) {
        if (feedConstraints[firstFeed].maxAnswerAge == 0) revert ConstraintsNotSet(firstFeed);
        
        PriceOracle_v1.Feed memory firstFeedData = PriceOracle_v1.Feed({
            priceFeed: AggregatorV3Interface(firstFeed),
            decimals: firstFeedDecimals
        });

        uint256 rate = _getRate();
        
        uint256 firstFeedPrice = firstFeedData.latestAnswer(feedConstraints[firstFeed]);
        // forge-lint: disable-next-line(unsafe-typecast) // Safe: only checking for zero
        if (firstFeedPrice == 0) revert InvalidPrice(firstFeed, int256(firstFeedPrice));

        // For single feed, calculate: (rate * firstFeedPrice) / 1e18
        uint256 aggregatorPrice = Math.mulDiv(rate, firstFeedPrice, 1e18);
        
        // Apply divisor to final price for normalization
        uint256 finalPrice = aggregatorPrice / priceDivisor;
        
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
            uint8 feedDecimals = feed.decimals();
            (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
            
            // Validate answer is positive
            if (answer <= 0) revert InvalidPrice(SUSDE_USDE_FEED, answer);
            
            // Validate feed is not stale (uses configurable maxRateSourceAge)
            // slither-disable-next-line timestamp
            if (block.timestamp - updatedAt > maxRateSourceAge) revert StaleRateSource(SUSDE_USDE_FEED, updatedAt);
            
            // Normalize to 18 decimals
            uint256 rate;
            if (feedDecimals <= 18) {
                rate = uint256(answer) * (10 ** (18 - feedDecimals));
            } else {
                rate = uint256(answer) / (10 ** (feedDecimals - 18));
            }
            
            // Validate rate is within sane bounds (sUSDE/USDE should be >= 0.9x)
            if (rate < 9e17) revert InvalidRate(rate);
            return rate;
        } else {
            // For WSTETH_CHAINLINK, get the wstETH/stETH rate from Chainlink feed
            AggregatorV3Interface feed = AggregatorV3Interface(WSTETH_STETH_FEED);
            uint8 feedDecimals = feed.decimals();
            (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
            
            // Validate answer is positive
            if (answer <= 0) revert InvalidPrice(WSTETH_STETH_FEED, answer);
            
            // Validate feed is not stale (uses configurable maxRateSourceAge)
            // slither-disable-next-line timestamp
            if (block.timestamp - updatedAt > maxRateSourceAge) revert StaleRateSource(WSTETH_STETH_FEED, updatedAt);
            
            // Normalize to 18 decimals
            uint256 rate;
            if (feedDecimals <= 18) {
                rate = uint256(answer) * (10 ** (18 - feedDecimals));
            } else {
                rate = uint256(answer) / (10 ** (feedDecimals - 18));
            }
            
            // Validate rate is within sane bounds (wstETH/stETH should be between 1.0 and 2.0)
            if (rate < 1e18 || rate > 2e18) revert InvalidRate(rate);
            return rate;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice Set constraints for the first feed
    function setFeedConstraints(uint8 identifier, uint64 maxAge, uint256 maxDev) external onlyOwner {
        address feed = feedIdentifiers[identifier];
        if (feed == address(0)) revert InvalidFeedIdentifier(identifier);
        _setFeedConstraints(feed, maxAge, maxDev);
    }

    /// @notice Return constraints for a feed by identifier
    function getConstraints(uint8 identifier) external view returns (uint64 maxAge, uint256 maxDev) {
        address feed = feedIdentifiers[identifier];
        if (feed == address(0)) revert InvalidFeedIdentifier(identifier);
        PriceOracle_v1.Constraints memory c = feedConstraints[feed];
        return (c.maxAnswerAge, c.maxPercentageDeviation);
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
    /// @return version The contract version (always 1 for v1)
    function version() external pure returns (uint256) {
        return 1;
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

    /// @dev Internal setter with validation and event emission
    function _setFeedConstraints(address feed, uint64 maxAge, uint256 maxDev) internal {
        if (feed != firstFeed) revert InvalidFeedIdentifier(0);
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
