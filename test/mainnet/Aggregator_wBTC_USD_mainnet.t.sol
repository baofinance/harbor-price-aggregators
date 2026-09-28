// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredMultipliedFeedsHarness} from "@harbor-price-test/conformance/shapes/WiredMultipliedFeedsHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {WBTC_BTC} from "@harbor-price/feeds/chainlink/mainnet/WBTC_BTC.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {Aggregator_wBTC_USD_mainnet} from "@harbor-price/mainnet/Aggregator_wBTC_USD_mainnet.sol";

/// @notice wBTC/USD on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_wBTC_USD_mainnet_Test is WiredMultipliedFeedsHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "wBTC";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @dev The rate is a constant, so there is no source to read it from.
    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: address(0), kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = WBTC_BTC.FEED;
        feeds[1] = BTC_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_wBTC_USD_mainnet());
    }
}
