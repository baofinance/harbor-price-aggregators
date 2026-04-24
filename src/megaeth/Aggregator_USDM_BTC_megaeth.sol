// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MegaETHRateSources} from "@harbor-price/rates/megaeth/MegaETHRateSources.sol";
import {USDM_USD} from "@harbor-price/feeds/chainlink/megaeth/USDM_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/megaeth/BTC_USD.sol";
import {Aggregator_USDM_BTC} from "@harbor-price/aggregators/megaeth/Aggregator_USDM_BTC.sol";

/// @notice MegaETH USDM/BTC oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDM_BTC_megaeth is Aggregator_USDM_BTC {
    constructor()
        Aggregator_USDM_BTC(
            MegaETHRateSources.USDMY,
            USDM_USD.FEED,
            USDM_USD.HEARTBEAT,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
