// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {Aggregator_stETH_EUR} from "@harbor-price/oracles/Aggregator_stETH_EUR.sol";

/// @notice Ethereum mainnet stETH/EUR oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_EUR_mainnet is Aggregator_stETH_EUR {
    constructor()
        Aggregator_stETH_EUR(
            MainnetRateSources.WSTETH,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            EUR_USD.FEED,
            EUR_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
