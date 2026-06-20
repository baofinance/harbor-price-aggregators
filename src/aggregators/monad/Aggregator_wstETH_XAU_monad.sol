// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_DoubleFeed_TwoFeedRate} from "@harbor-price/aggregators/base/Aggregator_DoubleFeed_TwoFeedRate.sol";
import {WSTETH_USD} from "@harbor-price/feeds/chainlink/monad/WSTETH_USD.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/monad/STETH_USD.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/monad/XAU_USD.sol";

/// @notice Monad wstETH/XAU oracle (rate: WSTETH_USD/STETH_USD, price: WSTETH_USD/XAU_USD). CL only.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wstETH_XAU_monad is Aggregator_DoubleFeed_TwoFeedRate {
    constructor()
        Aggregator_DoubleFeed_TwoFeedRate(
            WSTETH_USD.FEED,
            STETH_USD.FEED,
            WSTETH_USD.HEARTBEAT,
            WSTETH_USD.FEED,
            WSTETH_USD.HEARTBEAT,
            XAU_USD.FEED,
            XAU_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "wstETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "XAU";
    }
}
