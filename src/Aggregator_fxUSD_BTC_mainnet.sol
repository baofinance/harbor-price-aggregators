// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {Aggregator_fxUSD_BTC} from "@harbor-price/oracles/Aggregator_fxUSD_BTC.sol";

/// @notice Ethereum mainnet fxUSD/BTC oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
contract Aggregator_fxUSD_BTC_mainnet is Aggregator_fxUSD_BTC {
    constructor() Aggregator_fxUSD_BTC(MainnetRateSources.FXSAVE, BTC_USD.FEED, BTC_USD.HEARTBEAT, 1, true) {}
}
