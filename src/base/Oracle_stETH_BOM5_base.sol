// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseOracleAddresses} from "@harbor-price/price/BaseOracleAddresses.sol";
import {Oracle_stETH_BOM5} from "@harbor-price/price/oracles/base/Oracle_stETH_BOM5.sol";

/// @notice Base stETH/BOM5 oracle.
/// @dev Hard-coded wiring for Base; deploy scripts select this bytecode by chain.
///      BOM5 = Bag of Memes 5 (DOGE, SHIB, PEPE, TRUMP, WIF) with supply normalization.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_BOM5_base is Oracle_stETH_BOM5 {
    constructor()
        Oracle_stETH_BOM5(
            "stETH", // Base name (stETH doesn't exist as contract on Base)
            BaseOracleAddresses.WSTETH_STETH_FEED, // Rate feed
            BaseOracleAddresses.STETH_USD_FEED, // Base USD feed (stETH/USD)
            BaseOracleAddresses.DOGE_USD_FEED, // Feed 0 (DOGE)
            BaseOracleAddresses.SHIB_USD_FEED, // Feed 1 (SHIB)
            BaseOracleAddresses.PEPE_USD_FEED, // Feed 2 (PEPE)
            BaseOracleAddresses.TRUMP_USD_FEED, // Feed 3 (TRUMP)
            BaseOracleAddresses.WIF_USD_FEED, // Feed 4 (WIF)
            BaseOracleAddresses.DOGE_NORM_FACTOR, // Normalization factor 0
            BaseOracleAddresses.SHIB_NORM_FACTOR, // Normalization factor 1
            BaseOracleAddresses.PEPE_NORM_FACTOR, // Normalization factor 2
            BaseOracleAddresses.TRUMP_NORM_FACTOR, // Normalization factor 3
            BaseOracleAddresses.WIF_NORM_FACTOR // Normalization factor 4
        )
    {}
}

