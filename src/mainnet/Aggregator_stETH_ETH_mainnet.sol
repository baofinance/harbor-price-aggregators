// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {STETH_ETH} from "@harbor-price/feeds/chainlink/mainnet/STETH_ETH.sol";
import {Aggregator_stETH_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_ETH.sol";

/// @notice Ethereum mainnet stETH/ETH oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_ETH_mainnet is Aggregator_stETH_ETH {
    constructor()
        Aggregator_stETH_ETH(
            MainnetRateSources.WSTETH,
            STETH_ETH.FEED,
            STETH_ETH.HEARTBEAT,
            1,
            false
        )
    {}
}
