// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredSingleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredSingleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {SHMON_MON} from "@harbor-price/feeds/chainlink/monad/SHMON_MON.sol";
import {MON_USD} from "@harbor-price/feeds/chainlink/monad/MON_USD.sol";
import {Aggregator_shMON_USD_monad} from "@harbor-price/monad/Aggregator_shMON_USD_monad.sol";

/// @notice shMON/USD on monad: what it announces, what it reads, what it composes,
///         and how it fails when a source misbehaves
contract Aggregator_shMON_USD_monad_Test is WiredSingleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "shMON";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @dev The feeds price the underlying, not the wrapper, so the rate carries the price across
    ///      to the wrapper as well as being reported alongside it.
    function _rateScalesThePrice() internal pure override returns (bool) {
        return true;
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: SHMON_MON.FEED, kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](1);
        feeds[0] = MON_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_shMON_USD_monad());
    }
}
