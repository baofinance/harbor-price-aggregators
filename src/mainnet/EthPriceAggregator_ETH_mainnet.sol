// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_ETH_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_ETH_ETH.sol";

/// @notice Ethereum mainnet ETH/ETH oracle (trivial constant; no feed wiring needed).
/// @dev Hard-coded wiring for mainnet; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords,no-empty-blocks
contract EthPriceAggregator_ETH_mainnet is Aggregator_ETH_ETH {}
