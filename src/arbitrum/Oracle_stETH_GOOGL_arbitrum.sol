// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_stETH_GOOGL} from "@harbor-price/price/oracles/arbitrum/Oracle_stETH_GOOGL.sol";

/// @notice Arbitrum stETH/GOOGL oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_GOOGL_arbitrum is Oracle_stETH_GOOGL {
    constructor()
        Oracle_stETH_GOOGL(
            "stETH", // Base name (wstETH) 
            ArbitrumOracleAddresses.WSTETH_STETH_FEED, // // Rate feed (wstETH/stETH)
            ArbitrumOracleAddresses.STETH_USD_FEED, // First feed (stETH/USD)
            ArbitrumOracleAddresses.GOOGL_USD_FEED, // Second feed (GOOGL/USD)
            1,
            false
        )
    {}
}
