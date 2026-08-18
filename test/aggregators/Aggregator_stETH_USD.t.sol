// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SingleFeedStETHAggregatorTestBase} from "./SingleFeedStETHAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_stETH_USD} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_USD.sol";

contract Aggregator_stETH_USD_Test is SingleFeedStETHAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_stETH_USD).name;
    }

    function _createAggregator(
        address wsteth,
        address priceFeed,
        uint256 heartbeat,
        uint256 divisor,
        bool invert
    ) internal override returns (IHarborPriceAggregatorV3) {
        return
            IHarborPriceAggregatorV3(address(new Aggregator_stETH_USD(wsteth, priceFeed, heartbeat, divisor, invert)));
    }

    function _createWithZeroWsteth() internal override {
        new Aggregator_stETH_USD(address(0), address(mockPriceFeed), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroPriceFeed() internal override {
        new Aggregator_stETH_USD(address(mockWstETH), address(0), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_stETH_USD(address(mockWstETH), address(mockPriceFeed), DEFAULT_HEARTBEAT, 0, false);
    }
}
