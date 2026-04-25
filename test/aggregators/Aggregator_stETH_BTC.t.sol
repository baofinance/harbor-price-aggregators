// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DoubleFeedAggregatorTestBase} from "@harbor-test/aggregators/DoubleFeedAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_stETH_BTC} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_BTC.sol";

contract Aggregator_stETH_BTC_Test is DoubleFeedAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_stETH_BTC).name;
    }

    function _createAggregator(
        address wsteth,
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
                    new Aggregator_stETH_BTC(
                        wsteth,
                        firstFeed,
                        firstHeartbeat,
                        secondFeed,
                        secondHeartbeat,
                        divisor,
                        invert
                    )
                )
            );
    }

    function _createWithZeroWsteth() internal override {
        new Aggregator_stETH_BTC(
            address(0),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            true
        );
    }

    function _createWithZeroFirstFeed() internal override {
        new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            true
        );
    }

    function _createWithZeroSecondFeed() internal override {
        new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            true
        );
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            true
        );
    }
}
