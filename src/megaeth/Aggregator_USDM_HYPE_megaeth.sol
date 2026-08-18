// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MegaETHRateSources} from "@harbor-price/rates/megaeth/MegaETHRateSources.sol";
import {USDM_USD} from "@harbor-price/feeds/chainlink/megaeth/USDM_USD.sol";
import {HYPE_USD} from "@harbor-price/feeds/chainlink/megaeth/HYPE_USD.sol";
import {Aggregator_USDM_HYPE} from "@harbor-price/aggregators/megaeth/Aggregator_USDM_HYPE.sol";

/// @notice MegaETH USDM/HYPE oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDM_HYPE_megaeth is Aggregator_USDM_HYPE {
    constructor()
        Aggregator_USDM_HYPE(
            MegaETHRateSources.USDMY,
            USDM_USD.FEED,
            USDM_USD.HEARTBEAT,
            HYPE_USD.FEED,
            HYPE_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
