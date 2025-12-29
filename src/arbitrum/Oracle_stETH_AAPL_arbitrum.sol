// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_stETH_AAPL} from "@harbor-price/price/oracles/arbitrum/Oracle_stETH_AAPL.sol";

/// @notice Arbitrum stETH/AAPL oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_AAPL_arbitrum is Oracle_stETH_AAPL {
    constructor()
        Oracle_stETH_AAPL(
            "stETH", // Base name (stETH doesn't exist as contract on Arbitrum)
            ArbitrumOracleAddresses.WSTETH_STETH_FEED, // Rate feed (wstETH/stETH)
            ArbitrumOracleAddresses.STETH_USD_FEED, // First feed (stETH/USD)
            ArbitrumOracleAddresses.AAPL_USD_FEED, // Second feed (AAPL/USD)
            1,
            false
        )
    {}
}

