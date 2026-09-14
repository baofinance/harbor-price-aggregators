// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// solhint-disable-next-line max-line-length
import {DoubleFeedTwoFeedRateHarness} from "@harbor-price-test/conformance/shapes/DoubleFeedTwoFeedRateHarness.sol";
import {Aggregator_wstETH_BTC_monad} from "@harbor-price/monad/Aggregator_wstETH_BTC_monad.sol";
import {WSTETH_USD} from "@harbor-price/feeds/chainlink/monad/WSTETH_USD.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/monad/STETH_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/monad/BTC_USD.sol";

contract Aggregator_wstETH_BTC_monad_Test is DoubleFeedTwoFeedRateHarness {
    function _rateNumeratorFeed() internal pure override returns (address) {
        return WSTETH_USD.FEED;
    }

    function _rateDenominatorFeed() internal pure override returns (address) {
        return STETH_USD.FEED;
    }

    function _firstFeed() internal pure override returns (address) {
        return WSTETH_USD.FEED;
    }

    function _secondFeed() internal pure override returns (address) {
        return BTC_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_wstETH_BTC_monad());
    }
}
