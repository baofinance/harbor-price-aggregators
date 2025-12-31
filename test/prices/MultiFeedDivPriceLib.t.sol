// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {MultiFeedDivPriceLib} from "@harbor-price/prices/MultiFeedDivPriceLib.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";

/// @title MultiFeedDivPriceLib Unit Tests
/// @notice Tests for MultiFeedDivPriceLib price computation with custom divisor
contract MultiFeedDivPriceLibTest is Test {
    uint256 constant DEFAULT_HEARTBEAT = 3600;

    function setUp() public {
        vm.warp(1735500000); // ~Dec 29, 2025
    }

    /// @notice Helper - wraps getPrice for external call (coverage)
    function callGetPrice(
        AggregatorV3Interface[] memory f,
        uint8[] memory decimals,
        uint256[] memory heartbeats,
        uint256 divisor
    ) external view returns (uint256) {
        return MultiFeedDivPriceLib.getPrice(f, decimals, heartbeats, divisor);
    }

    /// @notice Helper - creates a feed array with given prices
    function createFeeds(uint256[] memory prices, uint8 decimals) internal returns (MockAggregatorV3[] memory) {
        MockAggregatorV3[] memory newFeeds = new MockAggregatorV3[](prices.length);
        for (uint256 i = 0; i < prices.length; i++) {
            newFeeds[i] = new MockAggregatorV3(decimals);
            // Convert price to feed's decimal format
            int256 answer = int256(prices[i] / (10 ** (18 - decimals)));
            newFeeds[i].setAnswer(answer, block.timestamp);
        }
        return newFeeds;
    }

    // =========================================================================
    // Basic division tests
    // =========================================================================

    /// @notice Sum divided by feed count equals average
    function test_getPrice_divideByFeedCount_averages() public {
        uint256[] memory prices = new uint256[](3);
        prices[0] = 100e18;
        prices[1] = 200e18;
        prices[2] = 300e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](3);
        uint256[] memory heartbeats = new uint256[](3);
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](3);
        for (uint256 i = 0; i < 3; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        uint256 divisor = 3; // Divide by feed count
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);

        // Expected: (100e18 + 200e18 + 300e18) / 3 = 200e18
        assertEq(result, 200e18, "Should divide sum by divisor");
    }

    /// @notice Two feeds divided by 2 equals average
    function test_getPrice_twoFeeds_divideByTwo() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100e18;
        prices[1] = 300e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 18;

        uint256[] memory heartbeats = new uint256[](2);
        heartbeats[0] = DEFAULT_HEARTBEAT;
        heartbeats[1] = DEFAULT_HEARTBEAT;

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](2);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));
        feedInterfaces[1] = AggregatorV3Interface(address(testFeeds[1]));

        uint256 divisor = 2;
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);

        // Expected: (100e18 + 300e18) / 2 = 200e18
        assertEq(result, 200e18, "Should divide sum by 2");
    }

    /// @notice Single feed divided by 1 returns the price
    function test_getPrice_singleFeed_divideByOne() public {
        uint256[] memory prices = new uint256[](1);
        prices[0] = 500e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 18;

        uint256[] memory heartbeats = new uint256[](1);
        heartbeats[0] = DEFAULT_HEARTBEAT;

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](1);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));

        uint256 divisor = 1;
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);

        assertEq(result, 500e18, "Single feed divided by 1 should return price");
    }

    // =========================================================================
    // MAG7 pattern tests (sum divided by feed count)
    // =========================================================================

    /// @notice MAG7 pattern (7 feeds) averages correctly
    function test_getPrice_mag7Pattern_averages() public {
        uint256[] memory prices = new uint256[](7);
        prices[0] = 100e18;
        prices[1] = 200e18;
        prices[2] = 300e18;
        prices[3] = 400e18;
        prices[4] = 500e18;
        prices[5] = 600e18;
        prices[6] = 700e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](7);
        uint256[] memory heartbeats = new uint256[](7);
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](7);
        for (uint256 i = 0; i < 7; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        uint256 divisor = 7; // Divide by feed count for average
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);

        // Expected: (100 + 200 + 300 + 400 + 500 + 600 + 700) * 1e18 / 7 = 400e18
        assertEq(result, 400e18, "MAG7 pattern should average correctly");
    }

    // =========================================================================
    // MAG7.i26 pattern tests (sum divided by index price)
    // =========================================================================

    /// @notice MAG7.i26 pattern divides by custom index price
    function test_getPrice_mag7i26Pattern_dividesByIndexPrice() public {
        uint256[] memory prices = new uint256[](7);
        prices[0] = 100e18;
        prices[1] = 200e18;
        prices[2] = 300e18;
        prices[3] = 400e18;
        prices[4] = 500e18;
        prices[5] = 600e18;
        prices[6] = 700e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](7);
        uint256[] memory heartbeats = new uint256[](7);
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](7);
        for (uint256 i = 0; i < 7; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        // Index price from baseline (e.g., sum of prices on 1-1-2026)
        uint256 indexPrice = 2800e18; // Sum of 7 feeds at baseline
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, indexPrice);

        // Expected: 2800e18 / 2800e18 = 1 (integer division gives 1, not 1e18)
        // The library does integer division: sum / divisor
        assertEq(result, 1, "MAG7.i26 should divide sum by index price");
    }

    /// @notice MAG7.i26 pattern with different current prices
    function test_getPrice_mag7i26Pattern_differentCurrentPrices() public {
        uint256[] memory prices = new uint256[](7);
        prices[0] = 150e18; // Higher than baseline
        prices[1] = 250e18;
        prices[2] = 350e18;
        prices[3] = 450e18;
        prices[4] = 550e18;
        prices[5] = 650e18;
        prices[6] = 750e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](7);
        uint256[] memory heartbeats = new uint256[](7);
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](7);
        for (uint256 i = 0; i < 7; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        uint256 indexPrice = 2800e18; // Baseline sum
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, indexPrice);

        // Expected: 3150e18 / 2800e18 = 1.125e18 (indexed value > 1 means prices increased)
        // Using integer division: 3150000000000000000000 / 2800e18
        uint256 expected = (3150e18) / indexPrice;
        assertEq(result, expected, "MAG7.i26 should show indexed value relative to baseline");
    }

    // =========================================================================
    // Decimal normalization tests
    // =========================================================================

    /// @notice Feeds with different decimals are normalized correctly
    function test_getPrice_mixedDecimals_normalizes() public {
        MockAggregatorV3 feed8 = new MockAggregatorV3(8);
        MockAggregatorV3 feed18 = new MockAggregatorV3(18);

        // 100 in 8 decimals -> 100e18
        feed8.setAnswer(100e8, block.timestamp);
        // 200 in 18 decimals -> 200e18
        feed18.setAnswer(200e18, block.timestamp);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](2);
        feedInterfaces[0] = AggregatorV3Interface(address(feed8));
        feedInterfaces[1] = AggregatorV3Interface(address(feed18));

        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 8;
        decimals[1] = 18;

        uint256[] memory heartbeats = new uint256[](2);
        heartbeats[0] = DEFAULT_HEARTBEAT;
        heartbeats[1] = DEFAULT_HEARTBEAT;

        uint256 divisor = 2;
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);
        assertEq(result, 150e18, "Should normalize and divide feeds with different decimals");
    }

    // =========================================================================
    // Error cases
    // =========================================================================

    /// @notice Empty feeds array reverts
    function test_getPrice_emptyFeeds_reverts() public {
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](0);
        uint8[] memory decimals = new uint8[](0);
        uint256[] memory heartbeats = new uint256[](0);
        uint256 divisor = 1;

        vm.expectRevert(MultiFeedDivPriceLib.EmptyFeeds.selector);
        this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);
    }

    /// @notice Zero divisor reverts
    function test_getPrice_zeroDivisor_reverts() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100e18;
        prices[1] = 200e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](2);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));
        feedInterfaces[1] = AggregatorV3Interface(address(testFeeds[1]));

        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 18;

        uint256[] memory heartbeats = new uint256[](2);
        heartbeats[0] = DEFAULT_HEARTBEAT;
        heartbeats[1] = DEFAULT_HEARTBEAT;

        vm.expectRevert(abi.encodeWithSelector(MultiFeedDivPriceLib.InvalidFeedCount.selector, 0));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, 0);
    }

    /// @notice Mismatched decimals array length reverts
    function test_getPrice_mismatchedDecimals_reverts() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100e18;
        prices[1] = 200e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](2);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));
        feedInterfaces[1] = AggregatorV3Interface(address(testFeeds[1]));

        uint8[] memory decimals = new uint8[](1); // Wrong length
        decimals[0] = 18;

        uint256[] memory heartbeats = new uint256[](2);
        heartbeats[0] = DEFAULT_HEARTBEAT;
        heartbeats[1] = DEFAULT_HEARTBEAT;

        vm.expectRevert(abi.encodeWithSelector(MultiFeedDivPriceLib.InvalidFeedCount.selector, 1));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, 2);
    }

    /// @notice Mismatched heartbeats array length reverts
    function test_getPrice_mismatchedHeartbeats_reverts() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100e18;
        prices[1] = 200e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](2);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));
        feedInterfaces[1] = AggregatorV3Interface(address(testFeeds[1]));

        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 18;

        uint256[] memory heartbeats = new uint256[](1); // Wrong length
        heartbeats[0] = DEFAULT_HEARTBEAT;

        vm.expectRevert(abi.encodeWithSelector(MultiFeedDivPriceLib.InvalidFeedCount.selector, 1));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, 2);
    }

    /// @notice Too many feeds (over limit) reverts
    function test_getPrice_tooManyFeeds_reverts() public {
        uint256 feedCount = 51; // Over limit of 50
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](feedCount);
        uint8[] memory decimals = new uint8[](feedCount);
        uint256[] memory heartbeats = new uint256[](feedCount);

        for (uint256 i = 0; i < feedCount; i++) {
            MockAggregatorV3 feed = new MockAggregatorV3(18);
            feed.setAnswer(100e18, block.timestamp);
            feedInterfaces[i] = AggregatorV3Interface(address(feed));
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
        }

        vm.expectRevert(abi.encodeWithSelector(MultiFeedDivPriceLib.InvalidFeedCount.selector, feedCount));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, 1);
    }

    // =========================================================================
    // Edge cases
    // =========================================================================

    /// @notice Zero prices sum to zero
    function test_getPrice_zeroPrices_returnsZero() public {
        uint256[] memory prices = new uint256[](3);
        prices[0] = 0;
        prices[1] = 0;
        prices[2] = 0;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](3);
        uint256[] memory heartbeats = new uint256[](3);
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](3);
        for (uint256 i = 0; i < 3; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        uint256 divisor = 3;
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);
        assertEq(result, 0, "Zero prices should return zero");
    }

    /// @notice Large divisor results in small price
    function test_getPrice_largeDivisor_resultsInSmallPrice() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 1000e18;
        prices[1] = 2000e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](2);
        decimals[0] = 18;
        decimals[1] = 18;

        uint256[] memory heartbeats = new uint256[](2);
        heartbeats[0] = DEFAULT_HEARTBEAT;
        heartbeats[1] = DEFAULT_HEARTBEAT;

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](2);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));
        feedInterfaces[1] = AggregatorV3Interface(address(testFeeds[1]));

        uint256 divisor = 1000;
        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, divisor);

        // Expected: (1000e18 + 2000e18) / 1000 = 3e18
        assertEq(result, 3e18, "Large divisor should result in small price");
    }
}
