// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SingleFeedNoRateAggregatorTestBase} from "@harbor-price-test/aggregators/SingleFeedNoRateAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_tBTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_tBTC_USD.sol";

contract Aggregator_tBTC_USD_Test is SingleFeedNoRateAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_tBTC_USD).name;
    }

    function _createAggregator(
        address priceFeed,
        uint256 heartbeat,
        uint256 divisor,
        bool invert
    ) internal override returns (IHarborPriceAggregatorV3) {
        return IHarborPriceAggregatorV3(address(new Aggregator_tBTC_USD(priceFeed, heartbeat, divisor, invert)));
    }

    function _createWithZeroPriceFeed() internal override {
        new Aggregator_tBTC_USD(address(0), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_tBTC_USD(address(mockPriceFeed), DEFAULT_HEARTBEAT, 0, false);
    }
}
