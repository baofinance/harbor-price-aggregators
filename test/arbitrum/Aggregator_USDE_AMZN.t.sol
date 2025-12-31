// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumDoubleFeedAggregatorTestBase} from "./ArbitrumDoubleFeedAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_USDE_AMZN} from "@harbor-price/oracles/arbitrum/Aggregator_USDE_AMZN.sol";

contract Aggregator_USDE_AMZN_Test is ArbitrumDoubleFeedAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_USDE_AMZN).name;
    }

    function _createAggregator(
        address rateFeed,
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
                    new Aggregator_USDE_AMZN(
                        rateFeed,
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

    function _createWithZeroRateFeed() internal override {
        new Aggregator_USDE_AMZN(
            address(0),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroFirstFeed() internal override {
        new Aggregator_USDE_AMZN(
            address(mockRateFeed),
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroSecondFeed() internal override {
        new Aggregator_USDE_AMZN(
            address(mockRateFeed),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_USDE_AMZN(
            address(mockRateFeed),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }
}
