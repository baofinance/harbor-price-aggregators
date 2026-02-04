// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DoubleFeedNoRateAggregatorTestBase} from "./DoubleFeedNoRateAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_wBTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_wBTC_USD.sol";

contract Aggregator_wBTC_USD_Test is DoubleFeedNoRateAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_wBTC_USD).name;
    }

    function _createAggregator(
        address firstFeed,
        uint256 firstHeartbeat,
        address secondFeed,
        uint256 secondHeartbeat,
        uint256 divisor,
        bool invert
    ) internal override returns (IHarborPriceAggregatorV3) {
        return
            IHarborPriceAggregatorV3(
                address(
                    new Aggregator_wBTC_USD(firstFeed, firstHeartbeat, secondFeed, secondHeartbeat, divisor, invert)
                )
            );
    }

    function _createWithZeroFirstFeed() internal override {
        new Aggregator_wBTC_USD(
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroSecondFeed() internal override {
        new Aggregator_wBTC_USD(
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_wBTC_USD(
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }
}
