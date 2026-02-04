// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {MCAP_USD} from "@harbor-price/feeds/chainlink/mainnet/MCAP_USD.sol";
import {Aggregator_sUSDe_MCAP} from "@harbor-price/aggregators/mainnet/Aggregator_sUSDe_MCAP.sol";

/// @notice Ethereum mainnet sUSDe/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_MCAP_mainnet is Aggregator_sUSDe_MCAP {
    constructor()
        Aggregator_sUSDe_MCAP(
            MainnetRateSources.SUSDE,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            MCAP_USD.FEED,
            MCAP_USD.HEARTBEAT,
            1e12,
            false
        )
    {}
}
