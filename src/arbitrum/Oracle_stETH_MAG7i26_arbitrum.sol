// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumOracleAddresses} from "@harbor-price/price/ArbitrumOracleAddresses.sol";
import {Oracle_stETH_MAG7i26} from "@harbor-price/price/oracles/arbitrum/Oracle_stETH_MAG7i26.sol";

/// @notice Arbitrum stETH/MAG7.i26 oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_MAG7i26_arbitrum is Oracle_stETH_MAG7i26 {
    constructor()
        Oracle_stETH_MAG7i26(
            "stETH", // Base name (stETH doesn't exist as contract on Arbitrum)
            ArbitrumOracleAddresses.WSTETH_STETH_FEED, // Rate feed
            ArbitrumOracleAddresses.STETH_USD_FEED, // Base USD feed (stETH/USD)
            ArbitrumOracleAddresses.MAG7_I26_INDEX_PRICE, // Index price (sum of 7 stocks on 1-1-2026)
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

