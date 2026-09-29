// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {console} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {RobinhoodForkTest} from "@harbor-price-test/fork/RobinhoodForkTest.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {RobinhoodRateSources} from "@harbor-price/rates/robinhood/RobinhoodRateSources.sol";
import {SYRUPUSDG_USDG} from "@harbor-price/feeds/chainlink/robinhood/SYRUPUSDG_USDG.sol";
import {USDG_USD} from "@harbor-price/feeds/chainlink/robinhood/USDG_USD.sol";
import {Aggregator_syrupUSDG_USD_robinhood} from "@harbor-price/robinhood/Aggregator_syrupUSDG_USD_robinhood.sol";

/// @notice Live syrupUSDG/USD wiring on Robinhood Chain (no mocks).
/// @dev Rate is Chainlink syrupUSDG/USDG; price is Chainlink USDG/USD. The CCIP token still has no
///      working `convertToAssets` — it is not the rate source.
///      `forge test --match-path test/robinhood/Aggregator_syrupUSDG_USD_robinhoodFork.t.sol -vv`
contract Aggregator_syrupUSDG_USD_robinhoodForkTest is RobinhoodForkTest {
    IHarborPriceAggregatorV3 internal oracle;

    function setUp() public override {
        super.setUp();
        oracle = IHarborPriceAggregatorV3(address(new Aggregator_syrupUSDG_USD_robinhood()));
    }

    function test_fork_identityAndWiring() public view {
        assertEq(oracle.baseName(), "syrupUSDG");
        assertEq(oracle.quoteName(), "USD");
        assertEq(oracle.oracleName(), "syrupUSDG/USD");
        assertEq(oracle.rateProvider(), SYRUPUSDG_USDG.FEED);
        assertEq(oracle.version(), 3);
        assertTrue(SYRUPUSDG_USDG.FEED.code.length > 0, "syrupUSDG/USDG feed");
        assertTrue(USDG_USD.FEED.code.length > 0, "USDG/USD feed");
    }

    function test_fork_latestAnswer() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = oracle.latestAnswer();
        uint256 yieldUsd = p1 * r1 / 1e18;

        console.log("=== syrupUSDG/USD (live) ===");
        console.log("rate feed:", SYRUPUSDG_USDG.FEED);
        console.log("price feed:", USDG_USD.FEED);
        console.log("USDG/USD price (18 decimals):", p1);
        console.log("syrupUSDG/USDG rate (18 decimals):", r1);
        console.log("Harbor Yield USD (price*rate/1e18):", yieldUsd);
        console.log("Harbor Yield USD whole:", yieldUsd / 1e18);
        console.log("Harbor Yield USD 18dp remainder:", yieldUsd % 1e18);

        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, r2, "rate1 == rate2");
        assertGt(p1, 0.98e18, "USDG/USD floor");
        assertLt(p1, 1.02e18, "USDG/USD cap");
        assertGt(r1, 0.9e18, "rate floor");
        assertLt(r1, 1.2e18, "rate cap");
        assertGt(yieldUsd, 0.9e18, "composed USD floor");
        assertLt(yieldUsd, 1.2e18, "composed USD cap");
    }

    function test_fork_convertToAssetsRevertsOnTheBridgedToken() public {
        console.log("syrupUSDG token (not the rate source):", RobinhoodRateSources.SYRUP_USDG);
        vm.expectRevert();
        IERC4626(RobinhoodRateSources.SYRUP_USDG).convertToAssets(1e6);
    }

    function test_fork_usdgUsdFeedIsLive() public view {
        AggregatorV3Interface feed = AggregatorV3Interface(USDG_USD.FEED);
        uint256 price = ChainlinkFeedLib.latestAnswerNormalized(feed, feed.decimals(), USDG_USD.HEARTBEAT);
        assertGt(price, 0.98e18, "USDG/USD floor");
        assertLt(price, 1.02e18, "USDG/USD cap");
    }
}
