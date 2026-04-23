// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/mainnet/STETH_USD.sol";
import {Aggregator_stETH_USD} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_USD.sol";

/// @notice Ethereum mainnet stETH/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_USD_mainnet is Aggregator_stETH_USD {
    constructor()
        Aggregator_stETH_USD(
            MainnetRateSources.WSTETH,
            STETH_USD.FEED,
            STETH_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
