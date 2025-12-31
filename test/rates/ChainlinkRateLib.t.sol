// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";

/// @title ChainlinkRateLib Unit Tests
/// @notice Tests for ChainlinkRateLib rate retrieval and validation
contract ChainlinkRateLibTest is Test {
    MockAggregatorV3 feed;

    uint256 constant DEFAULT_MIN_RATE = 1e18;
    uint256 constant DEFAULT_MAX_RATE = 2e18;
    uint256 constant DEFAULT_MAX_AGE = 86400; // 24 hours

    function setUp() public {
        vm.warp(1735500000); // ~Dec 29, 2025
        feed = new MockAggregatorV3(18);
    }

    /// @notice Helper - wraps getRate with defaults for external call (coverage)
    function callGetRate(AggregatorV3Interface f) external view returns (uint256) {
        return ChainlinkRateLib.getRate(f);
    }

    /// @notice Helper - wraps getRate with custom params for external call (coverage)
    function callGetRateWithParams(
        AggregatorV3Interface f,
        uint8 decimals,
        uint256 minRate,
        uint256 maxRate,
        uint64 maxAge
    ) external view returns (uint256) {
        return ChainlinkRateLib.getRate(f, decimals, minRate, maxRate, maxAge);
    }

    // =========================================================================
    // getRate() with defaults tests
    // =========================================================================

    /// @notice Valid rate within default bounds is returned correctly
    function test_getRate_validRate_succeeds() public {
        uint256 rate = 1.5e18; // Within [1e18, 2e18]
        feed.setAnswer(int256(rate), block.timestamp);

        uint256 result = this.callGetRate(AggregatorV3Interface(address(feed)));
        assertEq(result, rate, "Should return the rate");
    }

    /// @notice Rate exactly at minimum is accepted
    function test_getRate_atMinimum_succeeds() public {
        feed.setAnswer(int256(DEFAULT_MIN_RATE), block.timestamp);

        uint256 result = this.callGetRate(AggregatorV3Interface(address(feed)));
        assertEq(result, DEFAULT_MIN_RATE, "Rate at minimum should be accepted");
    }

    /// @notice Rate exactly at maximum is accepted
    function test_getRate_atMaximum_succeeds() public {
        feed.setAnswer(int256(DEFAULT_MAX_RATE), block.timestamp);

        uint256 result = this.callGetRate(AggregatorV3Interface(address(feed)));
        assertEq(result, DEFAULT_MAX_RATE, "Rate at maximum should be accepted");
    }

    /// @notice Rate below minimum reverts
    function test_getRate_belowMinimum_reverts() public {
        uint256 lowRate = DEFAULT_MIN_RATE - 1;
        feed.setAnswer(int256(lowRate), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.InvalidRate.selector, lowRate));
        this.callGetRate(AggregatorV3Interface(address(feed)));
    }

    /// @notice Rate above maximum reverts
    function test_getRate_aboveMaximum_reverts() public {
        uint256 highRate = DEFAULT_MAX_RATE + 1;
        feed.setAnswer(int256(highRate), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.InvalidRate.selector, highRate));
        this.callGetRate(AggregatorV3Interface(address(feed)));
    }

    /// @notice Zero rate reverts
    function test_getRate_zero_reverts() public {
        feed.setAnswer(0, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.InvalidRate.selector, 0));
        this.callGetRate(AggregatorV3Interface(address(feed)));
    }

    /// @notice Negative rate reverts
    function test_getRate_negative_reverts() public {
        feed.setAnswer(-100e18, block.timestamp);

        // When answer is negative, it gets converted to uint256 which wraps to a large number
        // The library checks `answer <= 0` first, so it should revert with the wrapped value
        // But since we can't easily predict the exact wrapped value, we just check that it reverts
        vm.expectRevert();
        this.callGetRate(AggregatorV3Interface(address(feed)));
    }

    /// @notice Stale feed data reverts
    function test_getRate_stale_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_MAX_AGE - 1;
        feed.setAnswer(int256(DEFAULT_MIN_RATE), staleTime);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.StaleRateSource.selector, address(feed), staleTime));
        this.callGetRate(AggregatorV3Interface(address(feed)));
    }

    // =========================================================================
    // getRate() with custom params tests
    // =========================================================================

    /// @notice Custom bounds are respected - rate within custom range
    function test_getRate_customBounds_succeeds() public {
        uint256 customMin = 0.5e18;
        uint256 customMax = 3e18;
        uint256 rate = 2.5e18; // Within custom range, outside default range
        feed.setAnswer(int256(rate), block.timestamp);

        uint256 result = this.callGetRateWithParams(
            AggregatorV3Interface(address(feed)),
            18,
            customMin,
            customMax,
            uint64(DEFAULT_MAX_AGE)
        );
        assertEq(result, rate, "Should accept rate within custom bounds");
    }

    /// @notice Custom bounds - rate below custom min reverts
    function test_getRate_customBounds_belowMin_reverts() public {
        uint256 customMin = 1.5e18;
        uint256 customMax = 2.5e18;
        uint256 rate = 1.4e18; // Below custom min
        feed.setAnswer(int256(rate), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.InvalidRate.selector, rate));
        this.callGetRateWithParams(
            AggregatorV3Interface(address(feed)),
            18,
            customMin,
            customMax,
            uint64(DEFAULT_MAX_AGE)
        );
    }

    /// @notice Custom bounds - rate above custom max reverts
    function test_getRate_customBounds_aboveMax_reverts() public {
        uint256 customMin = 1.0e18;
        uint256 customMax = 1.5e18;
        uint256 rate = 1.6e18; // Above custom max
        feed.setAnswer(int256(rate), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.InvalidRate.selector, rate));
        this.callGetRateWithParams(
            AggregatorV3Interface(address(feed)),
            18,
            customMin,
            customMax,
            uint64(DEFAULT_MAX_AGE)
        );
    }

    /// @notice Custom max age is respected
    function test_getRate_customMaxAge_succeeds() public {
        uint256 customMaxAge = 3600; // 1 hour
        uint256 oldTime = block.timestamp - customMaxAge + 100; // Just within limit
        feed.setAnswer(int256(DEFAULT_MIN_RATE), oldTime);

        uint256 result = this.callGetRateWithParams(
            AggregatorV3Interface(address(feed)),
            18,
            DEFAULT_MIN_RATE,
            DEFAULT_MAX_RATE,
            uint64(customMaxAge)
        );
        assertEq(result, DEFAULT_MIN_RATE, "Should accept data within custom max age");
    }

    /// @notice Custom max age - stale data reverts
    function test_getRate_customMaxAge_stale_reverts() public {
        uint256 customMaxAge = 3600; // 1 hour
        uint256 staleTime = block.timestamp - customMaxAge - 1;
        feed.setAnswer(int256(DEFAULT_MIN_RATE), staleTime);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.StaleRateSource.selector, address(feed), staleTime));
        this.callGetRateWithParams(
            AggregatorV3Interface(address(feed)),
            18,
            DEFAULT_MIN_RATE,
            DEFAULT_MAX_RATE,
            uint64(customMaxAge)
        );
    }

    // =========================================================================
    // Decimal normalization tests
    // =========================================================================

    /// @notice 8 decimal feed gets normalized to 18 decimals
    function test_getRate_8decimals_normalizes() public {
        MockAggregatorV3 feed8 = new MockAggregatorV3(8);
        uint256 rate8 = 150000000; // 1.5 in 8 decimals
        feed8.setAnswer(int256(rate8), block.timestamp);

        uint256 result = this.callGetRateWithParams(
            AggregatorV3Interface(address(feed8)),
            8,
            DEFAULT_MIN_RATE,
            DEFAULT_MAX_RATE,
            uint64(DEFAULT_MAX_AGE)
        );
        assertEq(result, 1.5e18, "8 decimal feed should normalize to 18 decimals");
    }

    /// @notice 18 decimal feed stays as 18 decimals
    function test_getRate_18decimals_noChange() public {
        uint256 rate = 1.5e18;
        feed.setAnswer(int256(rate), block.timestamp);

        uint256 result = this.callGetRateWithParams(
            AggregatorV3Interface(address(feed)),
            18,
            DEFAULT_MIN_RATE,
            DEFAULT_MAX_RATE,
            uint64(DEFAULT_MAX_AGE)
        );
        assertEq(result, rate, "18 decimal feed should remain unchanged");
    }

    /// @notice 6 decimal feed gets normalized to 18 decimals
    function test_getRate_6decimals_normalizes() public {
        MockAggregatorV3 feed6 = new MockAggregatorV3(6);
        uint256 rate6 = 1500000; // 1.5 in 6 decimals
        feed6.setAnswer(int256(rate6), block.timestamp);

        uint256 result = this.callGetRateWithParams(
            AggregatorV3Interface(address(feed6)),
            6,
            DEFAULT_MIN_RATE,
            DEFAULT_MAX_RATE,
            uint64(DEFAULT_MAX_AGE)
        );
        assertEq(result, 1.5e18, "6 decimal feed should normalize to 18 decimals");
    }

    // =========================================================================
    // Edge cases
    // =========================================================================

    /// @notice Feed updated exactly at max age boundary succeeds
    function test_getRate_exactlyAtMaxAge_succeeds() public {
        uint256 boundaryTime = block.timestamp - DEFAULT_MAX_AGE;
        feed.setAnswer(int256(DEFAULT_MIN_RATE), boundaryTime);

        uint256 result = this.callGetRate(AggregatorV3Interface(address(feed)));
        assertEq(result, DEFAULT_MIN_RATE, "Should accept data exactly at max age boundary");
    }

    /// @notice Very recent feed data succeeds
    function test_getRate_veryRecent_succeeds() public {
        feed.setAnswer(int256(DEFAULT_MIN_RATE), block.timestamp);

        uint256 result = this.callGetRate(AggregatorV3Interface(address(feed)));
        assertEq(result, DEFAULT_MIN_RATE, "Should accept very recent data");
    }

    // =========================================================================
    // Fuzz tests
    // =========================================================================

    /// @notice Fuzz test for valid rates with default bounds
    function test_Fuzz_getRate_validRange(uint256 rate) public {
        // Bound to valid range: [1e18, 2e18]
        rate = bound(rate, DEFAULT_MIN_RATE, DEFAULT_MAX_RATE);
        feed.setAnswer(int256(rate), block.timestamp);

        uint256 result = ChainlinkRateLib.getRate(AggregatorV3Interface(address(feed)));
        assertEq(result, rate, "Should return valid rate");
    }

    /// @notice Fuzz test for custom bounds
    function test_Fuzz_getRate_customBounds(uint256 rate, uint256 minRate, uint256 maxRate) public {
        // Bound inputs to reasonable ranges
        minRate = bound(minRate, 1e15, 1e20);
        maxRate = bound(maxRate, minRate, 1e21);
        rate = bound(rate, minRate, maxRate);

        feed.setAnswer(int256(rate), block.timestamp);

        uint256 result = this.callGetRateWithParams(
            AggregatorV3Interface(address(feed)),
            18,
            minRate,
            maxRate,
            uint64(DEFAULT_MAX_AGE)
        );
        assertEq(result, rate, "Should return rate within custom bounds");
    }
}
