// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";

/// @title SingleFeedPriceLib Unit Tests
/// @notice Tests for SingleFeedPriceLib price computation logic
contract SingleFeedPriceLibTest is Test {
    MockAggregatorV3 feed;

    uint256 constant DEFAULT_HEARTBEAT = 3600;

    function setUp() public {
        feed = new MockAggregatorV3(18);
    }

    /// @notice Helper - wraps computeFromValidatedFeedPrice for external call (coverage)
    function callCompute(uint256 feedPrice, uint256 divisor, bool invert) external pure returns (uint256) {
        return SingleFeedPriceLib.computeFromValidatedFeedPrice(feedPrice, divisor, invert);
    }

    /// @notice Helper - wraps getPrice for external call (coverage)
    function callGetPrice(
        AggregatorV3Interface f,
        uint8 decimals,
        uint256 heartbeat,
        uint256 divisor,
        bool invert
    ) external view returns (uint256) {
        return SingleFeedPriceLib.getPrice(f, decimals, heartbeat, divisor, invert);
    }

    // =========================================================================
    // getPrice tests (full function with feed)
    // =========================================================================

    /// @notice getPrice: direct passthrough with 18 decimal feed
    function test_getPrice_direct_18decimals() public {
        feed.setAnswer(2000e18, block.timestamp);

        uint256 result = this.callGetPrice(AggregatorV3Interface(address(feed)), 18, DEFAULT_HEARTBEAT, 1, false);
        assertEq(result, 2000e18, "Should return feed price directly");
    }

    /// @notice getPrice: direct with divisor
    function test_getPrice_direct_withDivisor() public {
        feed.setAnswer(2000e18, block.timestamp);

        uint256 result = this.callGetPrice(AggregatorV3Interface(address(feed)), 18, DEFAULT_HEARTBEAT, 2, false);
        assertEq(result, 1000e18, "Should divide by divisor");
    }

    /// @notice getPrice: inverted
    function test_getPrice_invert() public {
        feed.setAnswer(2e18, block.timestamp);

        uint256 result = this.callGetPrice(AggregatorV3Interface(address(feed)), 18, DEFAULT_HEARTBEAT, 1, true);
        assertEq(result, 0.5e18, "Invert of 2 should be 0.5");
    }

    /// @notice getPrice: 8 decimal feed gets normalized
    function test_getPrice_8decimals() public {
        MockAggregatorV3 feed8 = new MockAggregatorV3(8);
        feed8.setAnswer(2000e8, block.timestamp);

        uint256 result = this.callGetPrice(AggregatorV3Interface(address(feed8)), 8, DEFAULT_HEARTBEAT, 1, false);
        assertEq(result, 2000e18, "8 decimal feed should normalize to 18");
    }

    function test_getPrice_zeroAnswer_reverts() public {
        feed.setAnswer(0, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkFeedLib.ZeroPrice.selector, address(feed), 0));
        this.callGetPrice(AggregatorV3Interface(address(feed)), 18, DEFAULT_HEARTBEAT, 1, false);
    }

    // =========================================================================
    // computeFromValidatedFeedPrice - Direct (invert=false) tests
    // =========================================================================

    /// @notice Passthrough: divisor=1, invert=false returns feedPrice unchanged
    function test_compute_passthrough() public view {
        uint256 feedPrice = 2000e18; // $2000 normalized
        uint256 result = this.callCompute(feedPrice, 1, false);
        assertEq(result, feedPrice, "Passthrough should return feedPrice");
    }

    /// @notice Division: divisor>1 divides the feedPrice
    function test_compute_withDivisor() public view {
        uint256 feedPrice = 2000e18;
        uint256 divisor = 2;
        uint256 result = this.callCompute(feedPrice, divisor, false);
        assertEq(result, 1000e18, "Should divide by divisor");
    }

    /// @notice Division with larger divisor
    function test_compute_withLargeDivisor() public view {
        uint256 feedPrice = 1000e18;
        uint256 divisor = 1000;
        uint256 result = this.callCompute(feedPrice, divisor, false);
        assertEq(result, 1e18, "1000e18 / 1000 = 1e18");
    }

    // =========================================================================
    // Inverted (invert=true) tests
    // =========================================================================

    /// @notice Invert with divisor=1: computes 1e36/feedPrice
    function test_compute_invert_divisorOne() public view {
        uint256 feedPrice = 2e18; // 2.0
        // Expected: 1e18 * 1 * 1e18 / 2e18 = 1e36 / 2e18 = 0.5e18
        uint256 result = this.callCompute(feedPrice, 1, true);
        assertEq(result, 0.5e18, "Invert of 2.0 should be 0.5");
    }

    /// @notice Invert with divisor=1: price = 1e18 yields 1e18
    function test_compute_invert_priceOne() public view {
        uint256 feedPrice = 1e18;
        uint256 result = this.callCompute(feedPrice, 1, true);
        assertEq(result, 1e18, "Invert of 1.0 should be 1.0");
    }

    /// @notice Invert with divisor>1
    function test_compute_invert_withDivisor() public view {
        uint256 feedPrice = 2e18; // 2.0
        uint256 divisor = 4;
        // Expected: 1e18 * 4 * 1e18 / 2e18 = 4e36 / 2e18 = 2e18
        uint256 result = this.callCompute(feedPrice, divisor, true);
        assertEq(result, 2e18, "Invert of 2.0 with divisor=4 should be 2.0");
    }

    /// @notice Invert: feedPrice equals divisor*1e18 should yield 1e18
    function test_compute_invert_priceEqualsDivisor() public view {
        uint256 divisor = 5;
        uint256 feedPrice = 5e18; // Same as divisor
        // Expected: 1e18 * 5 * 1e18 / 5e18 = 5e36 / 5e18 = 1e18
        uint256 result = this.callCompute(feedPrice, divisor, true);
        assertEq(result, 1e18, "When feedPrice == divisor*1e18, result should be 1e18");
    }

    // =========================================================================
    // Edge cases
    // =========================================================================

    /// @notice Very large feedPrice (approaching uint256 limits)
    function test_compute_largeFeedPrice() public view {
        // Max safe value where feedPrice/1 doesn't overflow
        uint256 feedPrice = type(uint128).max;
        uint256 result = this.callCompute(feedPrice, 1, false);
        assertEq(result, feedPrice, "Large feedPrice passthrough");
    }

    /// @notice Very small feedPrice (1 wei normalized)
    function test_compute_smallFeedPrice() public view {
        uint256 feedPrice = 1; // 1 wei
        uint256 result = this.callCompute(feedPrice, 1, false);
        assertEq(result, 1, "Small feedPrice passthrough");
    }

    /// @notice Small feedPrice inverted yields large result
    function test_compute_invert_smallFeedPrice() public view {
        uint256 feedPrice = 1e12; // 0.000001 in 18 decimals
        // Expected: 1e36 / 1e12 = 1e24
        uint256 result = this.callCompute(feedPrice, 1, true);
        assertEq(result, 1e24, "Invert of small price yields large result");
    }

    // =========================================================================
    // Fuzz tests
    // =========================================================================

    /// @notice Fuzz: direct computation (invert=false)
    function test_Fuzz_compute_direct(uint256 feedPrice, uint256 divisor) public view {
        // Bound to reasonable ranges - use vm.assume instead of bound for view compatibility
        vm.assume(feedPrice >= 1 && feedPrice <= type(uint128).max);
        vm.assume(divisor >= 1 && divisor <= 1e18);

        uint256 result = this.callCompute(feedPrice, divisor, false);
        assertEq(result, feedPrice / divisor, "Direct should equal feedPrice/divisor");
    }

    /// @notice Fuzz: inverted computation (invert=true)
    function test_Fuzz_compute_invert(uint256 feedPrice, uint256 divisor) public view {
        // Bound to avoid overflow and division by zero - use vm.assume for view compatibility
        vm.assume(feedPrice >= 1e6 && feedPrice <= type(uint128).max);
        vm.assume(divisor >= 1 && divisor <= 1e12);

        uint256 result = this.callCompute(feedPrice, divisor, true);
        // Expected: (1e18 * divisor * 1e18) / feedPrice
        uint256 expected = (1e18 * divisor * 1e18) / feedPrice;
        assertEq(result, expected, "Invert should equal (1e36 * divisor) / feedPrice");
    }
}
