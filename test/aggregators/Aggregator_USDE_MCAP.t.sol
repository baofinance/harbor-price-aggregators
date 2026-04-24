// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DoubleFeedUSDEAggregatorTestBase} from "./DoubleFeedUSDEAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_USDE_MCAP} from "@harbor-price/aggregators/mainnet/Aggregator_USDE_MCAP.sol";

contract Aggregator_USDE_MCAP_Test is DoubleFeedUSDEAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_USDE_MCAP).name;
    }

    function _createAggregator(
        address susde,
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
                    new Aggregator_USDE_MCAP(
                        susde,
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

    function _createWithZeroSusde() internal override {
        new Aggregator_USDE_MCAP(
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
        new Aggregator_USDE_MCAP(
            address(mockSUSDe),
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroSecondFeed() internal override {
        new Aggregator_USDE_MCAP(
            address(mockSUSDe),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_USDE_MCAP(
            address(mockSUSDe),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }
}

