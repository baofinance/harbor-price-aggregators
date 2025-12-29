// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_stETH_BTC} from "@harbor-price/price/oracles/Oracle_stETH_BTC.sol";

/// @notice Ethereum mainnet stETH/BTC oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_stETH_BTC_mainnet is Oracle_stETH_BTC {
    constructor()
        Oracle_stETH_BTC(
            "stETH", // Base name
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.STETH_USD_FEED,
            MainnetOracleAddresses.BTC_USD_FEED,
            1,
            false
        )
    {}
}
