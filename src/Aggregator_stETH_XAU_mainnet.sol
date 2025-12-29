// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/mainnet/XAU_USD.sol";
import {Aggregator_stETH_XAU} from "@harbor-price/oracles/Aggregator_stETH_XAU.sol";

/// @notice Ethereum mainnet stETH/XAU oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_stETH_XAU_mainnet is Aggregator_stETH_XAU {
    constructor()
        Aggregator_stETH_XAU(
            MainnetRateSources.STETH,
            MainnetRateSources.WSTETH,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            XAU_USD.FEED,
            XAU_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
