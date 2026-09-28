// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredSingleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredSingleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {Aggregator_fxUSD_EUR_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_EUR_mainnet.sol";

/// @notice fxUSD/EUR on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_fxUSD_EUR_mainnet_Test is WiredSingleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "fxUSD";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "EUR";
    }

    /// @dev The feed quotes the pair the other way round, so the reported price is its reciprocal.
    function _priceIsInverted() internal pure override returns (bool) {
        return true;
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: MainnetRateSources.FXSAVE, kind: SourceKind.Erc4626Rate});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](1);
        feeds[0] = EUR_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_fxUSD_EUR_mainnet());
    }
}
