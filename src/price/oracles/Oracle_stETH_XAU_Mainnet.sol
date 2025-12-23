// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_stETH_XAU} from "@harbor-price/price/oracles/Oracle_stETH_XAU.sol";

/// @notice Ethereum mainnet stETH/XAU oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
contract Oracle_stETH_XAU_Mainnet is Oracle_stETH_XAU {
    constructor()
        Oracle_stETH_XAU(
            MainnetOracleAddresses.STETH,
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.ETH_USD_FEED,
            MainnetOracleAddresses.XAU_USD_FEED,
            1,
            false,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV
        )
    {}
}
