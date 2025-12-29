// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_USDE_MAG7} from "@harbor-price/price/oracles/arbitrum/Oracle_USDE_MAG7.sol";

/// @notice Arbitrum USDE/MAG7 oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_USDE_MAG7_arbitrum is Oracle_USDE_MAG7 {
    constructor()
        Oracle_USDE_MAG7(
            "USDE", // Base name (USDE doesn't exist as contract on Arbitrum)
            ArbitrumOracleAddresses.SUSDE_USDE_FEED, // Rate feed (sUSDE/USDE)
            ArbitrumOracleAddresses.USDE_USD_FEED, // Base USD feed (USDE/USD)
            ArbitrumOracleAddresses.AAPL_USD_FEED, // Feed 0
            ArbitrumOracleAddresses.MSFT_USD_FEED, // Feed 1
            ArbitrumOracleAddresses.TSLA_USD_FEED, // Feed 2
            ArbitrumOracleAddresses.GOOGL_USD_FEED, // Feed 3
            ArbitrumOracleAddresses.META_USD_FEED, // Feed 4
            ArbitrumOracleAddresses.AMZN_USD_FEED, // Feed 5
            ArbitrumOracleAddresses.NVDA_USD_FEED // Feed 6
        )
    {}
}

