// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {STRC_USD} from "@harbor-price/feeds/chainlink/mainnet/STRC_USD.sol";
import {Aggregator_fxUSD_STRC} from "@harbor-price/aggregators/mainnet/Aggregator_fxUSD_STRC.sol";

/// @notice Ethereum mainnet fxUSD/STRC oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_fxUSD_STRC_mainnet is Aggregator_fxUSD_STRC {
    constructor() Aggregator_fxUSD_STRC(MainnetRateSources.FXSAVE, STRC_USD.FEED, STRC_USD.HEARTBEAT, 1, true) {}
}
