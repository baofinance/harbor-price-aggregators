// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "./IWrappedPriceOracle.sol";
import {IFxSAVE} from "./IFxSAVE.sol";

/// @title Interface for Harbor Double Feed and Rate Aggregator
/// @notice Generic oracle for double feed conversions (e.g., wstETH to BTC, EUR, XAU, MCAP)
interface IHarborDoubleFeedAndRateAggregator is IWrappedPriceOracle {
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
    error InvalidConversionFeed(address source);
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

    /// @notice First feed address (e.g., USDC/USD or ETH/USD)
    function firstFeed() external view returns (address);

    /// @notice Second feed address (e.g., BTC/USD, EUR/USD, XAU/USD, MCAP/USD)
    function secondFeed() external view returns (address);

    /// @notice Decimals of first feed
    function firstFeedDecimals() external view returns (uint8);

    /// @notice Decimals of second feed
    function secondFeedDecimals() external view returns (uint8);

    /// @notice Divisor for price normalization (e.g., 1T for MCAP)
    function priceDivisor() external view returns (uint256);

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

    /// @notice Numeric identifiers for feeds (1 = first feed, 2 = second feed)
    function feedIdentifiers(uint8 identifier) external view returns (address);

    /*//////////////////////////////////////////////////////////////
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes upgradeability and ownership (proxy)
    /// @param owner_ The owner address
    /// @param oracleName_ The oracle name/description
    /// @param rateSource_ Rate source (0 = wstETH, 1 = fxsave)
    /// @param firstFeed_ First feed address (e.g., USDC/USD or ETH/USD)
    /// @param secondFeed_ Second feed address (e.g., BTC/USD, EUR/USD, XAU/USD, MCAP/USD)
    /// @param priceDivisor_ Divisor for price normalization (default 1, use 1e12 for MCAP)
    /// @param firstFeedMaxAge_ Max age for first feed (seconds)
    /// @param firstFeedMaxDev_ Max deviation for first feed (1e18)
    /// @param secondFeedMaxAge_ Max age for second feed (seconds)
    /// @param secondFeedMaxDev_ Max deviation for second feed (1e18)
    function initialize(
        address owner_,
        string memory oracleName_,
        RateSource rateSource_,
        address firstFeed_,
        address secondFeed_,
        uint256 priceDivisor_,
        uint64 firstFeedMaxAge_,
        uint256 firstFeedMaxDev_,
        uint64 secondFeedMaxAge_,
        uint256 secondFeedMaxDev_
    ) external;

    /// @notice Initializes feed identifiers and constraints for proxy storage
    /// @param firstFeedMaxAge Max age for first feed (seconds)
    /// @param firstFeedMaxDev Max deviation for first feed (1e18)
    /// @param secondFeedMaxAge Max age for second feed (seconds)
    /// @param secondFeedMaxDev Max deviation for second feed (1e18)
    function initializeFeeds(
        uint64 firstFeedMaxAge,
        uint256 firstFeedMaxDev,
        uint64 secondFeedMaxAge,
        uint256 secondFeedMaxDev
    ) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the current price
    /// @return price The current price
    function getPrice() external view returns (uint256 price);

    /// @notice Set constraints for a specific feed by identifier (1=first feed, 2=second feed)
    /// @param identifier Feed identifier (1 = first feed, 2 = second feed)
    /// @param maxAge Maximum age in seconds
    /// @param maxDev Maximum deviation (1e18 precision)
    function setFeedConstraints(uint8 identifier, uint64 maxAge, uint256 maxDev) external;

    /// @notice Update constraints for both feeds in one call
    /// @param firstFeedMaxAge Max age for first feed (seconds)
    /// @param firstFeedMaxDev Max deviation for first feed (1e18)
    /// @param secondFeedMaxAge Max age for second feed (seconds)
    /// @param secondFeedMaxDev Max deviation for second feed (1e18)
    function updateBothConstraints(
        uint64 firstFeedMaxAge,
        uint256 firstFeedMaxDev,
        uint64 secondFeedMaxAge,
        uint256 secondFeedMaxDev
    ) external;

    /// @notice Return constraints for a feed by identifier
    /// @param identifier Feed identifier (1 = first feed, 2 = second feed)
    /// @return maxAge Maximum age in seconds
    /// @return maxDev Maximum deviation (1e18 precision)
    function getConstraints(uint8 identifier) external view returns (uint64 maxAge, uint256 maxDev);

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




