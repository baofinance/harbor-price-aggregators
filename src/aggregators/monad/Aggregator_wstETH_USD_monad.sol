// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_DirectPrice_TwoFeedRate} from "@harbor-price/aggregators/base/Aggregator_DirectPrice_TwoFeedRate.sol";
import {WSTETH_USD} from "@harbor-price/feeds/chainlink/monad/WSTETH_USD.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/monad/STETH_USD.sol";

/// @notice Monad wstETH/USD oracle: direct WSTETH_USD price, rate = WSTETH_USD/STETH_USD (for harvest based on stETH). CL only.
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wstETH_USD_monad is Aggregator_DirectPrice_TwoFeedRate {
    constructor()
        Aggregator_DirectPrice_TwoFeedRate(
            WSTETH_USD.FEED,
            STETH_USD.FEED,
            WSTETH_USD.HEARTBEAT,
            WSTETH_USD.FEED,
            WSTETH_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "wstETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }
}
