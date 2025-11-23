// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "./IWrappedPriceOracle.sol";
import {IFxSAVE} from "./IFxSAVE.sol";

/// @title Interface for Harbor Single Feed and Rate Aggregator
/// @notice Generic oracle for single feed conversions (e.g., wstETH to ETH)
interface IHarborSingleFeedAndRateAggregator is IWrappedPriceOracle {
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

    /// @notice First feed address (e.g., ETH/USD)
    function firstFeed() external view returns (address);

    /// @notice Decimals of first feed
    function firstFeedDecimals() external view returns (uint8);

    /// @notice Divisor for price normalization (default 1)
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

    /// @notice Numeric identifiers for feeds (1 = first feed)
    function feedIdentifiers(uint8 identifier) external view returns (address);

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
    ) external;

    /// @notice Initializes feed identifiers and constraints for proxy storage
    /// @param firstFeedMaxAge Max age for first feed (seconds)
    /// @param firstFeedMaxDev Max deviation for first feed (1e18)
    function initializeFeeds(uint64 firstFeedMaxAge, uint256 firstFeedMaxDev) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the current price
    /// @return price The current price
    function getPrice() external view returns (uint256 price);

    /// @notice Set constraints for the first feed
    /// @param identifier Feed identifier (1 = first feed)
    /// @param maxAge Maximum age in seconds
    /// @param maxDev Maximum deviation (1e18 precision)
    function setFeedConstraints(uint8 identifier, uint64 maxAge, uint256 maxDev) external;

    /// @notice Return constraints for a feed by identifier
    /// @param identifier Feed identifier (1 = first feed)
    /// @return maxAge Maximum age in seconds
    /// @return maxDev Maximum deviation (1e18 precision)
    function getConstraints(uint8 identifier) external view returns (uint64 maxAge, uint256 maxDev);
}




