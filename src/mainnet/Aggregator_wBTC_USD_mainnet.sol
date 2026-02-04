// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WBTC_BTC} from "@harbor-price/feeds/chainlink/mainnet/WBTC_BTC.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {Aggregator_wBTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_wBTC_USD.sol";

/// @notice Ethereum mainnet wBTC/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_wBTC_USD_mainnet is Aggregator_wBTC_USD {
    constructor()
        Aggregator_wBTC_USD(
            WBTC_BTC.FEED,
            WBTC_BTC.HEARTBEAT,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
