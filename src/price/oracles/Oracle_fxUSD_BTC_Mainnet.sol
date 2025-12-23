// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_fxUSD_BTC} from "@harbor-price/price/oracles/Oracle_fxUSD_BTC.sol";

/// @notice Ethereum mainnet fxUSD/BTC oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
contract Oracle_fxUSD_BTC_Mainnet is Oracle_fxUSD_BTC {
    constructor()
        Oracle_fxUSD_BTC(
            MainnetOracleAddresses.FXSAVE,
            MainnetOracleAddresses.BTC_USD_FEED,
            1,
            true,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV
        )
    {}
}
