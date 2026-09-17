// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredConstantPriceHarness} from "@harbor-price-test/conformance/shapes/WiredConstantPriceHarness.sol";
import {Aggregator_ETH_ETH_mainnet} from "@harbor-price/mainnet/Aggregator_ETH_ETH_mainnet.sol";

/// @notice ETH/ETH on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_ETH_ETH_mainnet_Test is WiredConstantPriceHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "ETH";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "ETH";
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_ETH_ETH_mainnet());
    }
}
