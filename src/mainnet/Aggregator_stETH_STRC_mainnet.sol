// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {STRC_USD} from "@harbor-price/feeds/chainlink/mainnet/STRC_USD.sol";
import {Aggregator_stETH_STRC} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_STRC.sol";

/// @notice Ethereum mainnet stETH/STRC oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_STRC_mainnet is Aggregator_stETH_STRC {
    constructor()
        Aggregator_stETH_STRC(
            MainnetRateSources.WSTETH,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            STRC_USD.FEED,
            STRC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
