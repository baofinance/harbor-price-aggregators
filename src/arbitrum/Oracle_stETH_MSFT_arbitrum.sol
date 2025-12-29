// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_stETH_MSFT} from "@harbor-price/price/oracles/arbitrum/Oracle_stETH_MSFT.sol";

/// @notice Arbitrum stETH/MSFT oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_MSFT_arbitrum is Oracle_stETH_MSFT {
    constructor()
        Oracle_stETH_MSFT(
            "stETH", // Base name (wstETH) 
            ArbitrumOracleAddresses.WSTETH_STETH_FEED, // // Rate feed (wstETH/stETH)
            ArbitrumOracleAddresses.STETH_USD_FEED, // First feed (stETH/USD)
            ArbitrumOracleAddresses.MSFT_USD_FEED, // Second feed (MSFT/USD)
            1,
            false
        )
    {}
}
