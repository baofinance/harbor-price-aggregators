// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredMultipliedFeedsHarness} from "@harbor-price-test/conformance/shapes/WiredMultipliedFeedsHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {WSTETH_STETH} from "@harbor-price/feeds/chainlink/megaeth/WSTETH_STETH.sol";
import {STETH_ETH} from "@harbor-price/feeds/chainlink/megaeth/STETH_ETH.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/megaeth/ETH_USD.sol";
import {Aggregator_stETH_USD_megaeth} from "@harbor-price/megaeth/Aggregator_stETH_USD_megaeth.sol";

/// @notice stETH/USD on megaeth: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_stETH_USD_megaeth_Test is WiredMultipliedFeedsHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "stETH";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "USD";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: WSTETH_STETH.FEED, kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = STETH_ETH.FEED;
        feeds[1] = ETH_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_stETH_USD_megaeth());
    }
}
