// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library MultiFeedNormalizedPriceLib {
    error EmptyFeeds();
    error InvalidFeedCount(uint256 count);

    /// @notice Get the normalized average price from multiple feeds.
    /// @dev Each feed's price is multiplied by its normalization factor, then summed and divided by feed count.
    ///      Formula: normalized_price = (original_price * normalization_factor) / feed_count
    /// @param feeds Array of Chainlink feed interfaces
    /// @param feedDecimals Array of decimals for each feed (must match feeds length)
    /// @param feedHeartbeats Array of heartbeats for each feed (must match feeds length)
    /// @param normalizationFactors Array of normalization factors (18 decimals) for each feed (must match feeds length)
    /// @return price The average of normalized prices, normalized to 18 decimals
    function getPrice(
        AggregatorV3Interface[] memory feeds,
        uint8[] memory feedDecimals,
        uint256[] memory feedHeartbeats,
        uint256[] memory normalizationFactors
    ) internal view returns (uint256) {
        uint256 feedCount = feeds.length;
        if (feedCount == 0) revert EmptyFeeds();
        if (feedCount > 50) revert InvalidFeedCount(feedCount); // Reasonable limit
        if (feedDecimals.length != feedCount) revert InvalidFeedCount(feedDecimals.length);
        if (feedHeartbeats.length != feedCount) revert InvalidFeedCount(feedHeartbeats.length);
        if (normalizationFactors.length != feedCount) revert InvalidFeedCount(normalizationFactors.length);

        uint256 sum = 0;
        for (uint256 i = 0; i < feedCount; i++) {
            // Get the price from Chainlink feed (normalized to 18 decimals) with staleness check
            uint256 feedPrice = ChainlinkFeedLib.latestAnswerNormalized(feeds[i], feedDecimals[i], feedHeartbeats[i]);

            // Normalize: price * normalization_factor
            // This scales the price to account for supply differences
            uint256 normalizedPrice = Math.mulDiv(feedPrice, normalizationFactors[i], 1e18);
            sum += normalizedPrice;
        }

        // Average = sum / feedCount
        return sum / feedCount;
    }
}
