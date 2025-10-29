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
        FXSAVE
    }

    /*//////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice wstETH contract address (if using wstETH rate source)
    address public immutable WSTETH;

    /// @notice fxsave contract address (if using fxsave rate source)
    IFxSAVE public immutable FXSAVE;

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

    /// @notice Divisor for first feed normalization (default 1)
    uint256 public firstFeedDivisor;

    /// @notice Feed validation constraints
    mapping(address => PriceOracle_v1.Constraints) public feedConstraints;

    /// @notice Numeric identifiers for feeds (1 = first feed)
    mapping(uint8 => address) public feedIdentifiers;

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

    /// @notice Constructor sets immutable values and disables initializers
    /// @param wsteth_ wstETH contract address
    /// @param fxsave_ fxsave contract address
    constructor(address wsteth_, address fxsave_) {
        _disableInitializers();
        WSTETH = wsteth_;
        FXSAVE = IFxSAVE(fxsave_);
    }

    /*//////////////////////////////////////////////////////////////
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes upgradeability and ownership (proxy)
    /// @param owner_ The owner address
    /// @param oracleName_ The oracle name/description
    /// @param rateSource_ Rate source (0 = wstETH, 1 = fxsave)
    /// @param firstFeed_ First feed address (e.g., ETH/USD)
    /// @param firstFeedDivisor_ Divisor for first feed normalization (default 1)
    /// @param firstFeedMaxAge_ Max age for first feed (seconds)
    /// @param firstFeedMaxDev_ Max deviation for first feed (1e18)
    function initialize(
        address owner_,
        string memory oracleName_,
        RateSource rateSource_,
        address firstFeed_,
        uint256 firstFeedDivisor_,
        uint64 firstFeedMaxAge_,
        uint256 firstFeedMaxDev_
    ) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuardTransient_init();
        _initializeOwner(owner_);
        
        // Validate inputs
        if (bytes(oracleName_).length == 0) revert("Invalid oracle name");
        if (firstFeed_ == address(0)) revert InvalidPriceSource(firstFeed_);
        if (firstFeedDivisor_ == 0) revert("Invalid divisor");
        if (firstFeedMaxAge_ == 0) revert InvalidMaxPriceAge(firstFeedMaxAge_);
        if (firstFeedMaxDev_ == 0 || firstFeedMaxDev_ > 1e18) revert InvalidMaxRelativeDeviation(firstFeedMaxDev_);
        
        // Validate rate source configuration
        if (rateSource_ == RateSource.WSTETH && WSTETH == address(0)) revert InvalidRateSource(WSTETH);
        if (rateSource_ == RateSource.FXSAVE && address(FXSAVE) == address(0)) revert InvalidRateSource(address(FXSAVE));
        
        // Set storage variables
        oracleName = oracleName_;
        rateSource = rateSource_;
        firstFeed = firstFeed_;
        firstFeedDivisor = firstFeedDivisor_;
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
    function initializeFeeds(
        uint64 firstFeedMaxAge,
        uint256 firstFeedMaxDev
    ) external onlyOwner {
        if (feedIdentifiers[1] != address(0)) revert("Feeds already initialized");
        feedIdentifiers[1] = address(firstFeed);
        _setFeedConstraints(address(firstFeed), firstFeedMaxAge, firstFeedMaxDev);
    }

    /*//////////////////////////////////////////////////////////////
                            ORACLE INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view returns (uint256, uint256, uint256, uint256) {
        if (feedConstraints[firstFeed].maxAnswerAge == 0) revert ConstraintsNotSet(firstFeed);
        
        PriceOracle_v1.Feed memory firstFeedData = PriceOracle_v1.Feed({
            priceFeed: AggregatorV3Interface(firstFeed),
            decimals: firstFeedDecimals
        });

        uint256 rate = _getRate();
        if (rate < 1e18) revert InvalidRate(rate);
        
        uint256 firstFeedPrice = firstFeedData.latestAnswer(feedConstraints[firstFeed]);
        // forge-lint: disable-next-line(unsafe-typecast) // Safe: only checking for zero
        if (firstFeedPrice == 0) revert InvalidPrice(firstFeed, int256(firstFeedPrice));

        // For single feed, the price is the rate divided by the feed price
        // This gives us the conversion rate (e.g., wstETH/ETH)
        uint256 aggregatorPrice = Math.mulDiv(rate, 1e18, firstFeedPrice);
        
        // Apply divisor to final price for normalization
        uint256 finalPrice = aggregatorPrice / firstFeedDivisor;
        
        return (finalPrice, finalPrice, rate, rate);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    function getPrice() external view returns (uint256 price) {
        PriceOracle_v1.Feed memory firstFeedData = PriceOracle_v1.Feed({
            priceFeed: AggregatorV3Interface(firstFeed),
            decimals: firstFeedDecimals
        });

        uint256 rate = _getRate();
        uint256 firstFeedPrice = firstFeedData.latestAnswer(feedConstraints[firstFeed]);
        
        // For single feed, the price is the rate divided by the feed price
        uint256 aggregatorPrice = Math.mulDiv(rate, 1e18, firstFeedPrice);
        
        // Apply divisor to final price for normalization
        uint256 finalPrice = aggregatorPrice / firstFeedDivisor;
        
        return finalPrice;
    }

    function _getRate() internal view returns (uint256) {
        if (rateSource == RateSource.WSTETH) {
            // For wstETH, get the conversion rate from wstETH to stETH
            return IWstETH(WSTETH).getStETHByWstETH(1e18);
        } else {
            // For fxsave, get the conversion rate
            return FXSAVE.convertToAssets(1e18);
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
