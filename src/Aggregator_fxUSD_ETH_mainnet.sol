// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Aggregator_fxUSD_ETH} from "@harbor-price/oracles/Aggregator_fxUSD_ETH.sol";

/// @notice Ethereum mainnet fxUSD/ETH oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_fxUSD_ETH_mainnet is Aggregator_fxUSD_ETH {
    constructor() Aggregator_fxUSD_ETH(MainnetOracleAddresses.FXSAVE, MainnetOracleAddresses.ETH_USD_FEED, 1, true) {}
}
