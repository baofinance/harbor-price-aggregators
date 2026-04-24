// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_DoubleFeed_TwoFeedRate} from "@harbor-price/aggregators/base/Aggregator_DoubleFeed_TwoFeedRate.sol";
import {SUSDE_USD} from "@harbor-price/feeds/chainlink/monad/SUSDE_USD.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/monad/USDE_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/monad/BTC_USD.sol";

/// @notice Monad sUSDe/BTC oracle (rate: SUSDE_USD/USDE_USD, price: USDE_USD/BTC_USD). CL only.
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_BTC_monad is Aggregator_DoubleFeed_TwoFeedRate {
    constructor()
        Aggregator_DoubleFeed_TwoFeedRate(
            SUSDE_USD.FEED,
            USDE_USD.FEED,
            SUSDE_USD.HEARTBEAT,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "sUSDe";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "BTC";
    }
}
