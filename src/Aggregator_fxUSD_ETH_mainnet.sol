// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_fxUSD_ETH} from "@harbor-price/aggregators/Aggregator_fxUSD_ETH.sol";

/// @notice Ethereum mainnet fxUSD/ETH oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
/*  */ // solhint-disable-next-line contract-name-capwords
contract Aggregator_fxUSD_ETH_mainnet is Aggregator_fxUSD_ETH {
    constructor() Aggregator_fxUSD_ETH(MainnetRateSources.FXSAVE, ETH_USD.FEED, ETH_USD.HEARTBEAT, 1, true) {}
}
