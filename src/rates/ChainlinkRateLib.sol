// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";

library ChainlinkRateLib {
    error InvalidRate(uint256 rate);
    error StaleRateSource(address source, uint256 updatedAt);

    uint256 internal constant DEFAULT_MIN_RATE = 1e18;
    uint256 internal constant DEFAULT_MAX_RATE = 2e18;
    uint64 internal constant DEFAULT_MAX_AGE = 86_400; // 24 hours (matches feed heartbeats)

    /// @notice Get the rate from a Chainlink feed with default validation.
    /// @param feed The Chainlink aggregator interface for the rate feed
    /// @return rate The rate normalized to 18 decimals
    function getRate(AggregatorV3Interface feed) internal view returns (uint256) {
        uint8 feedDecimals = feed.decimals();
        return getRate(feed, feedDecimals, DEFAULT_MIN_RATE, DEFAULT_MAX_RATE, DEFAULT_MAX_AGE);
    }

    /// @notice Get the rate from a Chainlink feed with custom validation.
    /// @param feed The Chainlink aggregator interface for the rate feed
    /// @param feedDecimals The number of decimals the feed reports
    /// @param minRate Minimum acceptable rate (18 decimals)
    /// @param maxRate Maximum acceptable rate (18 decimals)
    /// @param maxAge Maximum age in seconds for the feed data
    /// @return rate The rate normalized to 18 decimals
    function getRate(
        AggregatorV3Interface feed,
        uint8 feedDecimals,
        uint256 minRate,
        uint256 maxRate,
        uint64 maxAge
    ) internal view returns (uint256) {
        // Get the feed data
        // slither-disable-next-line unused-return
        (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();

        // Validate answer is positive
        if (answer <= 0) revert InvalidRate(uint256(answer));

        // Validate feed is not stale
        // slither-disable-next-line timestamp
        if (block.timestamp - updatedAt > maxAge) revert StaleRateSource(address(feed), updatedAt);

        // Normalize to 18 decimals
        int256 normalized;
        if (feedDecimals == 18) {
            normalized = answer;
        } else if (feedDecimals < 18) {
            normalized = answer * int256(10 ** (18 - feedDecimals));
        } else {
            normalized = answer / int256(10 ** (feedDecimals - 18));
        }

        // Validate normalized value is positive
        if (normalized <= 0) revert InvalidRate(uint256(-normalized));
        uint256 rate = uint256(normalized);

        // Validate rate bounds
        if (rate < minRate || rate > maxRate) revert InvalidRate(rate);

        return rate;
    }
}
