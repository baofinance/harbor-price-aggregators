// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Aggregator_fxUSD_XAU} from "@harbor-price/oracles/Aggregator_fxUSD_XAU.sol";

/// @notice Ethereum mainnet fxUSD/XAU oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_fxUSD_XAU_mainnet is Aggregator_fxUSD_XAU {
    constructor() Aggregator_fxUSD_XAU(MainnetOracleAddresses.FXSAVE, MainnetOracleAddresses.XAU_USD_FEED, 1, true) {}
}
