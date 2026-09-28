// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_EUR_ETH_mainnet} from "@harbor-price/mainnet/Aggregator_EUR_ETH_mainnet.sol";

/// @notice EUR/ETH on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_EUR_ETH_mainnet_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "EUR";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "ETH";
    }

    /// @dev The rate is a constant, so there is no source to read it from.
    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: address(0), kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = EUR_USD.FEED;
        feeds[1] = ETH_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_EUR_ETH_mainnet());
    }
}
