// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MegaETHRateSources} from "@harbor-price/rates/megaeth/MegaETHRateSources.sol";
import {USDM_USD} from "@harbor-price/feeds/chainlink/megaeth/USDM_USD.sol";
import {HYPE_USD} from "@harbor-price/feeds/chainlink/megaeth/HYPE_USD.sol";
import {Aggregator_USDM_HYPE_megaeth} from "@harbor-price/megaeth/Aggregator_USDM_HYPE_megaeth.sol";

/// @notice USDM/HYPE on megaeth: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_USDM_HYPE_megaeth_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "USDM";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "HYPE";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: MegaETHRateSources.USDMY, kind: SourceKind.Erc4626Rate});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = USDM_USD.FEED;
        feeds[1] = HYPE_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_USDM_HYPE_megaeth());
    }
}
