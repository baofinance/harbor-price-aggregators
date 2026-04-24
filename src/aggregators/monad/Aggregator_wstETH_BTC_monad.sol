// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_DoubleFeed_TwoFeedRate} from "@harbor-price/aggregators/base/Aggregator_DoubleFeed_TwoFeedRate.sol";
import {WSTETH_USD} from "@harbor-price/feeds/chainlink/monad/WSTETH_USD.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/monad/STETH_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/monad/BTC_USD.sol";

/// @notice Monad wstETH/BTC oracle (rate: WSTETH_USD/STETH_USD, price: WSTETH_USD/BTC_USD). CL only.
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wstETH_BTC_monad is Aggregator_DoubleFeed_TwoFeedRate {
    constructor()
        Aggregator_DoubleFeed_TwoFeedRate(
            WSTETH_USD.FEED,
            STETH_USD.FEED,
            WSTETH_USD.HEARTBEAT,
            WSTETH_USD.FEED,
            WSTETH_USD.HEARTBEAT,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "wstETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "BTC";
    }
}
