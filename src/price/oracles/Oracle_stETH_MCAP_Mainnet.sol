// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_stETH_MCAP} from "@harbor-price/price/oracles/Oracle_stETH_MCAP.sol";

/// @notice Ethereum mainnet stETH/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
contract Oracle_stETH_MCAP_Mainnet is Oracle_stETH_MCAP {
    constructor()
        Oracle_stETH_MCAP(
            MainnetOracleAddresses.STETH,
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.ETH_USD_FEED,
            MainnetOracleAddresses.MCAP_USD_FEED,
            1e12,
            false,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV
        )
    {}
}
