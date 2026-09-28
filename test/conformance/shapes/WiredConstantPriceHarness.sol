// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";

/// @title An aggregator that reads nothing because the pair it prices is an asset against itself
/// @notice An asset is worth exactly one of itself, at every moment, with no source that could say
///         otherwise. It exists so that a market whose peg asset is its own collateral can take an
///         oracle like any other market rather than being a special case in the contracts that
///         consume one.
/// @dev Having no sources is the whole of its specification, so it declares them here rather than
///      leaving each concrete test to declare emptiness. The conformance tests that drive a source
///      to zero or make it unreachable have nothing to iterate over and pass vacuously — correctly,
///      since there is no source whose failure it could mishandle. What still applies to it is the
///      ordering of the bands, the 18-decimal scale, and that reading it changes nothing.
abstract contract WiredConstantPriceHarness is WiredAggregatorHarness {
    /// @inheritdoc WiredAggregatorHarness
    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: address(0), kind: SourceKind.ChainlinkFeed});
    }

    /// @inheritdoc WiredAggregatorHarness
    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](0);
    }

    /// @inheritdoc WiredAggregatorHarness
    function _expectedPrice() internal pure override returns (uint256) {
        return 1e18;
    }
}
