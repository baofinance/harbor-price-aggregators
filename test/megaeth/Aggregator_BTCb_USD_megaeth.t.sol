// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredSingleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredSingleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {BTCb_USD} from "@harbor-price/feeds/chainlink/megaeth/BTCb_USD.sol";
import {Aggregator_BTCb_USD_megaeth} from "@harbor-price/megaeth/Aggregator_BTCb_USD_megaeth.sol";

/// @notice BTC.b/USD on megaeth: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_BTCb_USD_megaeth_Test is WiredSingleFeedHarness {
    /// @dev The asset is BTC.b, the Avalanche-bridged bitcoin. A Solidity identifier cannot carry
    ///      the dot, so the contract name drops it while the announced name keeps it.
    function _expectedBaseName() internal pure override returns (string memory) {
        return "BTC.b";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @dev The rate is a constant, so there is no source to read it from.
    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: address(0), kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](1);
        feeds[0] = BTCb_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_BTCb_USD_megaeth());
    }
}
