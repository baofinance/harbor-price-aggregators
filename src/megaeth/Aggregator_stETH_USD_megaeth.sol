// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WSTETH_STETH} from "@harbor-price/feeds/chainlink/megaeth/WSTETH_STETH.sol";
import {STETH_ETH} from "@harbor-price/feeds/chainlink/megaeth/STETH_ETH.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/megaeth/ETH_USD.sol";
import {Aggregator_stETH_USD} from "@harbor-price/aggregators/megaeth/Aggregator_stETH_USD.sol";

/// @notice MegaETH stETH/USD oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_USD_megaeth is Aggregator_stETH_USD {
    constructor()
        Aggregator_stETH_USD(WSTETH_STETH.FEED, STETH_ETH.FEED, STETH_ETH.HEARTBEAT, ETH_USD.FEED, ETH_USD.HEARTBEAT)
    {}
}
