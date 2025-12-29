// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {Aggregator_fxUSD_EUR} from "@harbor-price/oracles/Aggregator_fxUSD_EUR.sol";

/// @notice Ethereum mainnet fxUSD/EUR oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_fxUSD_EUR_mainnet is Aggregator_fxUSD_EUR {
    constructor() Aggregator_fxUSD_EUR(MainnetRateSources.FXSAVE, EUR_USD.FEED, 1, true) {}
}
