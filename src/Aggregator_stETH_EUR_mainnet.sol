// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Aggregator_stETH_EUR} from "@harbor-price/oracles/Aggregator_stETH_EUR.sol";

/// @notice Ethereum mainnet stETH/EUR oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_stETH_EUR_mainnet is Aggregator_stETH_EUR {
    constructor()
        Aggregator_stETH_EUR(
            MainnetOracleAddresses.STETH,
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.ETH_USD_FEED,
            MainnetOracleAddresses.EUR_USD_FEED,
            1,
            false
        )
    {}
}
