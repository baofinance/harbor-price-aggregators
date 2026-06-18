// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/megaeth/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/megaeth/USDE_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/megaeth/BTC_USD.sol";
import {Aggregator_USDE_BTC} from "@harbor-price/aggregators/megaeth/Aggregator_USDE_BTC.sol";

/// @notice MegaETH USDE/BTC oracle (price: USDE/USD -> BTC, rate: SUSDE/USDE).
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_BTC_megaeth is Aggregator_USDE_BTC {
    constructor()
        Aggregator_USDE_BTC(
            SUSDE_USDE.FEED,
            USDE_USD.FEED,
            USDE_USD.HEARTBEAT,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
