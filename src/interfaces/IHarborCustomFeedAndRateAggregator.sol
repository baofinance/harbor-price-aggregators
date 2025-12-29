// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "./IWrappedPriceOracle.sol";
import {IFxSAVE} from "./IFxSAVE.sol";

/// @title Interface for Harbor Custom Feed and Rate Aggregator
/// @notice Generic oracle for custom feed aggregations (e.g., wstETH to aggregated stock prices)
interface IHarborCustomFeedAndRateAggregator is IWrappedPriceOracle {
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
                                STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice wstETH contract address (if using wstETH rate source)
    function WSTETH() external view returns (address);

    /// @notice fxsave contract address (if using fxsave rate source)
    function FXSAVE() external view returns (IFxSAVE);

    /// @notice sUSDE/USDE Chainlink feed address (if using SUSDE_CHAINLINK rate source)
    function SUSDE_USDE_FEED() external view returns (address);

    /// @notice wstETH/stETH Chainlink feed address (if using WSTETH_CHAINLINK rate source)
    function WSTETH_STETH_FEED() external view returns (address);

    /// @notice Oracle name/description
    function oracleName() external view returns (string memory);

    /// @notice Rate source configuration
    function rateSource() external view returns (RateSource);

    /// @notice Array of custom feed addresses (e.g., AAPL, GOOGLE, NVDA, AMZN, MSFT, META)
    function customFeeds(uint256 index) external view returns (address);

    /// @notice USD feed address for final conversion
    function usdFeed() external view returns (address);

    /// @notice Divisor for aggregated price normalization (e.g., 7)
    function aggregationDivisor() external view returns (uint256);

    /// @notice Decimals of USD feed
    function usdFeedDecimals() external view returns (uint8);

    /// @notice Decimals of each custom feed (indexed by feed address)
    function feedDecimals(address feed) external view returns (uint8);

    /// @notice Feed validation constraints
    function feedConstraints(address feed)
        external
        view
        returns (
            uint64 maxAnswerAge,
            uint256 maxPercentageDeviation,
            uint256 maxAbsoluteDeviation,
            uint256 maxTrendReversalDeviation
        );

    /// @notice Numeric identifiers for feeds (1+ = custom feeds, 100 = USD feed)
    function feedIdentifiers(uint8 identifier) external view returns (address);

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
        uint256 usdFeedMaxDev_
    ) external;

    /// @notice Initializes feed identifiers and constraints for proxy storage
    /// @param customFeedMaxAge Max age for custom feeds (seconds)
    /// @param customFeedMaxDev Max deviation for custom feeds (1e18)
    /// @param usdFeedMaxAge Max age for USD feed (seconds)
    /// @param usdFeedMaxDev Max deviation for USD feed (1e18)
    function initializeFeeds(
        uint64 customFeedMaxAge,
        uint256 customFeedMaxDev,
        uint64 usdFeedMaxAge,
        uint256 usdFeedMaxDev
    ) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the current price
    /// @return price The current price
    function getPrice() external view returns (uint256 price);

    /// @notice Set constraints for a specific feed by identifier (1+ = custom feeds, 100 = USD feed)
    /// @param identifier Feed identifier (1+ = custom feeds, 100 = USD feed)
    /// @param maxAge Maximum age in seconds
    /// @param maxDev Maximum deviation (1e18 precision)
    function setFeedConstraints(uint8 identifier, uint64 maxAge, uint256 maxDev) external;

    /// @notice Update constraints for all custom feeds in one call
    /// @param customFeedMaxAge Max age for custom feeds (seconds)
    /// @param customFeedMaxDev Max deviation for custom feeds (1e18)
    function updateCustomFeedConstraints(uint64 customFeedMaxAge, uint256 customFeedMaxDev) external;

    /// @notice Update constraints for USD feed
    /// @param usdFeedMaxAge Max age for USD feed (seconds)
    /// @param usdFeedMaxDev Max deviation for USD feed (1e18)
    function updateUsdFeedConstraints(uint64 usdFeedMaxAge, uint256 usdFeedMaxDev) external;

    /// @notice Return constraints for a feed by identifier
    /// @param identifier Feed identifier (1+ = custom feeds, 100 = USD feed)
    /// @return maxAge Maximum age in seconds
    /// @return maxDev Maximum deviation (1e18 precision)
    function getConstraints(uint8 identifier) external view returns (uint64 maxAge, uint256 maxDev);

    /// @notice Get the number of custom feeds
    /// @return count The number of custom feeds
    function getCustomFeedCount() external view returns (uint256);

    /// @notice Get a custom feed address by index
    /// @param index The index of the custom feed
    /// @return feed The custom feed address
    function getCustomFeed(uint256 index) external view returns (address);

    /// @notice Get the current rate from the configured rate source
    /// @return rate The current rate (wstETH/stETH, fxSAVE/assets, etc.), always 18 decimals
    function getRate() external view returns (uint256 rate);

    /// @notice Get the number of decimals for the price output
    /// @dev Always returns 18 decimals for consistency
    /// @return decimals Always returns 18
    function decimals() external pure returns (uint8);

    /// @notice Maximum age for rate source feeds (configurable, defaults to 1 day)
    /// @dev Only applies to Chainlink rate sources (SUSDE_CHAINLINK, WSTETH_CHAINLINK)
    ///      Direct contract calls (WSTETH, FXSAVE) are always current
    function maxRateSourceAge() external view returns (uint64);

    /// @notice Set the maximum age for rate source feeds
    /// @dev Only applies to Chainlink rate sources (SUSDE_CHAINLINK, WSTETH_CHAINLINK)
    ///      Direct contract calls (WSTETH, FXSAVE) are always current and don't use this
    /// @param maxAge Maximum age in seconds (e.g., 1 days = 86400, 7 days = 604800)
    function setMaxRateSourceAge(uint64 maxAge) external;

    /// @notice Emitted when max rate source age is updated
    /// @param maxAge New maximum age in seconds
    event MaxRateSourceAgeUpdated(uint64 maxAge);
}
