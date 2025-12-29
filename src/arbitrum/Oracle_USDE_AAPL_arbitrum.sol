// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_USDE_AAPL} from "@harbor-price/price/oracles/arbitrum/Oracle_USDE_AAPL.sol";

/// @notice Arbitrum USDE/AAPL oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_USDE_AAPL_arbitrum is Oracle_USDE_AAPL {
    constructor()
        Oracle_USDE_AAPL(
            "USDE", // Base name (USDE doesn't exist as contract on Arbitrum)
            ArbitrumOracleAddresses.SUSDE_USDE_FEED, // Rate feed (sUSDE/USDE)
            ArbitrumOracleAddresses.USDE_USD_FEED, // First feed (USDE/USD)
            ArbitrumOracleAddresses.AAPL_USD_FEED, // Second feed (AAPL/USD)
            1,
            false
        )
    {}
}

