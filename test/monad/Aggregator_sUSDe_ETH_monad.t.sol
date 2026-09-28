// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredDoubleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredDoubleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {SUSDE_USD} from "@harbor-price/feeds/chainlink/monad/SUSDE_USD.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/monad/USDE_USD.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/monad/ETH_USD.sol";
import {Aggregator_sUSDe_ETH_monad} from "@harbor-price/monad/Aggregator_sUSDe_ETH_monad.sol";

/// @notice sUSDe/ETH on monad: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_sUSDe_ETH_monad_Test is WiredDoubleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "sUSDe";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "ETH";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: SUSDE_USD.FEED, kind: SourceKind.ChainlinkFeed});
    }

    /// @dev No feed quotes this wrapper's accrual directly, so the rate is the wrapped asset over
    ///      the unwrapped one, each quoted against a common third.
    function _rateDenominatorFeed() internal pure override returns (address) {
        return USDE_USD.FEED;
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](2);
        feeds[0] = USDE_USD.FEED;
        feeds[1] = ETH_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_sUSDe_ETH_monad());
    }
}
