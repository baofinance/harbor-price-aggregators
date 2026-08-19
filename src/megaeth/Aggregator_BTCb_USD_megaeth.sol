// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BTCb_USD} from "@harbor-price/feeds/chainlink/megaeth/BTCb_USD.sol";
import {Aggregator_BTCb_USD} from "@harbor-price/aggregators/megaeth/Aggregator_BTCb_USD.sol";

/// @notice MegaETH BTC.b/USD oracle (alternative to BTC/USD for wrapped BTC.b).
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_BTCb_USD_megaeth is Aggregator_BTCb_USD {
    constructor() Aggregator_BTCb_USD(BTCb_USD.FEED, BTCb_USD.HEARTBEAT, 1, false) {}
}
