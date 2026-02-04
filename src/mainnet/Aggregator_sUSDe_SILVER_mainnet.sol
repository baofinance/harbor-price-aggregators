// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {XAG_USD} from "@harbor-price/feeds/chainlink/mainnet/XAG_USD.sol";
import {Aggregator_sUSDe_XAG} from "@harbor-price/aggregators/mainnet/Aggregator_sUSDe_XAG.sol";

/// @notice Ethereum mainnet sUSDe/XAG oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_SILVER_mainnet is Aggregator_sUSDe_XAG {
    constructor()
        Aggregator_sUSDe_XAG(
            MainnetRateSources.SUSDE,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
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
