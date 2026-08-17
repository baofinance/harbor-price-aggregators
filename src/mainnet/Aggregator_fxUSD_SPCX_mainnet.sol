// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {SPCX_USD} from "@harbor-price/feeds/chainlink/mainnet/SPCX_USD.sol";
import {Aggregator_fxUSD_SPCX} from "@harbor-price/aggregators/mainnet/Aggregator_fxUSD_SPCX.sol";

/// @notice Ethereum mainnet fxUSD/SPCX oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_fxUSD_SPCX_mainnet is Aggregator_fxUSD_SPCX {
    constructor() Aggregator_fxUSD_SPCX(MainnetRateSources.FXSAVE, SPCX_USD.FEED, SPCX_USD.HEARTBEAT, 1, true) {}
}
