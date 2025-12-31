// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/arbitrum/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/arbitrum/USDE_USD.sol";
import {AAPL_USD} from "@harbor-price/feeds/chainlink/arbitrum/AAPL_USD.sol";
import {Aggregator_USDE_AAPL} from "@harbor-price/oracles/arbitrum/Aggregator_USDE_AAPL.sol";

/// @notice Arbitrum USDE/AAPL oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_AAPL_arbitrum is Aggregator_USDE_AAPL {
    constructor()
        Aggregator_USDE_AAPL(
            SUSDE_USDE.FEED, // Rate feed (sUSDE/USDE)
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT, // First feed heartbeat (USDE/USD)
            AAPL_USD.FEED, // Second feed (AAPL/USD)
            AAPL_USD.HEARTBEAT, // Second feed heartbeat
            1,
            false
        )
    {}
}
