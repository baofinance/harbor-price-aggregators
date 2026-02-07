// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_hsfxUSD_ETH_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsfxUSD_ETH_USD.sol";

/// @notice Ethereum mainnet hsfxUSD-ETH/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsfxUSD_ETH_USD_mainnet is Aggregator_hsfxUSD_ETH_USD {
    constructor()
        Aggregator_hsfxUSD_ETH_USD(
            MainnetRateSources.MINTER_HSFXUSD_ETH,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
