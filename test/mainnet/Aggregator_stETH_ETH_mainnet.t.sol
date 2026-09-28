// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredSingleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredSingleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {STETH_ETH} from "@harbor-price/feeds/chainlink/mainnet/STETH_ETH.sol";
import {Aggregator_stETH_ETH_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_ETH_mainnet.sol";

/// @notice stETH/ETH on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_stETH_ETH_mainnet_Test is WiredSingleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "stETH";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "ETH";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: MainnetRateSources.WSTETH, kind: SourceKind.WstETHRate});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](1);
        feeds[0] = STETH_ETH.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_stETH_ETH_mainnet());
    }
}
