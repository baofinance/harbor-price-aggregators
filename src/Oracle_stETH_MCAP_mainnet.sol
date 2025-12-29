// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_stETH_MCAP} from "@harbor-price/price/oracles/Oracle_stETH_MCAP.sol";

/// @notice Ethereum mainnet stETH/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_MCAP_mainnet is Oracle_stETH_MCAP {
    constructor()
        Oracle_stETH_MCAP(
            "stETH", // Base name
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.STETH_USD_FEED,
            MainnetOracleAddresses.MCAP_USD_FEED,
            1e12,
            false
        )
    {}
}
