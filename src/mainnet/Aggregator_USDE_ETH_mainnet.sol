// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_USDE_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_USDE_ETH.sol";

/// @notice Ethereum mainnet USDE/ETH oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_ETH_mainnet is Aggregator_USDE_ETH {
    constructor()
        Aggregator_USDE_ETH(
            MainnetRateSources.SUSDE,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
