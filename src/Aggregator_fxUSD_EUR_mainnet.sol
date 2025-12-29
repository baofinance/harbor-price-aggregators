// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Aggregator_fxUSD_EUR} from "@harbor-price/oracles/Aggregator_fxUSD_EUR.sol";

/// @notice Ethereum mainnet fxUSD/EUR oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_fxUSD_EUR_mainnet is Aggregator_fxUSD_EUR {
    constructor() Aggregator_fxUSD_EUR(MainnetOracleAddresses.FXSAVE, MainnetOracleAddresses.EUR_USD_FEED, 1, true) {}
}
