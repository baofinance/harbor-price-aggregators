// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_USDE_TSLA} from "@harbor-price/price/oracles/arbitrum/Oracle_USDE_TSLA.sol";

/// @notice Arbitrum USDE/TSLA oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_USDE_TSLA_arbitrum is Oracle_USDE_TSLA {
    constructor()
        Oracle_USDE_TSLA(
            "USDE", // Base name (sUSDE)
            ArbitrumOracleAddresses.SUSDE_USDE_FEED, // Rate feed (sUSDE/USDE)
            ArbitrumOracleAddresses.USDE_USD_FEED, // First feed (USDE/USD)
            ArbitrumOracleAddresses.TSLA_USD_FEED, // Second feed (TSLA/USD)
            1,
            false
        )
    {}
}
