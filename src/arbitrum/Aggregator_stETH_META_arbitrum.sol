// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WSTETH_STETH} from "@harbor-price/feeds/chainlink/arbitrum/WSTETH_STETH.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/arbitrum/STETH_USD.sol";
import {META_USD} from "@harbor-price/feeds/chainlink/arbitrum/META_USD.sol";
import {Aggregator_stETH_META} from "@harbor-price/oracles/arbitrum/Aggregator_stETH_META.sol";

/// @notice Arbitrum stETH/META oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_META_arbitrum is Aggregator_stETH_META {
    constructor()
        Aggregator_stETH_META(
            WSTETH_STETH.FEED, // Rate feed (wstETH/stETH)
            STETH_USD.FEED,
            STETH_USD.HEARTBEAT, // First feed heartbeat (stETH/USD)
            META_USD.FEED, // Second feed (META/USD)
            META_USD.HEARTBEAT, // Second feed heartbeat
            1,
            false
        )
    {}
}
