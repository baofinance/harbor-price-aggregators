// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PriceOracle_v1} from "../PriceOracle_v1.sol";

library DoubleFeedPriceLib {
    using PriceOracle_v1 for PriceOracle_v1.Feed;

    function getPrice(
        AggregatorV3Interface firstFeed,
        uint8 firstDecimals,
        PriceOracle_v1.Constraints memory firstConstraints,
        AggregatorV3Interface secondFeed,
        uint8 secondDecimals,
        PriceOracle_v1.Constraints memory secondConstraints,
        uint256 divisor,
        bool invert
    ) internal view returns (uint256) {
        PriceOracle_v1.Feed memory firstFeedData = PriceOracle_v1.Feed({priceFeed: firstFeed, decimals: firstDecimals});
        PriceOracle_v1.Feed memory secondFeedData = PriceOracle_v1.Feed({priceFeed: secondFeed, decimals: secondDecimals});

        uint256 firstFeedPrice = firstFeedData.latestAnswer(firstConstraints);
        uint256 secondFeedPrice = secondFeedData.latestAnswer(secondConstraints);

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
