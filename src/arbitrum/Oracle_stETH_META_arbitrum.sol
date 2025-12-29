// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_stETH_META} from "@harbor-price/price/oracles/arbitrum/Oracle_stETH_META.sol";

/// @notice Arbitrum stETH/META oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_META_arbitrum is Oracle_stETH_META {
    constructor()
        Oracle_stETH_META(
            "stETH", // Base name (wstETH) 
            ArbitrumOracleAddresses.WSTETH_STETH_FEED, // // Rate feed (wstETH/stETH)
            ArbitrumOracleAddresses.STETH_USD_FEED, // First feed (stETH/USD)
            ArbitrumOracleAddresses.META_USD_FEED, // Second feed (META/USD)
            1,
            false
        )
    {}
}
