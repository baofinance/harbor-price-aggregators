// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";
import {WstETHRateLib} from "@harbor-price/rates/WstETHRateLib.sol";
import {MockWstETH} from "@harbor-price-test/mock/MockWstETH.sol";

/// @title WstETHRateLib Unit Tests
/// @notice Tests for WstETHRateLib rate retrieval and validation
contract WstETHRateLibTest is Test {
    MockWstETH mock;

    uint256 constant DEFAULT_MIN_RATE = 9e17; // 0.9 - matches library constant
    uint256 constant DEFAULT_MAX_RATE = 3e18;

    function setUp() public {
        mock = new MockWstETH();
    }

    /// @notice Helper for try/catch - wraps library call in external function
    function callGetRate(IWstETH wsteth) external view returns (uint256) {
        return WstETHRateLib.getRate(wsteth);
    }

    /// @notice Helper for try/catch - wraps library call with custom bounds in external function
    function callGetRateWithBounds(IWstETH wsteth, uint256 minRate, uint256 maxRate) external view returns (uint256) {
        return WstETHRateLib.getRate(wsteth, minRate, maxRate);
    }

    /// @notice Helper - wraps getRaw for coverage
    function callGetRaw(IWstETH wsteth, uint256 amount) external view returns (uint256) {
        return WstETHRateLib.getRaw(wsteth, amount);
    }

    /// @notice Valid rate within bounds is returned correctly
    function test_getRate_validRate_succeeds() public {
        uint256 rate = 1.2e18; // Typical wstETH rate
        mock.setStEthPerToken(rate);

        // Use external call for coverage of return statement
        uint256 result = this.callGetRate(IWstETH(address(mock)));
        assertEq(result, rate, "Should return the rate");
    }

    /// @notice Rate exactly at minimum is accepted
    function test_getRate_atMinimum_succeeds() public {
        mock.setStEthPerToken(DEFAULT_MIN_RATE);

        uint256 result = this.callGetRate(IWstETH(address(mock)));
        assertEq(result, DEFAULT_MIN_RATE, "Rate at minimum should be accepted");
    }

    /// @notice Rate exactly at maximum is accepted
    function test_getRate_atMaximum_succeeds() public {
        mock.setStEthPerToken(DEFAULT_MAX_RATE);

        uint256 result = this.callGetRate(IWstETH(address(mock)));
        assertEq(result, DEFAULT_MAX_RATE, "Rate at maximum should be accepted");
    }

    /// @notice Rate below minimum reverts
    function test_getRate_belowMinimum_reverts() public {
        uint256 lowRate = DEFAULT_MIN_RATE - 1;
        mock.setStEthPerToken(lowRate);

        vm.expectRevert(abi.encodeWithSelector(WstETHRateLib.InvalidRate.selector, lowRate));
        this.callGetRate(IWstETH(address(mock)));
    }

    /// @notice Rate above maximum reverts
    function test_getRate_aboveMaximum_reverts() public {
        uint256 highRate = DEFAULT_MAX_RATE + 1;
        mock.setStEthPerToken(highRate);

        vm.expectRevert(abi.encodeWithSelector(WstETHRateLib.InvalidRate.selector, highRate));
        this.callGetRate(IWstETH(address(mock)));
    }

    /// @notice Zero rate reverts
    function test_getRate_zero_reverts() public {
        mock.setStEthPerToken(0);

        vm.expectRevert(abi.encodeWithSelector(WstETHRateLib.InvalidRate.selector, 0));
        this.callGetRate(IWstETH(address(mock)));
    }

    /// @notice Custom bounds are respected - rate within custom range
    function test_getRate_customBounds_succeeds() public {
        uint256 customMin = 0.5e18;
        uint256 customMax = 4e18;
        uint256 rate = 3.5e18; // Within custom range, outside default 0.9–3
        mock.setStEthPerToken(rate);

        uint256 result = this.callGetRateWithBounds(IWstETH(address(mock)), customMin, customMax);
        assertEq(result, rate, "Should accept rate within custom bounds");
    }

    /// @notice Custom bounds - rate below custom min reverts
    function test_getRate_customBounds_belowMin_reverts() public {
        uint256 customMin = 1.5e18;
        uint256 customMax = 2.5e18;
        uint256 rate = 1.4e18; // Below custom min
        mock.setStEthPerToken(rate);

        vm.expectRevert(abi.encodeWithSelector(WstETHRateLib.InvalidRate.selector, rate));
        this.callGetRateWithBounds(IWstETH(address(mock)), customMin, customMax);
    }

    /// @notice Custom bounds - rate above custom max reverts
    function test_getRate_customBounds_aboveMax_reverts() public {
        uint256 customMin = 1.0e18;
        uint256 customMax = 1.5e18;
        uint256 rate = 1.6e18; // Above custom max
        mock.setStEthPerToken(rate);

        vm.expectRevert(abi.encodeWithSelector(WstETHRateLib.InvalidRate.selector, rate));
        this.callGetRateWithBounds(IWstETH(address(mock)), customMin, customMax);
    }

    /// @notice getRaw returns raw getStETHByWstETH result without validation
    function test_getRaw_returnsUnvalidated() public {
        uint256 rate = 0.5e18; // Below default min - would fail getRate
        mock.setStEthPerToken(rate);

        // getRaw should not validate
        uint256 result = this.callGetRaw(IWstETH(address(mock)), 1e18);
        assertEq(result, rate, "getRaw should return unvalidated result");
    }

    /// @notice getRaw with different wstETH amounts
    function test_getRaw_differentAmounts() public {
        uint256 rate = 1.2e18;
        mock.setStEthPerToken(rate);

        // 2e18 wstETH should return 2 * rate stETH
        uint256 result = this.callGetRaw(IWstETH(address(mock)), 2e18);
        assertEq(result, 2.4e18, "getRaw should scale with amount");
    }

    /// @notice Fuzz test for valid rates
    function test_Fuzz_getRate_validRange(uint256 rate) public {
        // Bound to valid range: [0.9e18, 3e18]
        rate = bound(rate, DEFAULT_MIN_RATE, DEFAULT_MAX_RATE);
        mock.setStEthPerToken(rate);

        uint256 result = WstETHRateLib.getRate(IWstETH(address(mock)));
        assertEq(result, rate, "Should return valid rate");
    }
}
