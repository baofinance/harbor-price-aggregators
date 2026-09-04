// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorHarness} from "@harbor-price-test/conformance/AggregatorHarness.sol";
import {OracleSource} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {Aggregator_ETH_ETH} from "@harbor-price/aggregators/mainnet/Aggregator_ETH_ETH.sol";

/// @notice ETH priced in ETH: the identity oracle, which reads nothing and answers parity.
contract Aggregator_ETH_ETH_Test is AggregatorHarness {
    /// @dev It has no sources to install — the only aggregator in the repo that reads none.
    function _installSources() internal override {} // solhint-disable-line no-empty-blocks

    /// @notice It reads nothing, so no source can misbehave on its behalf.
    function _sources() internal pure override returns (OracleSource[] memory sources) {
        sources = new OracleSource[](0);
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_ETH_ETH());
    }

    function test_latestAnswer_isParity() public view {
        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = aggregator.latestAnswer();

        assertEq(minPrice, 1e18, "minUnderlyingPrice");
        assertEq(maxPrice, 1e18, "maxUnderlyingPrice");
        assertEq(minRate, 1e18, "minWrappedRate");
        assertEq(maxRate, 1e18, "maxWrappedRate");
    }

    function test_identity() public view {
        assertEq(aggregator.baseName(), "ETH", "baseName");
        assertEq(aggregator.quoteName(), "ETH", "quoteName");
        assertEq(aggregator.oracleName(), "ETH/ETH", "oracleName");
        assertEq(aggregator.version(), 3, "version");
    }
}
