// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_fxUSD_MCAP} from "@harbor-price/price/oracles/Oracle_fxUSD_MCAP.sol";

/// @notice Ethereum mainnet fxUSD/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
contract Oracle_fxUSD_MCAP_Mainnet is Oracle_fxUSD_MCAP {
    constructor()
        Oracle_fxUSD_MCAP(
            MainnetOracleAddresses.FXSAVE,
            MainnetOracleAddresses.MCAP_USD_FEED,
            1e12,
            true,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV
        )
    {}
}
