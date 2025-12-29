// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_fxUSD_ETH} from "@harbor-price/price/oracles/Oracle_fxUSD_ETH.sol";

/// @notice Ethereum mainnet fxUSD/ETH oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Oracle_fxUSD_ETH_mainnet is Oracle_fxUSD_ETH {
    constructor() Oracle_fxUSD_ETH("fxUSD", MainnetOracleAddresses.FXSAVE, MainnetOracleAddresses.ETH_USD_FEED, 1, true) {}
}
