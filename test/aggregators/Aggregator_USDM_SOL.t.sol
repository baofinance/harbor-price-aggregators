// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DoubleFeedUSDMYAggregatorTestBase} from "@harbor-test/aggregators/DoubleFeedUSDMAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_USDM_SOL} from "@harbor-price/aggregators/megaeth/Aggregator_USDM_SOL.sol";

contract Aggregator_USDM_SOL_Test is DoubleFeedUSDMAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_USDM_SOL).name;
    }

    function _createAggregator(
        address usdmy,
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
                    new Aggregator_USDM_SOL(
                        usdmy,
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

    function _createWithZeroUSDMY() internal override {
        new Aggregator_USDM_SOL(
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
        new Aggregator_USDM_SOL(
            address(mockUSDMY),
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroSecondFeed() internal override {
        new Aggregator_USDM_SOL(
            address(mockUSDMY),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_USDM_SOL(
            address(mockUSDMY),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }
}
