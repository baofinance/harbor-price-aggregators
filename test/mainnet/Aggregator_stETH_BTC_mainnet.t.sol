// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/mainnet/STETH_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {Aggregator_stETH_BTC_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_BTC_mainnet.sol";

/// @notice stETH/BTC on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_stETH_BTC_mainnet_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "stETH";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "BTC";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: MainnetRateSources.WSTETH, kind: SourceKind.WstETHRate});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = STETH_USD.FEED;
        feeds[1] = BTC_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_stETH_BTC_mainnet());
    }
}
