// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// solhint-disable-next-line max-line-length
import {SingleRateDoublePriceHarness} from "@harbor-price-test/conformance/shapes/SingleRateDoublePriceHarness.sol";
import {Aggregator_shMON_XAU_monad} from "@harbor-price/aggregators/monad/Aggregator_shMON_XAU_monad.sol";
import {SHMON_MON} from "@harbor-price/feeds/chainlink/monad/SHMON_MON.sol";
import {MON_USD} from "@harbor-price/feeds/chainlink/monad/MON_USD.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/monad/XAU_USD.sol";

contract Aggregator_shMON_XAU_monad_Test is SingleRateDoublePriceHarness {
    function _rateFeed() internal pure override returns (address) {
        return SHMON_MON.FEED;
    }

    function _firstFeed() internal pure override returns (address) {
        return MON_USD.FEED;
    }

    function _secondFeed() internal pure override returns (address) {
        return XAU_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_shMON_XAU_monad());
    }
}
