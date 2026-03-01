// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/mainnet/XAU_USD.sol";
import {Aggregator_hsstETH_GOLD_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsstETH_GOLD_USD.sol";

/// @notice Ethereum mainnet hsstETH-GOLD/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsstETH_GOLD_USD_mainnet is Aggregator_hsstETH_GOLD_USD {
    constructor()
        Aggregator_hsstETH_GOLD_USD(
            MainnetRateSources.MINTER_HSSTETH_GOLD,
            XAU_USD.FEED,
            XAU_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
