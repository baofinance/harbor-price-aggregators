// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/arbitrum/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/arbitrum/USDE_USD.sol";
import {TSLA_USD} from "@harbor-price/feeds/chainlink/arbitrum/TSLA_USD.sol";
import {Aggregator_USDE_TSLA} from "@harbor-price/oracles/arbitrum/Aggregator_USDE_TSLA.sol";

/// @notice Arbitrum USDE/TSLA oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_TSLA_arbitrum is Aggregator_USDE_TSLA {
    constructor()
        Aggregator_USDE_TSLA(
            SUSDE_USDE.FEED, // Rate feed (sUSDE/USDE)
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT, // First feed heartbeat (USDE/USD)
            TSLA_USD.FEED, // Second feed (TSLA/USD)
            TSLA_USD.HEARTBEAT, // Second feed heartbeat
            1,
            false
        )
    {}
}
