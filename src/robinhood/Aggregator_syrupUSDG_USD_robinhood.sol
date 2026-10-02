// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SYRUPUSDG_USDG} from "@harbor-price/feeds/chainlink/robinhood/SYRUPUSDG_USDG.sol";
import {USDG_USD} from "@harbor-price/feeds/chainlink/robinhood/USDG_USD.sol";
import {Aggregator_syrupUSDG_USD} from "@harbor-price/aggregators/robinhood/Aggregator_syrupUSDG_USD.sol";

/// @notice Robinhood Chain syrupUSDG/USD oracle.
/// @dev Hard-coded wiring; deploy scripts select this bytecode by chain. Invert is false.
///      Rate is the Chainlink syrupUSDG/USDG proxy; the CCIP token has no working convertToAssets.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_syrupUSDG_USD_robinhood is Aggregator_syrupUSDG_USD {
    constructor() Aggregator_syrupUSDG_USD(SYRUPUSDG_USDG.FEED, USDG_USD.FEED, USDG_USD.HEARTBEAT, 1, false) {}
}
