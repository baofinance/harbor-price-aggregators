// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_stETH_EUR} from "@harbor-price/price/oracles/Oracle_stETH_EUR.sol";

/// @notice Ethereum mainnet stETH/EUR oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
contract Oracle_stETH_EUR_mainnet is Oracle_stETH_EUR {
    constructor()
        Oracle_stETH_EUR(
            MainnetOracleAddresses.STETH,
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.ETH_USD_FEED,
            MainnetOracleAddresses.EUR_USD_FEED,
            1,
            false,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV
        )
    {}
}
