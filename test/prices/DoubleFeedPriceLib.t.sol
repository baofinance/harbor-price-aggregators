// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {DoubleFeedPriceLib} from "@harbor-price/prices/DoubleFeedPriceLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";

/// @title DoubleFeedPriceLib Unit Tests
/// @notice Tests for DoubleFeedPriceLib price computation logic
contract DoubleFeedPriceLibTest is Test {
    MockAggregatorV3 firstFeed;
    MockAggregatorV3 secondFeed;

    uint256 constant DEFAULT_HEARTBEAT = 3600;

    function setUp() public {
        firstFeed = new MockAggregatorV3(18);
        secondFeed = new MockAggregatorV3(18);
    }

    /// @notice Helper - wraps getPrice for external call (coverage)
    function callGetPrice(
        AggregatorV3Interface first,
        uint8 firstDecimals,
        uint256 firstHeartbeat,
        AggregatorV3Interface second,
        uint8 secondDecimals,
        uint256 secondHeartbeat,
        uint256 divisor,
        bool invert
    ) external view returns (uint256) {
        return
            DoubleFeedPriceLib.getPrice(
                first,
                firstDecimals,
                firstHeartbeat,
                second,
                secondDecimals,
                secondHeartbeat,
                divisor,
                invert
            );
    }

    // =========================================================================
    // Direct calculation (invert=false): firstFeed/secondFeed
    // =========================================================================

    /// @notice Direct: Equal feeds with divisor=1 yields 1e18
    function test_getPrice_direct_equalFeeds() public {
        firstFeed.setAnswer(2000e18, block.timestamp);
        secondFeed.setAnswer(2000e18, block.timestamp);

        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 1e18, "Equal feeds should yield 1e18");
    }

    function test_getPrice_zeroFirstFeed_reverts() public {
        firstFeed.setAnswer(0, block.timestamp);
        secondFeed.setAnswer(2000e18, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkFeedLib.ZeroPrice.selector, address(firstFeed), 0));
        this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function test_getPrice_zeroSecondFeed_reverts() public {
        firstFeed.setAnswer(2000e18, block.timestamp);
        secondFeed.setAnswer(0, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkFeedLib.ZeroPrice.selector, address(secondFeed), 0));
        this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    /// @notice Direct: firstFeed > secondFeed
    function test_getPrice_direct_firstGreater() public {
        firstFeed.setAnswer(4000e18, block.timestamp);
        secondFeed.setAnswer(2000e18, block.timestamp);

        // Formula: (firstFeed * divisor * 1e18) / secondFeed
        // = (4000e18 * 1 * 1e18) / 2000e18 = 2e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 2e18, "4000/2000 should be 2");
    }

    /// @notice Direct: firstFeed < secondFeed yields fraction
    function test_getPrice_direct_firstSmaller() public {
        firstFeed.setAnswer(1000e18, block.timestamp);
        secondFeed.setAnswer(4000e18, block.timestamp);

        // = (1000e18 * 1 * 1e18) / 4000e18 = 0.25e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 0.25e18, "1000/4000 should be 0.25");
    }

    /// @notice Direct with divisor > 1
    function test_getPrice_direct_withDivisor() public {
        firstFeed.setAnswer(2000e18, block.timestamp);
        secondFeed.setAnswer(1000e18, block.timestamp);

        // Formula: (2000e18 * 2 * 1e18) / 1000e18 = 4e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            2,
            false
        );
        assertEq(result, 4e18, "2000/1000 * 2 = 4");
    }

    // =========================================================================
    // Inverted calculation (invert=true): secondFeed/firstFeed
    // =========================================================================

    /// @notice Invert: Equal feeds with divisor=1 yields 1e18
    function test_getPrice_invert_equalFeeds() public {
        firstFeed.setAnswer(2000e18, block.timestamp);
        secondFeed.setAnswer(2000e18, block.timestamp);

        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            true
        );
        assertEq(result, 1e18, "Equal feeds inverted should yield 1e18");
    }

    /// @notice Invert: second > first
    function test_getPrice_invert_secondGreater() public {
        firstFeed.setAnswer(1000e18, block.timestamp);
        secondFeed.setAnswer(2000e18, block.timestamp);

        // Formula: (secondFeedPrice * 1e18) / (firstFeedPrice * divisor)
        // = (2000e18 * 1e18) / (1000e18 * 1) = 2e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            true
        );
        assertEq(result, 2e18, "Invert: 2000/1000 = 2");
    }

    /// @notice Invert with divisor > 1
    function test_getPrice_invert_withDivisor() public {
        firstFeed.setAnswer(1000e18, block.timestamp);
        secondFeed.setAnswer(2000e18, block.timestamp);

        // Formula: (2000e18 * 1e18) / (1000e18 * 2) = 2000e36 / 2000e18 = 1e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            2,
            true
        );
        assertEq(result, 1e18, "Invert: 2000/(1000*2) = 1");
    }

    // =========================================================================
    // Different decimal combinations
    // =========================================================================

    /// @notice Both feeds with 8 decimals
    function test_getPrice_decimals_8_8() public {
        MockAggregatorV3 feed8a = new MockAggregatorV3(8);
        MockAggregatorV3 feed8b = new MockAggregatorV3(8);
        feed8a.setAnswer(2000e8, block.timestamp);
        feed8b.setAnswer(1000e8, block.timestamp);

        // Both normalized to 18 decimals: 2000e18 / 1000e18 = 2e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(feed8a)),
            8,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(feed8b)),
            8,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 2e18, "8/8 decimals: 2000/1000 = 2");
    }

    /// @notice First 8 decimals, second 18 decimals
    function test_getPrice_decimals_8_18() public {
        MockAggregatorV3 feed8 = new MockAggregatorV3(8);
        feed8.setAnswer(2000e8, block.timestamp);
        secondFeed.setAnswer(1000e18, block.timestamp);

        // 2000e18 / 1000e18 = 2e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(feed8)),
            8,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 2e18, "8/18 decimals: 2000/1000 = 2");
    }

    /// @notice First 18 decimals, second 8 decimals
    function test_getPrice_decimals_18_8() public {
        MockAggregatorV3 feed8 = new MockAggregatorV3(8);
        firstFeed.setAnswer(2000e18, block.timestamp);
        feed8.setAnswer(1000e8, block.timestamp);

        // 2000e18 / 1000e18 = 2e18
        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(feed8)),
            8,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 2e18, "18/8 decimals: 2000/1000 = 2");
    }

    // =========================================================================
    // Edge cases
    // =========================================================================

    /// @notice Very large price ratio
    function test_getPrice_largePriceRatio() public {
        firstFeed.setAnswer(100_000e18, block.timestamp);
        secondFeed.setAnswer(1e18, block.timestamp);

        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 100_000e18, "Large ratio: 100k/1 = 100k");
    }

    /// @notice Very small price ratio
    function test_getPrice_smallPriceRatio() public {
        firstFeed.setAnswer(1e18, block.timestamp);
        secondFeed.setAnswer(100_000e18, block.timestamp);

        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(result, 1e13, "Small ratio: 1/100k = 0.00001e18");
    }

    // =========================================================================
    // Fuzz tests
    // =========================================================================

    /// @notice Fuzz: direct calculation maintains expected relationship
    function test_Fuzz_getPrice_direct(uint256 price1, uint256 price2, uint256 divisor) public {
        // Bound to reasonable ranges
        price1 = bound(price1, 1e8, 1e30);
        price2 = bound(price2, 1e8, 1e30);
        divisor = bound(divisor, 1, 1e6);

        firstFeed.setAnswer(int256(price1), block.timestamp);
        secondFeed.setAnswer(int256(price2), block.timestamp);

        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            divisor,
            false
        );

        // Expected: (price1 * divisor * 1e18) / price2
        uint256 expected = Math.mulDiv(Math.mulDiv(price1, divisor, 1), 1e18, price2);
        assertEq(result, expected, "Direct fuzz should match formula");
    }

    /// @notice Fuzz: inverted calculation maintains expected relationship
    function test_Fuzz_getPrice_invert(uint256 price1, uint256 price2, uint256 divisor) public {
        // Bound to reasonable ranges
        price1 = bound(price1, 1e8, 1e30);
        price2 = bound(price2, 1e8, 1e30);
        divisor = bound(divisor, 1, 1e6);

        firstFeed.setAnswer(int256(price1), block.timestamp);
        secondFeed.setAnswer(int256(price2), block.timestamp);

        uint256 result = this.callGetPrice(
            AggregatorV3Interface(address(firstFeed)),
            18,
            DEFAULT_HEARTBEAT,
            AggregatorV3Interface(address(secondFeed)),
            18,
            DEFAULT_HEARTBEAT,
            divisor,
            true
        );

        // Expected: (price2 * 1e18) / (price1 * divisor)
        uint256 expected = Math.mulDiv(price2, 1e18, Math.mulDiv(price1, divisor, 1));
        assertEq(result, expected, "Invert fuzz should match formula");
    }
}
