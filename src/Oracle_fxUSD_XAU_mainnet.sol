// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_fxUSD_XAU} from "@harbor-price/price/oracles/Oracle_fxUSD_XAU.sol";

/// @notice Ethereum mainnet fxUSD/XAU oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
contract Oracle_fxUSD_XAU_mainnet is Oracle_fxUSD_XAU {
    constructor()
        Oracle_fxUSD_XAU(
            MainnetOracleAddresses.FXSAVE,
            MainnetOracleAddresses.XAU_USD_FEED,
            1,
            true,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV
        )
    {}
}
