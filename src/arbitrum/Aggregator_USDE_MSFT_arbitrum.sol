// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/arbitrum/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/arbitrum/USDE_USD.sol";
import {MSFT_USD} from "@harbor-price/feeds/chainlink/arbitrum/MSFT_USD.sol";
import {Aggregator_USDE_MSFT} from "@harbor-price/oracles/arbitrum/Aggregator_USDE_MSFT.sol";

/// @notice Arbitrum USDE/MSFT oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_MSFT_arbitrum is Aggregator_USDE_MSFT {
    constructor()
        Aggregator_USDE_MSFT(
            SUSDE_USDE.FEED, // Rate feed (sUSDE/USDE)
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT, // First feed heartbeat (USDE/USD)
            MSFT_USD.FEED, // Second feed (MSFT/USD)
            MSFT_USD.HEARTBEAT, // Second feed heartbeat
            1,
            false
        )
    {}
}
