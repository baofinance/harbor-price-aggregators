// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SingleFeedStETHAggregatorTestBase} from "@harbor-price-test/aggregators/SingleFeedStETHAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_stETH_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_ETH.sol";

// Tests: Aggregator_stETH_ETH — stETH/ETH price with wstETH->stETH rate; full suite via SingleFeedWstETHAggregatorTestBase
contract Aggregator_stETH_ETH_Test is SingleFeedStETHAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_stETH_ETH).name;
    }

    function _createAggregator(
        address wsteth,
        address priceFeed,
        uint256 heartbeat,
        uint256 divisor,
        bool invert
    ) internal override returns (IHarborPriceAggregatorV3) {
        return
            IHarborPriceAggregatorV3(address(new Aggregator_stETH_ETH(wsteth, priceFeed, heartbeat, divisor, invert)));
    }

    function _createWithZeroWsteth() internal override {
        new Aggregator_stETH_ETH(address(0), address(mockPriceFeed), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroPriceFeed() internal override {
        new Aggregator_stETH_ETH(address(mockWstETH), address(0), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_stETH_ETH(address(mockWstETH), address(mockPriceFeed), DEFAULT_HEARTBEAT, 0, false);
    }
}
