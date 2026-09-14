// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// solhint-disable-next-line max-line-length
import {DirectPriceTwoFeedRateHarness} from "@harbor-price-test/conformance/shapes/DirectPriceTwoFeedRateHarness.sol";
import {Aggregator_wstETH_USD_monad} from "@harbor-price/monad/Aggregator_wstETH_USD_monad.sol";
import {WSTETH_USD} from "@harbor-price/feeds/chainlink/monad/WSTETH_USD.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/monad/STETH_USD.sol";

contract Aggregator_wstETH_USD_monad_Test is DirectPriceTwoFeedRateHarness {
    function _rateNumeratorFeed() internal pure override returns (address) {
        return WSTETH_USD.FEED;
    }

    function _rateDenominatorFeed() internal pure override returns (address) {
        return STETH_USD.FEED;
    }

    function _priceFeed() internal pure override returns (address) {
        return WSTETH_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_wstETH_USD_monad());
    }
}
