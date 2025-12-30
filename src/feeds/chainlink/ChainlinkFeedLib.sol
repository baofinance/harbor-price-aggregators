// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";

/// @title ChainlinkFeedLib
/// @notice Library for reading and normalizing Chainlink feed data to 18 decimals.
/// @dev This library provides feed reading with heartbeat validation and normalization.
library ChainlinkFeedLib {
    /// @notice Fixed tolerance added to heartbeat checks to account for block time variance.
    /// The updatedAt timestamp may exceed the documented heartbeat by a small margin
    /// due to:
    /// - Block timestamp granularity and miner clock variance
    /// - Transaction propagation and finalization delays
    /// - Oracle node coordination and aggregation timing
    /// We add a fixed buffer to the stated heartbeat to account for these
    /// operational realities while still detecting genuinely stale prices.
    /// @dev 42 seconds ≈ 3.5 Ethereum block times. Chainlink updates may land 1-2 blocks after
    ///      the heartbeat expires due to transaction inclusion timing.
    uint256 internal constant HEARTBEAT_TOLERANCE = 42;

    /// @notice Thrown when feed data is older than the heartbeat allows
    /// @param feed The feed address
    /// @param updatedAt When the feed was last updated
    /// @param currentTime Current block timestamp
    /// @param heartbeat Maximum allowed age in seconds (before tolerance)
    error StaleFeedData(address feed, uint256 updatedAt, uint256 currentTime, uint256 heartbeat);

    /// @notice Thrown when feed has never been updated (updatedAt == 0)
    /// @param feed The feed address
    error FeedNeverUpdated(address feed);

    /// @notice Thrown when normalized price is negative
    /// @param feed The feed address
    /// @param rawAnswer The raw answer from the feed
    error NegativePrice(address feed, int256 rawAnswer);

    /// @notice Read the latest answer from a Chainlink feed, normalized to 18 decimals.
    /// @param feed The Chainlink aggregator interface
    /// @param decimals The number of decimals the feed reports
    /// @param heartbeat Maximum age in seconds before data is considered stale
    /// @return price The latest price normalized to 18 decimals
    function latestAnswerNormalized(
        AggregatorV3Interface feed,
        uint8 decimals,
        uint256 heartbeat
    ) internal view returns (uint256 price) {
        // slither-disable-next-line unused-return
        (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();

        // Validate feed has been updated at least once
        if (updatedAt == 0) {
            revert FeedNeverUpdated(address(feed));
        }

        // Validate freshness against heartbeat + tolerance for block timing variance
        // slither-disable-next-line timestamp
        if (block.timestamp - updatedAt > heartbeat + HEARTBEAT_TOLERANCE) {
            revert StaleFeedData(address(feed), updatedAt, block.timestamp, heartbeat);
        }

        int256 normalized = normaliseTo18(answer, decimals);
        // Chainlink price feeds should never return negative values
        if (normalized < 0) {
            revert NegativePrice(address(feed), answer);
        }
        return uint256(normalized);
    }

    /// @notice Normalize a value to 18 decimals.
    /// @param value The raw value from the feed
    /// @param decimals The number of decimals the value currently has
    /// @return normalisedValue The value scaled to 18 decimals
    function normaliseTo18(int256 value, uint8 decimals) internal pure returns (int256 normalisedValue) {
        if (decimals <= 18) {
            // Scale up - not lossy
            normalisedValue = value * int256(10 ** (18 - decimals));
        } else {
            // Scale down (lossy for >18 decimals, but Chainlink never does this)
            normalisedValue = value / int256(10 ** (decimals - 18));
        }
    }
}
