// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

library SingleFeedPriceLib {
    function getPrice(
        AggregatorV3Interface feed,
        uint8 feedDecimals,
        uint256 heartbeat,
        uint256 divisor,
        bool invert
    ) internal view returns (uint256) {
        uint256 feedPrice = ChainlinkFeedLib.latestAnswerNormalized(feed, feedDecimals, heartbeat);
        return computeFromValidatedFeedPrice(feedPrice, divisor, invert);
    }

    function computeFromValidatedFeedPrice(
        uint256 feedPrice,
        uint256 divisor,
        bool invert
    ) internal pure returns (uint256) {
        if (invert) {
            // 1e36 * divisor / feedPrice
            return Math.mulDiv(1e18 * divisor, 1e18, feedPrice);
        }
        return feedPrice / divisor;
    }
}
