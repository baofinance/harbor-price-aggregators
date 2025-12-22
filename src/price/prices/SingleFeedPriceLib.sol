// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PriceOracle_v1} from "../PriceOracle_v1.sol";

library SingleFeedPriceLib {
    using PriceOracle_v1 for PriceOracle_v1.Feed;

    function getPrice(
        AggregatorV3Interface feed,
        uint8 feedDecimals,
        PriceOracle_v1.Constraints memory constraints,
        uint256 divisor,
        bool invert
    ) internal view returns (uint256) {
        PriceOracle_v1.Feed memory feedData = PriceOracle_v1.Feed({priceFeed: feed, decimals: feedDecimals});
        uint256 feedPrice = feedData.latestAnswer(constraints);
        return computeFromValidatedFeedPrice(feedPrice, divisor, invert);
    }

    function computeFromValidatedFeedPrice(uint256 feedPrice, uint256 divisor, bool invert) internal pure returns (uint256) {
        if (invert) {
            // 1e36 * divisor / feedPrice
            return Math.mulDiv(1e18 * divisor, 1e18, feedPrice);
        }
        return feedPrice / divisor;
    }
}
