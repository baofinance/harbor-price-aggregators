// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {XAU_USD} from "@harbor-price/feeds/chainlink/mainnet/XAU_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_Peg_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_Peg_ETH.sol";

/// @notice Ethereum mainnet GOLD/ETH oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_GOLD_ETH_mainnet is Aggregator_Peg_ETH {
    constructor() Aggregator_Peg_ETH(XAU_USD.FEED, XAU_USD.HEARTBEAT, ETH_USD.FEED, ETH_USD.HEARTBEAT) {}

    function _baseName() internal pure override returns (string memory) {
        return "GOLD";
    }
}
