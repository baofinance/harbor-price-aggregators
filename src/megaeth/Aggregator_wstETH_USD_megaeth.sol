// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WSTETH_STETH} from "@harbor-price/feeds/chainlink/megaeth/WSTETH_STETH.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/megaeth/ETH_USD.sol";
import {Aggregator_wstETH_USD} from "@harbor-price/aggregators/megaeth/Aggregator_wstETH_USD.sol";

/// @notice MegaETH wstETH/USD oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wstETH_USD_megaeth is Aggregator_wstETH_USD {
    constructor()
        Aggregator_wstETH_USD(
            WSTETH_STETH.FEED,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
