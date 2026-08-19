// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BTC_USD} from "@harbor-price/feeds/chainlink/megaeth/BTC_USD.sol";
import {Aggregator_BTC_USD} from "@harbor-price/aggregators/megaeth/Aggregator_BTC_USD.sol";

/// @notice MegaETH BTC/USD oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_BTC_USD_megaeth is Aggregator_BTC_USD {
    constructor() Aggregator_BTC_USD(BTC_USD.FEED, BTC_USD.HEARTBEAT, 1, false) {}
}
