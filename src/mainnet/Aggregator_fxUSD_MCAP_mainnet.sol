// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {MCAP_USD} from "@harbor-price/feeds/chainlink/mainnet/MCAP_USD.sol";
import {Aggregator_fxUSD_MCAP} from "@harbor-price/aggregators/mainnet/Aggregator_fxUSD_MCAP.sol";

/// @notice Ethereum mainnet fxUSD/MCAP oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_fxUSD_MCAP_mainnet is Aggregator_fxUSD_MCAP {
    constructor() Aggregator_fxUSD_MCAP(MainnetRateSources.FXSAVE, MCAP_USD.FEED, MCAP_USD.HEARTBEAT, 1e12, true) {}
}
