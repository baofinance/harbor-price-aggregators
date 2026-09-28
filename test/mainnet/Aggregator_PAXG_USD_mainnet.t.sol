// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredSingleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredSingleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {PAXG_USD} from "@harbor-price/feeds/chainlink/mainnet/PAXG_USD.sol";
import {Aggregator_PAXG_USD_mainnet} from "@harbor-price/mainnet/Aggregator_PAXG_USD_mainnet.sol";

/// @notice PAXG/USD on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_PAXG_USD_mainnet_Test is WiredSingleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "PAXG";
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
        feeds[0] = PAXG_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_PAXG_USD_mainnet());
    }
}
