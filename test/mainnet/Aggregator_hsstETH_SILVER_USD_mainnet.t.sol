// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredLeveragedTokenHarness} from "@harbor-price-test/conformance/shapes/WiredLeveragedTokenHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {XAG_USD} from "@harbor-price/feeds/chainlink/mainnet/XAG_USD.sol";
import {Aggregator_hsstETH_SILVER_USD_mainnet} from "@harbor-price/mainnet/Aggregator_hsstETH_SILVER_USD_mainnet.sol";

/// @notice hsstETH-SILVER/USD on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_hsstETH_SILVER_USD_mainnet_Test is WiredLeveragedTokenHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "hsstETH-SILVER";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "USD";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: MainnetRateSources.MINTER_HSSTETH_SILVER, kind: SourceKind.MinterLeveragedPrice});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](1);
        feeds[0] = XAG_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_hsstETH_SILVER_USD_mainnet());
    }
}
