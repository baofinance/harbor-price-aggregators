// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {SPCX_USD} from "@harbor-price/feeds/chainlink/mainnet/SPCX_USD.sol";
import {Aggregator_stETH_SPCX} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_SPCX.sol";

/// @notice Ethereum mainnet stETH/SPCX oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_SPCX_mainnet is Aggregator_stETH_SPCX {
    constructor()
        Aggregator_stETH_SPCX(
            MainnetRateSources.WSTETH,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            SPCX_USD.FEED,
            SPCX_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
