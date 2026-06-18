// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MegaETHRateSources} from "@harbor-price/rates/megaeth/MegaETHRateSources.sol";
import {USDM_USD} from "@harbor-price/feeds/chainlink/megaeth/USDM_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/megaeth/ETH_USD.sol";
import {Aggregator_USDM_ETH} from "@harbor-price/aggregators/megaeth/Aggregator_USDM_ETH.sol";

/// @notice MegaETH USDM/ETH oracle.
/// @dev Hard-coded wiring for MegaETH; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDM_ETH_megaeth is Aggregator_USDM_ETH {
    constructor()
        Aggregator_USDM_ETH(
            MegaETHRateSources.USDMY,
            USDM_USD.FEED,
            USDM_USD.HEARTBEAT,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
