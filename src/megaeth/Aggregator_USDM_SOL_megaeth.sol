// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MegaETHRateSources} from "@harbor-price/rates/megaeth/MegaETHRateSources.sol";
import {USDM_USD} from "@harbor-price/feeds/chainlink/megaeth/USDM_USD.sol";
import {SOL_USD} from "@harbor-price/feeds/chainlink/megaeth/SOL_USD.sol";
import {Aggregator_USDM_SOL} from "@harbor-price/aggregators/megaeth/Aggregator_USDM_SOL.sol";

/// @notice MegaETH USDM/SOL oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDM_SOL_megaeth is Aggregator_USDM_SOL {
    constructor()
        Aggregator_USDM_SOL(
            MegaETHRateSources.USDMY,
            USDM_USD.FEED,
            USDM_USD.HEARTBEAT,
            SOL_USD.FEED,
            SOL_USD.HEARTBEAT,
            1,
            false
        )
    {}
}

