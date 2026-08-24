// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @notice Library to compute a rate as the ratio of two Chainlink price feeds (numerator/denominator).
/// @dev Use when no direct rate feed exists (e.g. Monad: wstETH/stETH = wstETH_USD / stETH_USD).
library TwoFeedRatioRateLib {
    error InvalidRate(uint256 rate);

    /// @notice Get rate = numeratorFeedPrice / denominatorFeedPrice (18 decimals).
    /// @param numeratorFeed Feed for numerator (e.g. wstETH/USD)
    /// @param denominatorFeed Feed for denominator (e.g. stETH/USD)
    /// @param heartbeat Maximum age in seconds for both feeds
    /// @return rate Numerator/denominator normalized to 18 decimals
    function getRate(
        AggregatorV3Interface numeratorFeed,
        AggregatorV3Interface denominatorFeed,
        uint256 heartbeat
    ) internal view returns (uint256 rate) {
        uint8 numDec = numeratorFeed.decimals();
        uint8 denDec = denominatorFeed.decimals();
        uint256 numPrice = ChainlinkFeedLib.latestAnswerNormalized(numeratorFeed, numDec, heartbeat);
        uint256 denPrice = ChainlinkFeedLib.latestAnswerNormalized(denominatorFeed, denDec, heartbeat);
        if (denPrice == 0) revert InvalidRate(0);
        rate = Math.mulDiv(numPrice, 1e18, denPrice);
        if (rate == 0) revert InvalidRate(0);
        return rate;
    }

    /// @notice Get rate with optional min/max validation (e.g. wstETH/stETH ~0.9–3, sUSDE/USDE ~0.9–1.1).
    function getRate(
        AggregatorV3Interface numeratorFeed,
        AggregatorV3Interface denominatorFeed,
        uint256 heartbeat,
        uint256 minRate,
        uint256 maxRate
    ) internal view returns (uint256 rate) {
        rate = getRate(numeratorFeed, denominatorFeed, heartbeat);
        if (rate < minRate || rate > maxRate) revert InvalidRate(rate);
        return rate;
    }
}
