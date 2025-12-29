// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {MCAP_USD} from "@harbor-price/feeds/chainlink/mainnet/MCAP_USD.sol";
import {Aggregator_stETH_MCAP} from "@harbor-price/oracles/Aggregator_stETH_MCAP.sol";

/// @notice Ethereum mainnet stETH/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_stETH_MCAP_mainnet is Aggregator_stETH_MCAP {
    constructor()
        Aggregator_stETH_MCAP(
            MainnetRateSources.STETH,
            MainnetRateSources.WSTETH,
            ETH_USD.FEED,
            MCAP_USD.FEED,
            1e12,
            false
        )
    {}
}
