// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {Aggregator_hsfxUSD_BTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsfxUSD_BTC_USD.sol";

/// @notice Ethereum mainnet hsfxUSD-BTC/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsfxUSD_BTC_USD_mainnet is Aggregator_hsfxUSD_BTC_USD {
    constructor()
        Aggregator_hsfxUSD_BTC_USD(
            MainnetRateSources.MINTER_HSFXUSD_BTC,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
