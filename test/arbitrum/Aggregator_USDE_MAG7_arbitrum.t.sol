// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredFeedOverAverageHarness} from "@harbor-price-test/conformance/shapes/WiredFeedOverAverageHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/arbitrum/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/arbitrum/USDE_USD.sol";
import {AAPL_USD} from "@harbor-price/feeds/chainlink/arbitrum/AAPL_USD.sol";
import {MSFT_USD} from "@harbor-price/feeds/chainlink/arbitrum/MSFT_USD.sol";
import {TSLA_USD} from "@harbor-price/feeds/chainlink/arbitrum/TSLA_USD.sol";
import {GOOGL_USD} from "@harbor-price/feeds/chainlink/arbitrum/GOOGL_USD.sol";
import {META_USD} from "@harbor-price/feeds/chainlink/arbitrum/META_USD.sol";
import {AMZN_USD} from "@harbor-price/feeds/chainlink/arbitrum/AMZN_USD.sol";
import {NVDA_USD} from "@harbor-price/feeds/chainlink/arbitrum/NVDA_USD.sol";
import {Aggregator_USDE_MAG7_arbitrum} from "@harbor-price/arbitrum/Aggregator_USDE_MAG7_arbitrum.sol";

/// @notice USDE/MAG7 on arbitrum: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_USDE_MAG7_arbitrum_Test is WiredFeedOverAverageHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "USDE";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "MAG7";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: SUSDE_USDE.FEED, kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](8);
        feeds[0] = USDE_USD.FEED;
        feeds[1] = AAPL_USD.FEED;
        feeds[2] = MSFT_USD.FEED;
        feeds[3] = TSLA_USD.FEED;
        feeds[4] = GOOGL_USD.FEED;
        feeds[5] = META_USD.FEED;
        feeds[6] = AMZN_USD.FEED;
        feeds[7] = NVDA_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_USDE_MAG7_arbitrum());
    }
}
