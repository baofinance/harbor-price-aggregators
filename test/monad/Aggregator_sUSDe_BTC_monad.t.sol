// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// solhint-disable-next-line max-line-length
import {DoubleFeedTwoFeedRateHarness} from "@harbor-price-test/conformance/shapes/DoubleFeedTwoFeedRateHarness.sol";
import {Aggregator_sUSDe_BTC_monad} from "@harbor-price/monad/Aggregator_sUSDe_BTC_monad.sol";
import {SUSDE_USD} from "@harbor-price/feeds/chainlink/monad/SUSDE_USD.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/monad/USDE_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/monad/BTC_USD.sol";

contract Aggregator_sUSDe_BTC_monad_Test is DoubleFeedTwoFeedRateHarness {
    function _rateNumeratorFeed() internal pure override returns (address) {
        return SUSDE_USD.FEED;
    }

    function _rateDenominatorFeed() internal pure override returns (address) {
        return USDE_USD.FEED;
    }

    function _firstFeed() internal pure override returns (address) {
        return USDE_USD.FEED;
    }

    function _secondFeed() internal pure override returns (address) {
        return BTC_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_sUSDe_BTC_monad());
    }
}
