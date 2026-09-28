// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/mainnet/USDE_USD.sol";
import {MCAP_USD} from "@harbor-price/feeds/chainlink/mainnet/MCAP_USD.sol";
import {Aggregator_USDE_MCAP_mainnet} from "@harbor-price/mainnet/Aggregator_USDE_MCAP_mainnet.sol";

/// @notice USDE/MCAP on mainnet: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_USDE_MCAP_mainnet_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "USDE";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "MCAP";
    }

    /// @dev This pair is quoted in bulk rather than per unit, so one unit of the composed price
    ///      counts as 1,000,000,000,000 of the quote asset.
    function _priceDivisor() internal pure override returns (uint256) {
        return 1e12;
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: MainnetRateSources.SUSDE, kind: SourceKind.Erc4626Rate});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = USDE_USD.FEED;
        feeds[1] = MCAP_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_USDE_MCAP_mainnet());
    }
}
