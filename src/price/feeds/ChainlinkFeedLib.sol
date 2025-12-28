// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";

/// @title ChainlinkFeedLib
/// @notice Library for reading and normalizing Chainlink feed data to 18 decimals.
/// @dev This library provides raw feed reading and normalization without validation.
///      For validated reads with staleness/deviation checks, use PriceOracle_v1.
library ChainlinkFeedLib {
    /// @notice Read the latest answer from a Chainlink feed, normalized to 18 decimals.
    /// @param feed The Chainlink aggregator interface
    /// @param decimals The number of decimals the feed reports
    /// @return price The latest price normalized to 18 decimals
    function latestAnswerNormalized(AggregatorV3Interface feed, uint8 decimals) internal view returns (uint256 price) {
        // slither-disable-next-line unused-return
        (, int256 answer,,,) = feed.latestRoundData();
        int256 normalized = normaliseTo18(answer, decimals);
        // Chainlink price feeds should never return negative values
        require(normalized >= 0, "ChainlinkFeedLib: negative price");
        return uint256(normalized);
    }

    /// @notice Normalize a value to 18 decimals.
    /// @param value The raw value from the feed
    /// @param decimals The number of decimals the value currently has
    /// @return normalisedValue The value scaled to 18 decimals
    function normaliseTo18(int256 value, uint8 decimals) internal pure returns (int256 normalisedValue) {
        if (decimals == 18) {
            normalisedValue = value;
        } else if (decimals < 18) {
            // Scale up - not lossy
            normalisedValue = value * int256(10 ** (18 - decimals));
        } else {
            // Scale down (lossy for >18 decimals, but Chainlink never does this)
            normalisedValue = value / int256(10 ** (decimals - 18));
        }
    }
}
