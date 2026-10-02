// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {console} from "forge-std/Test.sol";
import {WiredSingleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredSingleFeedHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {SYRUPUSDG_USDG} from "@harbor-price/feeds/chainlink/robinhood/SYRUPUSDG_USDG.sol";
import {USDG_USD} from "@harbor-price/feeds/chainlink/robinhood/USDG_USD.sol";
import {Aggregator_syrupUSDG_USD_robinhood} from "@harbor-price/robinhood/Aggregator_syrupUSDG_USD_robinhood.sol";

/// @notice syrupUSDG/USD on Robinhood: Chainlink syrupUSDG/USDG × USDG/USD, invert false.
contract Aggregator_syrupUSDG_USD_robinhood_Test is WiredSingleFeedHarness {
    function _expectedBaseName() internal pure override returns (string memory) {
        return "syrupUSDG";
    }

    function _expectedQuoteName() internal pure override returns (string memory) {
        return "USD";
    }

    function _rateSource() internal pure override returns (OracleSource memory) {
        return OracleSource({at: SYRUPUSDG_USDG.FEED, kind: SourceKind.ChainlinkFeed});
    }

    function _priceFeeds() internal pure override returns (address[] memory feeds) {
        feeds = new address[](1);
        feeds[0] = USDG_USD.FEED;
    }

    function _createAggregator() internal override returns (address) {
        return address(new Aggregator_syrupUSDG_USD_robinhood());
    }

    function test_latestAnswer_logsPrice() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();
        uint256 yieldUsd = (p1 * r1) / 1e18;

        console.log("=== syrupUSDG/USD robinhood (unit test, mocked sources) ===");
        console.log("USDG/USD price (18 decimals):", p1);
        console.log("syrupUSDG/USDG rate (18 decimals):", r1);
        console.log("Harbor Yield USD (price*rate/1e18):", yieldUsd);
        console.log("Harbor Yield USD whole:", yieldUsd / 1e18);
        console.log("Harbor Yield USD 18dp remainder:", yieldUsd % 1e18);
        console.log("");

        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, r2, "rate1 == rate2");
        assertEq(p1, _expectedPrice(), "price");
        assertEq(r1, _expectedRate(), "rate");
    }
}
