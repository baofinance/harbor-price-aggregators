// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/mainnet/XAU_USD.sol";
import {Aggregator_sUSDe_XAU} from "@harbor-price/aggregators/mainnet/Aggregator_sUSDe_XAU.sol";

/// @notice Ethereum mainnet sUSDe/XAU oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_GOLD_mainnet is Aggregator_sUSDe_XAU {
    constructor()
        Aggregator_sUSDe_XAU(
            MainnetRateSources.SUSDE,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            XAU_USD.FEED,
            XAU_USD.HEARTBEAT,
            1,
            false
        )
    {}

    function _quoteName() internal pure override returns (string memory) {
        return "GOLD";
    }
}
