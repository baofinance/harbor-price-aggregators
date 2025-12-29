// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Aggregator_stETH_MCAP} from "@harbor-price/oracles/Aggregator_stETH_MCAP.sol";

/// @notice Ethereum mainnet stETH/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_stETH_MCAP_mainnet is Aggregator_stETH_MCAP {
    constructor()
        Aggregator_stETH_MCAP(
            MainnetOracleAddresses.STETH,
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.ETH_USD_FEED,
            MainnetOracleAddresses.MCAP_USD_FEED,
            1e12,
            false
        )
    {}
}
