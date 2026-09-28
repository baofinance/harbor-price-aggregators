// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {WSTETH_STETH} from "@harbor-price/feeds/chainlink/arbitrum/WSTETH_STETH.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/arbitrum/STETH_USD.sol";
import {META_USD} from "@harbor-price/feeds/chainlink/arbitrum/META_USD.sol";
import {Aggregator_stETH_META_arbitrum} from "@harbor-price/arbitrum/Aggregator_stETH_META_arbitrum.sol";

/// @notice stETH/META on arbitrum: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_stETH_META_arbitrum_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "stETH";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "META";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: WSTETH_STETH.FEED, kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = STETH_USD.FEED;
        feeds[1] = META_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_stETH_META_arbitrum());
    }
}
