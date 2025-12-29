// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_USDE_AMZN} from "@harbor-price/price/oracles/arbitrum/Oracle_USDE_AMZN.sol";

/// @notice Arbitrum USDE/AMZN oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_USDE_AMZN_arbitrum is Oracle_USDE_AMZN {
    constructor()
        Oracle_USDE_AMZN(
            "USDE", // Base name (sUSDE)
            ArbitrumOracleAddresses.SUSDE_USDE_FEED, // Rate feed (sUSDE/USDE)
            ArbitrumOracleAddresses.USDE_USD_FEED, // First feed (USDE/USD)
            ArbitrumOracleAddresses.AMZN_USD_FEED, // Second feed (AMZN/USD)
            1,
            false
        )
    {}
}
