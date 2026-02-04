// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/mainnet/STETH_USD.sol";
import {Aggregator_wstETH_USD} from "@harbor-price/aggregators/mainnet/Aggregator_wstETH_USD.sol";

/// @notice Ethereum mainnet wstETH/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wstETH_USD_mainnet is Aggregator_wstETH_USD {
    constructor()
        Aggregator_wstETH_USD(
            MainnetRateSources.WSTETH,
            STETH_USD.FEED,
            STETH_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
