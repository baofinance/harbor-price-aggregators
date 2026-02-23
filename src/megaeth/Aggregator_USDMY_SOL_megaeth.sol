// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MegaETHRateSources} from "@harbor-price/rates/megaeth/MegaETHRateSources.sol";
import {USDM_USD} from "@harbor-price/feeds/chainlink/megaeth/USDM_USD.sol";
import {SOL_USD} from "@harbor-price/feeds/chainlink/megaeth/SOL_USD.sol";
import {Aggregator_USDMY_SOL} from "@harbor-price/aggregators/megaeth/Aggregator_USDMY_SOL.sol";

/// @notice MegaETH USDMY/SOL oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDMY_SOL_megaeth is Aggregator_USDMY_SOL {
    constructor()
        Aggregator_USDMY_SOL(
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
