// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_SingleRate_SinglePrice} from "@harbor-price/aggregators/base/Aggregator_SingleRate_SinglePrice.sol";
import {SHMON_MON} from "@harbor-price/feeds/chainlink/monad/SHMON_MON.sol";
import {MON_USD} from "@harbor-price/feeds/chainlink/monad/MON_USD.sol";

/// @notice Monad shMON/USD oracle (rate: SHMON_MON, price = rate * MON_USD). CL only.
// solhint-disable-next-line contract-name-capwords
contract Aggregator_shMON_USD_monad is Aggregator_SingleRate_SinglePrice {
    constructor() Aggregator_SingleRate_SinglePrice(SHMON_MON.FEED, MON_USD.FEED, MON_USD.HEARTBEAT, 1, false) {}

    function _baseName() internal pure override returns (string memory) {
        return "shMON";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }
}
