// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_SingleRate_DoublePrice} from "@harbor-price/aggregators/base/Aggregator_SingleRate_DoublePrice.sol";
import {SHMON_MON} from "@harbor-price/feeds/chainlink/monad/SHMON_MON.sol";
import {MON_USD} from "@harbor-price/feeds/chainlink/monad/MON_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/monad/ETH_USD.sol";

/// @notice Monad shMON/ETH oracle (rate: SHMON_MON, price = rate * MON_USD/ETH_USD). CL only.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_shMON_ETH_monad is Aggregator_SingleRate_DoublePrice {
    constructor()
        Aggregator_SingleRate_DoublePrice(
            SHMON_MON.FEED,
            MON_USD.FEED,
            MON_USD.HEARTBEAT,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "shMON";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "ETH";
    }
}
