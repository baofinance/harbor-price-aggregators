// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {MultiFeedSumPriceLib} from "@harbor-price/prices/MultiFeedSumPriceLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";

/// @title MultiFeedSumPriceLib Unit Tests
/// @notice Tests for MultiFeedSumPriceLib price sum computation
contract MultiFeedSumPriceLibTest is Test {
    MockAggregatorV3[] feeds;
    uint256 constant DEFAULT_HEARTBEAT = 3600;

    function setUp() public {
        vm.warp(1735500000); // ~Dec 29, 2025
    }

    /// @notice Helper - wraps getPrice for external call (coverage)
    function callGetPrice(
        AggregatorV3Interface[] memory f,
        uint8[] memory decimals,
        uint256[] memory heartbeats
    ) external view returns (uint256) {
        return MultiFeedSumPriceLib.getPrice(f, decimals, heartbeats);
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
    // Basic sum tests
    // =========================================================================

    /// @notice Sum of two feeds works correctly
    function test_getPrice_twoFeeds_sums() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100e18;
        prices[1] = 200e18;
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

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats);
        assertEq(result, 300e18, "Should sum two feeds");
    }

    /// @notice Sum of multiple feeds works correctly
    function test_getPrice_multipleFeeds_sums() public {
        uint256[] memory prices = new uint256[](5);
        prices[0] = 10e18;
        prices[1] = 20e18;
        prices[2] = 30e18;
        prices[3] = 40e18;
        prices[4] = 50e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](5);
        uint256[] memory heartbeats = new uint256[](5);
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](5);
        for (uint256 i = 0; i < 5; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats);
        assertEq(result, 150e18, "Should sum all feeds");
    }

    /// @notice Single feed returns its price
    function test_getPrice_singleFeed_returnsPrice() public {
        uint256[] memory prices = new uint256[](1);
        prices[0] = 500e18;
        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 18;

        uint256[] memory heartbeats = new uint256[](1);
        heartbeats[0] = DEFAULT_HEARTBEAT;

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](1);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats);
        assertEq(result, 500e18, "Single feed should return its price");
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

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats);
        assertEq(result, 300e18, "Should normalize and sum feeds with different decimals");
    }

    // =========================================================================
    // Error cases
    // =========================================================================

    /// @notice Empty feeds array reverts
    function test_getPrice_emptyFeeds_reverts() public {
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](0);
        uint8[] memory decimals = new uint8[](0);
        uint256[] memory heartbeats = new uint256[](0);

        vm.expectRevert(MultiFeedSumPriceLib.EmptyFeeds.selector);
        this.callGetPrice(feedInterfaces, decimals, heartbeats);
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

        vm.expectRevert(abi.encodeWithSelector(MultiFeedSumPriceLib.InvalidFeedCount.selector, 1));
        this.callGetPrice(feedInterfaces, decimals, heartbeats);
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

        vm.expectRevert(abi.encodeWithSelector(MultiFeedSumPriceLib.InvalidFeedCount.selector, 1));
        this.callGetPrice(feedInterfaces, decimals, heartbeats);
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

        vm.expectRevert(abi.encodeWithSelector(MultiFeedSumPriceLib.InvalidFeedCount.selector, feedCount));
        this.callGetPrice(feedInterfaces, decimals, heartbeats);
    }

    // =========================================================================
    // Edge cases
    // =========================================================================

    /// @notice Zero feed prices revert
    function test_getPrice_zeroPrices_reverts() public {
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

        vm.expectRevert(abi.encodeWithSelector(ChainlinkFeedLib.ZeroPrice.selector, address(testFeeds[0]), 0));
        this.callGetPrice(feedInterfaces, decimals, heartbeats);
    }

    /// @notice Very large prices sum correctly
    function test_getPrice_largePrices_sums() public {
        uint256[] memory prices = new uint256[](2);
        // Use smaller values to avoid overflow when summing
        prices[0] = type(uint128).max / 2;
        prices[1] = type(uint128).max / 2;
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

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats);
        assertEq(result, (type(uint128).max / 2) * 2, "Large prices should sum correctly");
    }

    /// @notice MAG7 pattern (7 feeds) works correctly
    function test_getPrice_mag7Pattern_sums() public {
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

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats);
        assertEq(result, 2800e18, "MAG7 pattern should sum correctly");
    }
}
