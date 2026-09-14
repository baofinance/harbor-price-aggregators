// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SingleRateSinglePriceHarness} from "@harbor-price-test/conformance/shapes/SingleRateSinglePriceHarness.sol";
import {Aggregator_shMON_USD_monad} from "@harbor-price/monad/Aggregator_shMON_USD_monad.sol";
import {SHMON_MON} from "@harbor-price/feeds/chainlink/monad/SHMON_MON.sol";
import {MON_USD} from "@harbor-price/feeds/chainlink/monad/MON_USD.sol";

contract Aggregator_shMON_USD_monad_Test is SingleRateSinglePriceHarness {
    function _rateFeed() internal pure override returns (address) {
        return SHMON_MON.FEED;
    }

    function _priceFeed() internal pure override returns (address) {
        return MON_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_shMON_USD_monad());
    }
}
