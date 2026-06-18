// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/megaeth/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/megaeth/USDE_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/megaeth/ETH_USD.sol";
import {Aggregator_USDE_ETH} from "@harbor-price/aggregators/megaeth/Aggregator_USDE_ETH.sol";

/// @notice MegaETH USDE/ETH oracle (price: USDE/USD -> ETH, rate: SUSDE/USDE).
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_ETH_megaeth is Aggregator_USDE_ETH {
    constructor()
        Aggregator_USDE_ETH(
            SUSDE_USDE.FEED,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
