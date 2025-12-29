// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_stETH_NVDA} from "@harbor-price/price/oracles/arbitrum/Oracle_stETH_NVDA.sol";

/// @notice Arbitrum stETH/NVDA oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_NVDA_arbitrum is Oracle_stETH_NVDA {
    constructor()
        Oracle_stETH_NVDA(
            "stETH", // Base name (wstETH) 
            ArbitrumOracleAddresses.WSTETH_STETH_FEED, // Rate feed (wstETH/stETH)
            ArbitrumOracleAddresses.STETH_USD_FEED, // First feed (stETH/USD)
            ArbitrumOracleAddresses.NVDA_USD_FEED, // Second feed (NVDA/USD)
            1,
            false
        )
    {}
}
