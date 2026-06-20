// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ISUSDe} from "@harbor-price/interfaces/ISUSDe.sol";
import {SUSDeRateLib} from "@harbor-price/rates/SUSDeRateLib.sol";
import {MockSUSDe} from "@harbor-price-test/mock/MockSUSDe.sol";

/// @title SUSDeRateLib Unit Tests
/// @notice Tests for SUSDeRateLib rate retrieval and validation
contract SUSDeRateLibTest is Test {
    MockSUSDe mock;

    uint256 constant DEFAULT_MIN_RATE = 9e17; // 0.9 - matches library constant

    function setUp() public {
        mock = new MockSUSDe();
    }

    /// @notice Helper for try/catch - wraps library call in external function
    function callGetRate(ISUSDe susde) external view returns (uint256) {
        return SUSDeRateLib.getRate(susde);
    }

    /// @notice Helper for try/catch - wraps library call with custom min in external function
    function callGetRateWithMin(ISUSDe susde, uint256 minRate) external view returns (uint256) {
        return SUSDeRateLib.getRate(susde, minRate);
    }

    /// @notice Helper - wraps getRaw for coverage
    function callGetRaw(ISUSDe susde, uint256 shares) external view returns (uint256) {
        return SUSDeRateLib.getRaw(susde, shares);
    }

    /// @notice Valid rate above minimum is returned correctly
    function test_getRate_validRate_succeeds() public {
        uint256 rate = 1.05e18; // 1.05 - typical sUSDe rate
        mock.setAssetsPerShare(rate);

        // Use external call for coverage of return statement
        uint256 result = this.callGetRate(ISUSDe(address(mock)));
        assertEq(result, rate, "Should return the rate");
    }

    /// @notice Rate exactly at minimum is accepted
    function test_getRate_atMinimum_succeeds() public {
        mock.setAssetsPerShare(DEFAULT_MIN_RATE);

        uint256 result = this.callGetRate(ISUSDe(address(mock)));
        assertEq(result, DEFAULT_MIN_RATE, "Rate at minimum should be accepted");
    }

    /// @notice Rate below minimum reverts
    function test_getRate_belowMinimum_reverts() public {
        uint256 lowRate = DEFAULT_MIN_RATE - 1;
        mock.setAssetsPerShare(lowRate);

        vm.expectRevert(abi.encodeWithSelector(SUSDeRateLib.InvalidRate.selector, lowRate));
        this.callGetRate(ISUSDe(address(mock)));
    }

    /// @notice Zero rate reverts
    function test_getRate_zero_reverts() public {
        mock.setAssetsPerShare(0);

        vm.expectRevert(abi.encodeWithSelector(SUSDeRateLib.InvalidRate.selector, 0));
        this.callGetRate(ISUSDe(address(mock)));
    }

    /// @notice Custom minRate threshold is respected
    function test_getRate_customMinRate_succeeds() public {
        uint256 customMin = 0.5e18;
        uint256 rate = 0.6e18; // Above custom min, below default min
        mock.setAssetsPerShare(rate);

        // Should succeed with custom min
        uint256 result = this.callGetRateWithMin(ISUSDe(address(mock)), customMin);
        assertEq(result, rate, "Should accept rate above custom minimum");
    }

    /// @notice Custom minRate threshold causes revert when rate is below
    function test_getRate_customMinRate_reverts() public {
        uint256 customMin = 1.1e18;
        uint256 rate = 1.0e18; // Below custom min
        mock.setAssetsPerShare(rate);

        vm.expectRevert(abi.encodeWithSelector(SUSDeRateLib.InvalidRate.selector, rate));
        this.callGetRateWithMin(ISUSDe(address(mock)), customMin);
    }

    /// @notice getRaw returns raw convertToAssets result without validation
    function test_getRaw_returnsUnvalidated() public {
        uint256 rate = 0.5e18; // Below default min - would fail getRate
        mock.setAssetsPerShare(rate);

        // getRaw should not validate
        uint256 result = this.callGetRaw(ISUSDe(address(mock)), 1e18);
        assertEq(result, rate, "getRaw should return unvalidated result");
    }

    /// @notice getRaw with different share amounts
    function test_getRaw_differentShares() public {
        uint256 rate = 1.05e18;
        mock.setAssetsPerShare(rate);

        // 2e18 shares should return 2 * rate
        uint256 result = this.callGetRaw(ISUSDe(address(mock)), 2e18);
        assertEq(result, 2.1e18, "getRaw should scale with shares");
    }

    /// @notice Fuzz test for valid rates
    function test_Fuzz_getRate_validRange(uint256 rate) public {
        // Bound to valid range: [0.9e18, 10e18] (reasonable sUSDe rates)
        rate = bound(rate, DEFAULT_MIN_RATE, 10e18);
        mock.setAssetsPerShare(rate);

        uint256 result = SUSDeRateLib.getRate(ISUSDe(address(mock)));
        assertEq(result, rate, "Should return valid rate");
    }
}
