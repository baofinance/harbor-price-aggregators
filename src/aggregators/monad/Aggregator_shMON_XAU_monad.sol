// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_SingleRate_DoublePrice} from "@harbor-price/aggregators/base/Aggregator_SingleRate_DoublePrice.sol";
import {SHMON_MON} from "@harbor-price/feeds/chainlink/monad/SHMON_MON.sol";
import {MON_USD} from "@harbor-price/feeds/chainlink/monad/MON_USD.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/monad/XAU_USD.sol";

/// @notice Monad shMON/XAU oracle (rate: SHMON_MON, price = rate * MON_USD/XAU_USD). CL only.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_shMON_XAU_monad is Aggregator_SingleRate_DoublePrice {
    constructor()
        Aggregator_SingleRate_DoublePrice(
            SHMON_MON.FEED,
            MON_USD.FEED,
            MON_USD.HEARTBEAT,
            XAU_USD.FEED,
            XAU_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "shMON";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "XAU";
    }
}
