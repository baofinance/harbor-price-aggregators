// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/mainnet/STETH_USD.sol";
import {XAG_USD} from "@harbor-price/feeds/chainlink/mainnet/XAG_USD.sol";
import {Aggregator_stETH_XAG} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_XAG.sol";

/// @notice Ethereum mainnet stETH/XAG oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_SILVER_mainnet is Aggregator_stETH_XAG {
    constructor()
        Aggregator_stETH_XAG(
            MainnetRateSources.WSTETH,
            STETH_USD.FEED,
            STETH_USD.HEARTBEAT,
            XAG_USD.FEED,
            XAG_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _quoteName() internal pure override returns (string memory) {
        return "SILVER";
    }
}
