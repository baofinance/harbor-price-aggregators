// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {XAG_USD} from "@harbor-price/feeds/chainlink/mainnet/XAG_USD.sol";
import {Aggregator_stETH_XAG} from "@harbor-price/aggregators/Aggregator_stETH_XAG.sol";

/// @notice Ethereum mainnet stETH/XAG oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_XAG_mainnet is Aggregator_stETH_XAG {
    constructor()
        Aggregator_stETH_XAG(
            MainnetRateSources.WSTETH,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            XAG_USD.FEED,
            XAG_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
