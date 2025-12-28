// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ChainlinkFeedLib} from "../feeds/ChainlinkFeedLib.sol";

library DoubleFeedPriceLib {
    function getPrice(
        AggregatorV3Interface firstFeed,
        uint8 firstDecimals,
        AggregatorV3Interface secondFeed,
        uint8 secondDecimals,
        uint256 divisor,
        bool invert
    ) internal view returns (uint256) {
        uint256 firstFeedPrice = ChainlinkFeedLib.latestAnswerNormalized(firstFeed, firstDecimals);
        uint256 secondFeedPrice = ChainlinkFeedLib.latestAnswerNormalized(secondFeed, secondDecimals);

        if (invert) {
            // Invert: Convert from second feed to first feed
            // Formula: (secondFeedPrice * 1e18) / (firstFeedPrice * divisor)
            return Math.mulDiv(secondFeedPrice, 1e18, Math.mulDiv(firstFeedPrice, divisor, 1));
        }

        // Direct conversion from first feed to second feed
        // Formula: (firstFeedPrice * divisor * 1e18) / secondFeedPrice
        return Math.mulDiv(Math.mulDiv(firstFeedPrice, divisor, 1), 1e18, secondFeedPrice);
    }
}
