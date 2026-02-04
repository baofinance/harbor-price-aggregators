// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {Aggregator_sUSDe_EUR} from "@harbor-price/aggregators/mainnet/Aggregator_sUSDe_EUR.sol";

/// @notice Ethereum mainnet sUSDe/EUR oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_EUR_mainnet is Aggregator_sUSDe_EUR {
    constructor()
        Aggregator_sUSDe_EUR(
            MainnetRateSources.SUSDE,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            EUR_USD.FEED,
            EUR_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
