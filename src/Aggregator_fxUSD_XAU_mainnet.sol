// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/mainnet/XAU_USD.sol";
import {Aggregator_fxUSD_XAU} from "@harbor-price/oracles/Aggregator_fxUSD_XAU.sol";

/// @notice Ethereum mainnet fxUSD/XAU oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_fxUSD_XAU_mainnet is Aggregator_fxUSD_XAU {
    constructor() Aggregator_fxUSD_XAU(MainnetRateSources.FXSAVE, XAU_USD.FEED, XAU_USD.HEARTBEAT, 1, true) {}
}
