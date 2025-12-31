// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {MultiFeedNormalizedPriceLib} from "@harbor-price/prices/MultiFeedNormalizedPriceLib.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title MultiFeedNormalizedPriceLib Unit Tests
/// @notice Tests for MultiFeedNormalizedPriceLib normalized average price computation
contract MultiFeedNormalizedPriceLibTest is Test {
    uint256 constant DEFAULT_HEARTBEAT = 3600;

    function setUp() public {
        vm.warp(1735500000); // ~Dec 29, 2025
    }

    /// @notice Helper - wraps getPrice for external call (coverage)
    function callGetPrice(
        AggregatorV3Interface[] memory f,
        uint8[] memory decimals,
        uint256[] memory heartbeats,
        uint256[] memory normFactors
    ) external view returns (uint256) {
        return MultiFeedNormalizedPriceLib.getPrice(f, decimals, heartbeats, normFactors);
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
    // Basic normalized average tests
    // =========================================================================

    /// @notice Two feeds with normalization factors average correctly
    function test_getPrice_twoFeeds_averages() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100e18; // $100
        prices[1] = 200e18; // $200

        uint256[] memory normFactors = new uint256[](2);
        normFactors[0] = 2e18; // 2x normalization
        normFactors[1] = 1e18; // 1x normalization (no change)

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

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);

        // Expected: ((100e18 * 2e18 / 1e18) + (200e18 * 1e18 / 1e18)) / 2
        // = (200e18 + 200e18) / 2 = 200e18
        assertEq(result, 200e18, "Should average normalized prices");
    }

    /// @notice Three feeds with normalization average correctly
    function test_getPrice_threeFeeds_averages() public {
        uint256[] memory prices = new uint256[](3);
        prices[0] = 100e18;
        prices[1] = 200e18;
        prices[2] = 300e18;

        uint256[] memory normFactors = new uint256[](3);
        normFactors[0] = 1e18; // No normalization
        normFactors[1] = 2e18; // 2x
        normFactors[2] = 0.5e18; // 0.5x

        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](3);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));
        feedInterfaces[1] = AggregatorV3Interface(address(testFeeds[1]));
        feedInterfaces[2] = AggregatorV3Interface(address(testFeeds[2]));

        uint8[] memory decimals = new uint8[](3);
        decimals[0] = 18;
        decimals[1] = 18;
        decimals[2] = 18;

        uint256[] memory heartbeats = new uint256[](3);
        heartbeats[0] = DEFAULT_HEARTBEAT;
        heartbeats[1] = DEFAULT_HEARTBEAT;
        heartbeats[2] = DEFAULT_HEARTBEAT;

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);

        // Expected: ((100e18 * 1e18) + (200e18 * 2e18) + (300e18 * 0.5e18)) / 3 / 1e18
        // = (100e18 + 400e18 + 150e18) / 3 = 650e18 / 3 = 216.666...e18
        // Using integer division: 216666666666666666666 (216.666...)
        uint256 sum = 100e18 + 400e18 + 150e18;
        uint256 expected = sum / 3;
        assertEq(result, expected, "Should average three normalized prices");
    }

    /// @notice Single feed with normalization returns normalized price / feedCount
    function test_getPrice_singleFeed_normalizesAndAverages() public {
        uint256[] memory prices = new uint256[](1);
        prices[0] = 100e18;

        uint256[] memory normFactors = new uint256[](1);
        normFactors[0] = 2e18; // 2x normalization

        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](1);
        feedInterfaces[0] = AggregatorV3Interface(address(testFeeds[0]));

        uint8[] memory decimals = new uint8[](1);
        decimals[0] = 18;

        uint256[] memory heartbeats = new uint256[](1);
        heartbeats[0] = DEFAULT_HEARTBEAT;

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);

        // Expected: (100e18 * 2e18 / 1e18) / 1 = 200e18
        assertEq(result, 200e18, "Single feed should normalize and divide by feed count");
    }

    // =========================================================================
    // BOM5 pattern tests (5 feeds with supply normalization)
    // =========================================================================

    /// @notice BOM5 pattern with 5 feeds works correctly
    function test_getPrice_bom5Pattern_averages() public {
        // Example: 5 meme coins with different prices
        uint256[] memory prices = new uint256[](5);
        prices[0] = 0.1e18; // $0.10
        prices[1] = 0.00001e18; // $0.00001
        prices[2] = 0.0001e18; // $0.0001
        prices[3] = 0.5e18; // $0.50
        prices[4] = 2e18; // $2.00

        // Normalization factors to normalize supply relative to WIF (smallest supply)
        uint256[] memory normFactors = new uint256[](5);
        normFactors[0] = 0.1e18; // 0.1x
        normFactors[1] = 10000e18; // 10000x
        normFactors[2] = 1000e18; // 1000x
        normFactors[3] = 0.2e18; // 0.2x
        normFactors[4] = 1e18; // 1x (WIF, baseline)

        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](5);
        for (uint256 i = 0; i < 5; i++) {
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        uint8[] memory decimals = new uint8[](5);
        uint256[] memory heartbeats = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
        }

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);

        // Calculate expected manually
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += Math.mulDiv(prices[i], normFactors[i], 1e18);
        }
        uint256 expected = sum / 5;

        assertEq(result, expected, "BOM5 pattern should average normalized prices");
    }

    // =========================================================================
    // Error cases
    // =========================================================================

    /// @notice Empty feeds array reverts
    function test_getPrice_emptyFeeds_reverts() public {
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](0);
        uint8[] memory decimals = new uint8[](0);
        uint256[] memory heartbeats = new uint256[](0);
        uint256[] memory normFactors = new uint256[](0);

        vm.expectRevert(MultiFeedNormalizedPriceLib.EmptyFeeds.selector);
        this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);
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

        uint256[] memory normFactors = new uint256[](2);
        normFactors[0] = 1e18;
        normFactors[1] = 1e18;

        vm.expectRevert(abi.encodeWithSelector(MultiFeedNormalizedPriceLib.InvalidFeedCount.selector, 1));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);
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

        uint256[] memory normFactors = new uint256[](2);
        normFactors[0] = 1e18;
        normFactors[1] = 1e18;

        vm.expectRevert(abi.encodeWithSelector(MultiFeedNormalizedPriceLib.InvalidFeedCount.selector, 1));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);
    }

    /// @notice Mismatched normalization factors array length reverts
    function test_getPrice_mismatchedNormFactors_reverts() public {
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

        uint256[] memory normFactors = new uint256[](1); // Wrong length
        normFactors[0] = 1e18;

        vm.expectRevert(abi.encodeWithSelector(MultiFeedNormalizedPriceLib.InvalidFeedCount.selector, 1));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);
    }

    /// @notice Too many feeds (over limit) reverts
    function test_getPrice_tooManyFeeds_reverts() public {
        uint256 feedCount = 51; // Over limit of 50
        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](feedCount);
        uint8[] memory decimals = new uint8[](feedCount);
        uint256[] memory heartbeats = new uint256[](feedCount);
        uint256[] memory normFactors = new uint256[](feedCount);

        for (uint256 i = 0; i < feedCount; i++) {
            MockAggregatorV3 feed = new MockAggregatorV3(18);
            feed.setAnswer(100e18, block.timestamp);
            feedInterfaces[i] = AggregatorV3Interface(address(feed));
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
            normFactors[i] = 1e18;
        }

        vm.expectRevert(abi.encodeWithSelector(MultiFeedNormalizedPriceLib.InvalidFeedCount.selector, feedCount));
        this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);
    }

    // =========================================================================
    // Edge cases
    // =========================================================================

    /// @notice Zero normalization factor results in zero contribution
    function test_getPrice_zeroNormFactor_contributesZero() public {
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100e18;
        prices[1] = 200e18;

        uint256[] memory normFactors = new uint256[](2);
        normFactors[0] = 0; // Zero normalization
        normFactors[1] = 1e18;

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

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);

        // Expected: (0 + 200e18) / 2 = 100e18
        assertEq(result, 100e18, "Zero normalization should contribute zero");
    }

    /// @notice All feeds with 1x normalization equals simple average
    function test_getPrice_unitNormFactors_equalsAverage() public {
        uint256[] memory prices = new uint256[](3);
        prices[0] = 100e18;
        prices[1] = 200e18;
        prices[2] = 300e18;

        uint256[] memory normFactors = new uint256[](3);
        normFactors[0] = 1e18;
        normFactors[1] = 1e18;
        normFactors[2] = 1e18;

        MockAggregatorV3[] memory testFeeds = createFeeds(prices, 18);

        AggregatorV3Interface[] memory feedInterfaces = new AggregatorV3Interface[](3);
        for (uint256 i = 0; i < 3; i++) {
            feedInterfaces[i] = AggregatorV3Interface(address(testFeeds[i]));
        }

        uint8[] memory decimals = new uint8[](3);
        uint256[] memory heartbeats = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            decimals[i] = 18;
            heartbeats[i] = DEFAULT_HEARTBEAT;
        }

        uint256 result = this.callGetPrice(feedInterfaces, decimals, heartbeats, normFactors);

        // Expected: (100e18 + 200e18 + 300e18) / 3 = 200e18
        assertEq(result, 200e18, "Unit normalization should equal simple average");
    }
}
