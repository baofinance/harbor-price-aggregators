// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SingleFeedAggregatorTestBase} from "./SingleFeedAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_fxUSD_EUR} from "@harbor-price/aggregators/mainnet/Aggregator_fxUSD_EUR.sol";

contract Aggregator_fxUSD_EUR_Test is SingleFeedAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_fxUSD_EUR).name;
    }

    function _createAggregator(
        address fxsave,
        address priceFeed,
        uint256 heartbeat,
        uint256 divisor,
        bool invert
    ) internal override returns (IHarborPriceAggregatorV3) {
        return
            IHarborPriceAggregatorV3(address(new Aggregator_fxUSD_EUR(fxsave, priceFeed, heartbeat, divisor, invert)));
    }

    function _createWithZeroFxsave() internal override {
        new Aggregator_fxUSD_EUR(address(0), address(mockPriceFeed), DEFAULT_HEARTBEAT, 1, true);
    }

    function _createWithZeroPriceFeed() internal override {
        new Aggregator_fxUSD_EUR(address(mockFxSave), address(0), DEFAULT_HEARTBEAT, 1, true);
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_fxUSD_EUR(address(mockFxSave), address(mockPriceFeed), DEFAULT_HEARTBEAT, 0, true);
    }
}
