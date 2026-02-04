// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DoubleFeedNoRateAggregatorTestBase} from "./DoubleFeedNoRateAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_tBTC_BTC} from "@harbor-price/aggregators/mainnet/Aggregator_tBTC_BTC.sol";

contract Aggregator_tBTC_BTC_Test is DoubleFeedNoRateAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_tBTC_BTC).name;
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
                    new Aggregator_tBTC_BTC(firstFeed, firstHeartbeat, secondFeed, secondHeartbeat, divisor, invert)
                )
            );
    }

    function _createWithZeroFirstFeed() internal override {
        new Aggregator_tBTC_BTC(
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroSecondFeed() internal override {
        new Aggregator_tBTC_BTC(
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_tBTC_BTC(
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }
}
