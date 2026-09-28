// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/mainnet/XAU_USD.sol";
import {Aggregator_USDE_GOLD_mainnet} from "@harbor-price/mainnet/Aggregator_USDE_GOLD_mainnet.sol";

/// @notice USDE/GOLD on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_USDE_GOLD_mainnet_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "USDE";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "GOLD";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: MainnetRateSources.SUSDE, kind: SourceKind.Erc4626Rate});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = USDE_USD.FEED;
        feeds[1] = XAU_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_USDE_GOLD_mainnet());
    }
}
