// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Aggregator_fxUSD_MCAP} from "@harbor-price/oracles/Aggregator_fxUSD_MCAP.sol";

/// @notice Ethereum mainnet fxUSD/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_fxUSD_MCAP_mainnet is Aggregator_fxUSD_MCAP {
    constructor() Aggregator_fxUSD_MCAP(MainnetOracleAddresses.FXSAVE, MainnetOracleAddresses.MCAP_USD_FEED, 1e12, true) {}
}
