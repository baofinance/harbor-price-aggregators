// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_DoubleFeed_TwoFeedRate} from "@harbor-price/aggregators/base/Aggregator_DoubleFeed_TwoFeedRate.sol";
import {SUSDE_USD} from "@harbor-price/feeds/chainlink/monad/SUSDE_USD.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/monad/USDE_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/monad/ETH_USD.sol";

/// @notice Monad sUSDe/ETH oracle (rate: SUSDE_USD/USDE_USD, price: USDE_USD/ETH_USD). CL only.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_ETH_monad is Aggregator_DoubleFeed_TwoFeedRate {
    constructor()
        Aggregator_DoubleFeed_TwoFeedRate(
            SUSDE_USD.FEED,
            USDE_USD.FEED,
            SUSDE_USD.HEARTBEAT,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "sUSDe";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "ETH";
    }
}
