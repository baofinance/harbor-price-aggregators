// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/arbitrum/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/arbitrum/USDE_USD.sol";
import {META_USD} from "@harbor-price/feeds/chainlink/arbitrum/META_USD.sol";
import {Aggregator_USDE_META} from "@harbor-price/oracles/arbitrum/Aggregator_USDE_META.sol";

/// @notice Arbitrum USDE/META oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_META_arbitrum is Aggregator_USDE_META {
    constructor()
        Aggregator_USDE_META(
            SUSDE_USDE.FEED, // Rate feed (sUSDE/USDE)
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT, // First feed heartbeat (USDE/USD)
            META_USD.FEED, // Second feed (META/USD)
            META_USD.HEARTBEAT, // Second feed heartbeat
            1,
            false
        )
    {}
}
