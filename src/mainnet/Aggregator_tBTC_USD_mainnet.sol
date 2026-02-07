// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {TBTC_USD} from "@harbor-price/feeds/chainlink/mainnet/TBTC_USD.sol";
import {Aggregator_tBTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_tBTC_USD.sol";

/// @notice Ethereum mainnet tBTC/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_tBTC_USD_mainnet is Aggregator_tBTC_USD {
    constructor()
        Aggregator_tBTC_USD(
            TBTC_USD.FEED,
            TBTC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
