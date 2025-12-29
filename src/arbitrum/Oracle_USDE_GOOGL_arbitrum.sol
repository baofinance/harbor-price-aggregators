// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_USDE_GOOGL} from "@harbor-price/price/oracles/arbitrum/Oracle_USDE_GOOGL.sol";

/// @notice Arbitrum USDE/GOOGL oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_USDE_GOOGL_arbitrum is Oracle_USDE_GOOGL {
    constructor()
        Oracle_USDE_GOOGL(
            "USDE", // Base name (sUSDE)
            ArbitrumOracleAddresses.SUSDE_USDE_FEED, // Rate feed (sUSDE/USDE)
            ArbitrumOracleAddresses.USDE_USD_FEED, // First feed (USDE/USD)
            ArbitrumOracleAddresses.GOOGL_USD_FEED, // Second feed (GOOGL/USD)
            1,
            false
        )
    {}
}
