// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WSTETH_STETH} from "@harbor-price/feeds/chainlink/arbitrum/WSTETH_STETH.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/arbitrum/STETH_USD.sol";
import {MSFT_USD} from "@harbor-price/feeds/chainlink/arbitrum/MSFT_USD.sol";
import {Aggregator_stETH_MSFT} from "@harbor-price/oracles/arbitrum/Aggregator_stETH_MSFT.sol";

/// @notice Arbitrum stETH/MSFT oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_MSFT_arbitrum is Aggregator_stETH_MSFT {
    constructor()
        Aggregator_stETH_MSFT(
            WSTETH_STETH.FEED, // Rate feed (wstETH/stETH)
            STETH_USD.FEED,
            STETH_USD.HEARTBEAT, // First feed heartbeat (stETH/USD)
            MSFT_USD.FEED, // Second feed (MSFT/USD)
            MSFT_USD.HEARTBEAT, // Second feed heartbeat
            1,
            false
        )
    {}
}
