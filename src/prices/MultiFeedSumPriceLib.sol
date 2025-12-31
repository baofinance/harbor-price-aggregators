// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

library MultiFeedSumPriceLib {
    error EmptyFeeds();
    error InvalidFeedCount(uint256 count);

    /// @notice Get the sum of prices from multiple feeds.
    /// @param feeds Array of Chainlink feed interfaces
    /// @param feedDecimals Array of decimals for each feed (must match feeds length)
    /// @param feedHeartbeats Array of heartbeats for each feed (must match feeds length)
    /// @return price The sum of all feed prices normalized to 18 decimals
    function getPrice(
        AggregatorV3Interface[] memory feeds,
        uint8[] memory feedDecimals,
        uint256[] memory feedHeartbeats
    ) internal view returns (uint256) {
        uint256 feedCount = feeds.length;
        if (feedCount == 0) revert EmptyFeeds();
        if (feedCount > 50) revert InvalidFeedCount(feedCount); // Reasonable limit
        if (feedDecimals.length != feedCount) revert InvalidFeedCount(feedDecimals.length);
        if (feedHeartbeats.length != feedCount) revert InvalidFeedCount(feedHeartbeats.length);

        uint256 sum = 0;
        for (uint256 i = 0; i < feedCount; i++) {
            uint256 feedPrice = ChainlinkFeedLib.latestAnswerNormalized(feeds[i], feedDecimals[i], feedHeartbeats[i]);
            sum += feedPrice;
        }

        return sum;
    }
}
