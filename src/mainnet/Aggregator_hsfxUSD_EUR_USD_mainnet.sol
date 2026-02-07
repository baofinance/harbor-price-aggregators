// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {Aggregator_hsfxUSD_EUR_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsfxUSD_EUR_USD.sol";

/// @notice Ethereum mainnet hsfxUSD-EUR/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsfxUSD_EUR_USD_mainnet is Aggregator_hsfxUSD_EUR_USD {
    constructor()
        Aggregator_hsfxUSD_EUR_USD(
            MainnetRateSources.MINTER_HSFXUSD_EUR,
            EUR_USD.FEED,
            EUR_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
