// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredConstantPriceHarness} from "@harbor-price-test/conformance/shapes/WiredConstantPriceHarness.sol";
import {Aggregator_ETH_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_ETH_ETH.sol";

/// @notice ETH priced in ETH: the identity oracle, which reads nothing and answers parity.
contract Aggregator_ETH_ETH_Test is WiredConstantPriceHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "ETH";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "ETH";
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_ETH_ETH());
    }
}
