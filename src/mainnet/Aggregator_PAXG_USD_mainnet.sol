// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {PAXG_USD} from "@harbor-price/feeds/chainlink/mainnet/PAXG_USD.sol";
import {Aggregator_PAXG_USD} from "@harbor-price/aggregators/mainnet/Aggregator_PAXG_USD.sol";

/// @notice Ethereum mainnet PAXG/USD oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_PAXG_USD_mainnet is Aggregator_PAXG_USD {
    constructor()
        Aggregator_PAXG_USD(
            PAXG_USD.FEED,
            PAXG_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
