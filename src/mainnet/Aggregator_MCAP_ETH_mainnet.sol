// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MCAP_USD} from "@harbor-price/feeds/chainlink/mainnet/MCAP_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_Peg_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_Peg_ETH.sol";

/// @notice Ethereum mainnet MCAP/ETH oracle.
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_MCAP_ETH_mainnet is Aggregator_Peg_ETH {
    constructor() Aggregator_Peg_ETH(MCAP_USD.FEED, MCAP_USD.HEARTBEAT, ETH_USD.FEED, ETH_USD.HEARTBEAT) {}

    function _baseName() internal pure override returns (string memory) {
        return "MCAP";
    }
}
