// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {Aggregator_sUSDe_BTC} from "@harbor-price/aggregators/mainnet/Aggregator_sUSDe_BTC.sol";

/// @notice Ethereum mainnet sUSDe/BTC oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_BTC_mainnet is Aggregator_sUSDe_BTC {
    constructor()
        Aggregator_sUSDe_BTC(
            MainnetRateSources.SUSDE,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
