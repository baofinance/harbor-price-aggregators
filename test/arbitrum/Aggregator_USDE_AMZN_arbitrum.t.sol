// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/arbitrum/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/arbitrum/USDE_USD.sol";
import {AMZN_USD} from "@harbor-price/feeds/chainlink/arbitrum/AMZN_USD.sol";
import {Aggregator_USDE_AMZN_arbitrum} from "@harbor-price/arbitrum/Aggregator_USDE_AMZN_arbitrum.sol";

/// @notice USDE/AMZN on arbitrum: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_USDE_AMZN_arbitrum_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "USDE";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "AMZN";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: SUSDE_USDE.FEED, kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = USDE_USD.FEED;
        feeds[1] = AMZN_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_USDE_AMZN_arbitrum());
    }
}
