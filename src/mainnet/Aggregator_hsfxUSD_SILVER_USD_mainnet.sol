// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {XAG_USD} from "@harbor-price/feeds/chainlink/mainnet/XAG_USD.sol";
import {Aggregator_hsfxUSD_SILVER_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsfxUSD_SILVER_USD.sol";

/// @notice Ethereum mainnet hsfxUSD-SILVER/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsfxUSD_SILVER_USD_mainnet is Aggregator_hsfxUSD_SILVER_USD {
    constructor()
        Aggregator_hsfxUSD_SILVER_USD(
            MainnetRateSources.MINTER_HSFXUSD_SILVER,
            XAG_USD.FEED,
            XAG_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
