// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {XAG_USD} from "@harbor-price/feeds/chainlink/mainnet/XAG_USD.sol";
import {Aggregator_fxUSD_XAG} from "@harbor-price/aggregators/mainnet/Aggregator_fxUSD_XAG.sol";

/// @notice Ethereum mainnet fxUSD/XAG oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_fxUSD_SILVER_mainnet is Aggregator_fxUSD_XAG {
    constructor() Aggregator_fxUSD_XAG(MainnetRateSources.FXSAVE, XAG_USD.FEED, XAG_USD.HEARTBEAT, 1, true) {}

    function _quoteName() internal pure override returns (string memory) {
        return "SILVER";
    }
}
