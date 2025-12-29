// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_USDE_NVDA} from "@harbor-price/price/oracles/arbitrum/Oracle_USDE_NVDA.sol";

/// @notice Arbitrum USDE/NVDA oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_USDE_NVDA_arbitrum is Oracle_USDE_NVDA {
    constructor()
        Oracle_USDE_NVDA(
            "USDE", // Base name (sUSDE)
            ArbitrumOracleAddresses.SUSDE_USDE_FEED, // Rate feed (sUSDE/USDE)
            ArbitrumOracleAddresses.USDE_USD_FEED, // First feed (USDE/USD)
            ArbitrumOracleAddresses.NVDA_USD_FEED, // Second feed (NVDA/USD)
            1,
            false
        )
    {}
}
