// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {TwoFeedRatioRateLib} from "@harbor-price/rates/TwoFeedRatioRateLib.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";

/// @title A wrapped asset's accrual, recovered from two feeds that each quote against a third
/// @notice Some chains carry no feed for a wrapper's accrual — no wstETH/stETH — but do carry both
///         assets quoted against a common third, so dividing one by the other cancels it and leaves
///         the accrual. These tests pin what that division must produce and, where it cannot produce
///         anything, that the failure names the feed responsible rather than being flattened into a
///         bad rate.
contract TwoFeedRatioRateLibTest is Test {
    MockAggregatorV3 numeratorFeed;
    MockAggregatorV3 denominatorFeed;

    uint256 constant HEARTBEAT = 3600;

    /// @dev `ChainlinkFeedLib` allows a feed to land this many seconds past its heartbeat before
    ///      calling it stale, so a test that means to cross the line has to clear the tolerance too.
    uint256 constant HEARTBEAT_TOLERANCE = 42;

    function setUp() public {
        // Far enough from zero that a feed can be backdated without the timestamp underflowing.
        vm.warp(1_735_500_000);

        numeratorFeed = new MockAggregatorV3(18);
        denominatorFeed = new MockAggregatorV3(18);
    }

    /// @dev The library's functions are `internal`, so they inline into whatever calls them. Reaching
    ///      them through an external call is what lets `vm.expectRevert` bind to something, and is
    ///      also how a consumer reaches them in practice.
    function callGetRate(
        AggregatorV3Interface numerator,
        AggregatorV3Interface denominator,
        uint256 heartbeat
    ) external view returns (uint256) {
        return TwoFeedRatioRateLib.getRate(numerator, denominator, heartbeat);
    }

    function callGetRateBounded(
        AggregatorV3Interface numerator,
        AggregatorV3Interface denominator,
        uint256 heartbeat,
        uint256 minRate,
        uint256 maxRate
    ) external view returns (uint256) {
        return TwoFeedRatioRateLib.getRate(numerator, denominator, heartbeat, minRate, maxRate);
    }

    /// @dev Both feeds reporting now, at the given raw answers.
    function _report(int256 numeratorAnswer, int256 denominatorAnswer) private {
        numeratorFeed.setAnswer(numeratorAnswer, block.timestamp);
        denominatorFeed.setAnswer(denominatorAnswer, block.timestamp);
    }

    function _getRate() private view returns (uint256) {
        return
            this.callGetRate(
                AggregatorV3Interface(address(numeratorFeed)),
                AggregatorV3Interface(address(denominatorFeed)),
                HEARTBEAT
            );
    }

    // =========================================================================
    // The ratio
    // =========================================================================

    /// @notice The rate is the numerator's price over the denominator's, carried at 18 decimals.
    function test_getRate_isTheNumeratorOverTheDenominator() public {
        _report(3.6e18, 3e18);

        assertEq(_getRate(), 1.2e18);
    }

    /// @notice Each feed's own decimals are read and applied to that feed alone.
    /// @dev The two feeds need not agree on decimals, and nothing obliges them to. Here they report
    ///      the same real value at different scales, so a correct implementation returns parity.
    ///      One that read the decimals once and applied them to both would be out by the difference —
    ///      ten orders of magnitude for this pair — which is why the two are set apart rather than
    ///      both left at 18.
    function test_getRate_normalisesEachFeedWithItsOwnDecimals() public {
        numeratorFeed.setDecimals(8);
        numeratorFeed.setAnswer(2e8, block.timestamp);
        denominatorFeed.setAnswer(2e18, block.timestamp);

        assertEq(_getRate(), 1e18);
    }

    /// @notice A feed reporting more than 18 decimals is scaled down to 18.
    /// @dev No Chainlink feed does this today, so this is the branch that would otherwise only be
    ///      exercised the day one appears.
    function test_getRate_scalesDownAFeedCarryingMoreThanEighteenDecimals() public {
        numeratorFeed.setDecimals(20);
        numeratorFeed.setAnswer(3e20, block.timestamp);
        denominatorFeed.setAnswer(1e18, block.timestamp);

        assertEq(_getRate(), 3e18);
    }

    /// @notice A wrapper worth less than its underlying is reported as it stands, not floored at
    ///         parity.
    /// @dev The bounds are the caller's to impose through the other overload; this one reports what
    ///      the feeds say. A rate silently raised to parity would value an impaired wrapper as whole.
    function test_getRate_reportsARatioBelowParity() public {
        _report(1.5e18, 3e18);

        assertEq(_getRate(), 0.5e18);
    }

    /// @notice A ratio that does not divide exactly is truncated rather than rounded up.
    /// @dev One third at 18 decimals. Rounding up would give ...334, so this pins the direction: the
    ///      rate never overstates what the numerator is worth.
    function test_getRate_truncatesRatherThanRoundsUp() public {
        _report(1e18, 3e18);

        assertEq(_getRate(), 333333333333333333);
    }

    /// @notice A ratio too small to survive 18 decimals is refused, not reported as nothing.
    /// @dev Both feeds are live and positive, so neither is at fault, yet the quotient truncates to
    ///      zero. Reporting it would say the wrapper is worth nothing — a claim about value — when
    ///      the truth is that the ratio is beyond what the representation can carry.
    function test_getRate_ratioTruncatingToZero_reverts() public {
        _report(1, 2e18);

        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidRate.selector, uint256(0)));
        _getRate();
    }

    // =========================================================================
    // A feed that cannot be used, and which one it was
    // =========================================================================

    /// @notice A numerator that has stopped updating fails, naming the numerator.
    function test_getRate_staleNumerator_reverts() public {
        _report(3.6e18, 3e18);
        uint256 staleTime = block.timestamp - HEARTBEAT - HEARTBEAT_TOLERANCE - 1;
        numeratorFeed.setAnswer(3.6e18, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPriceOracleErrors.StaleFeedData.selector,
                address(numeratorFeed),
                staleTime,
                block.timestamp,
                HEARTBEAT
            )
        );
        _getRate();
    }

    /// @notice A denominator that has stopped updating fails, naming the denominator.
    /// @dev The same heartbeat governs both feeds, so the only thing distinguishing this from the
    ///      case above is which address the failure carries — and a consumer deciding what to do
    ///      about a dead feed needs that to be the right one.
    function test_getRate_staleDenominator_reverts() public {
        _report(3.6e18, 3e18);
        uint256 staleTime = block.timestamp - HEARTBEAT - HEARTBEAT_TOLERANCE - 1;
        denominatorFeed.setAnswer(3e18, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPriceOracleErrors.StaleFeedData.selector,
                address(denominatorFeed),
                staleTime,
                block.timestamp,
                HEARTBEAT
            )
        );
        _getRate();
    }

    /// @notice A feed late by no more than the tolerance is still used.
    /// @dev A feed publishing on a heartbeat lands a little after it; the tolerance is what stops
    ///      that ordinary lateness reading as an outage.
    function test_getRate_toleratesAFeedLateWithinTheTolerance() public {
        uint256 lateTime = block.timestamp - HEARTBEAT - HEARTBEAT_TOLERANCE;
        numeratorFeed.setAnswer(3.6e18, lateTime);
        denominatorFeed.setAnswer(3e18, block.timestamp);

        assertEq(_getRate(), 1.2e18);
    }

    /// @notice A numerator that has never reported fails, naming it.
    /// @dev Distinct from staleness: a feed with no round at all has never had a value, so there is
    ///      nothing to judge the age of.
    function test_getRate_numeratorNeverUpdated_reverts() public {
        numeratorFeed.setAnswer(3.6e18, 0);
        denominatorFeed.setAnswer(3e18, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.FeedNeverUpdated.selector, address(numeratorFeed)));
        _getRate();
    }

    /// @notice A denominator that has never reported fails, naming it.
    function test_getRate_denominatorNeverUpdated_reverts() public {
        numeratorFeed.setAnswer(3.6e18, block.timestamp);
        denominatorFeed.setAnswer(3e18, 0);

        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.FeedNeverUpdated.selector, address(denominatorFeed)));
        _getRate();
    }

    /// @notice A negative numerator fails, naming it and carrying the raw answer.
    /// @dev The answer is reported as the feed gave it, before normalisation, so whoever reads the
    ///      failure sees what the feed actually said.
    function test_getRate_negativeNumerator_reverts() public {
        _report(-1e18, 3e18);

        vm.expectRevert(
            abi.encodeWithSelector(IPriceOracleErrors.NegativePrice.selector, address(numeratorFeed), int256(-1e18))
        );
        _getRate();
    }

    /// @notice A negative denominator fails, naming it and carrying the raw answer.
    function test_getRate_negativeDenominator_reverts() public {
        _report(3.6e18, -1e18);

        vm.expectRevert(
            abi.encodeWithSelector(IPriceOracleErrors.NegativePrice.selector, address(denominatorFeed), int256(-1e18))
        );
        _getRate();
    }

    /// @notice A numerator answering zero fails, naming it.
    function test_getRate_zeroNumerator_reverts() public {
        _report(0, 3e18);

        vm.expectRevert(
            abi.encodeWithSelector(IPriceOracleErrors.ZeroPrice.selector, address(numeratorFeed), int256(0))
        );
        _getRate();
    }

    /// @notice A denominator answering zero fails as a dead feed, naming it — never as a division by
    ///         zero and never as a bad rate.
    /// @dev This is the case that decides how a zero denominator is reported. It is refused while it
    ///      is still being read, as a feed fault carrying the feed's address, rather than surviving
    ///      to the division. A consumer therefore learns which feed died, which `InvalidRate(0)`
    ///      would not have told it.
    function test_getRate_zeroDenominator_revertsNamingTheFeed() public {
        _report(3.6e18, 0);

        vm.expectRevert(
            abi.encodeWithSelector(IPriceOracleErrors.ZeroPrice.selector, address(denominatorFeed), int256(0))
        );
        _getRate();
    }

    // =========================================================================
    // The bounded overload
    // =========================================================================

    /// @notice A rate inside the caller's bounds is returned unchanged.
    function test_getRateBounded_withinBounds_succeeds() public {
        _report(1.2e18, 1e18);

        uint256 rate = this.callGetRateBounded(
            AggregatorV3Interface(address(numeratorFeed)),
            AggregatorV3Interface(address(denominatorFeed)),
            HEARTBEAT,
            0.9e18,
            3e18
        );
        assertEq(rate, 1.2e18);
    }

    /// @notice The bounds are inclusive at the bottom.
    function test_getRateBounded_atTheLowerBound_succeeds() public {
        _report(0.9e18, 1e18);

        uint256 rate = this.callGetRateBounded(
            AggregatorV3Interface(address(numeratorFeed)),
            AggregatorV3Interface(address(denominatorFeed)),
            HEARTBEAT,
            0.9e18,
            3e18
        );
        assertEq(rate, 0.9e18);
    }

    /// @notice The bounds are inclusive at the top.
    function test_getRateBounded_atTheUpperBound_succeeds() public {
        _report(3e18, 1e18);

        uint256 rate = this.callGetRateBounded(
            AggregatorV3Interface(address(numeratorFeed)),
            AggregatorV3Interface(address(denominatorFeed)),
            HEARTBEAT,
            0.9e18,
            3e18
        );
        assertEq(rate, 3e18);
    }

    /// @notice A rate below the caller's bound is refused, carrying the rejected value.
    /// @dev One wei below, so the test fails if the comparison is ever loosened to strict.
    function test_getRateBounded_belowTheLowerBound_reverts() public {
        _report(0.9e18 - 1, 1e18);

        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidRate.selector, uint256(0.9e18 - 1)));
        this.callGetRateBounded(
            AggregatorV3Interface(address(numeratorFeed)),
            AggregatorV3Interface(address(denominatorFeed)),
            HEARTBEAT,
            0.9e18,
            3e18
        );
    }

    /// @notice A rate above the caller's bound is refused, carrying the rejected value.
    function test_getRateBounded_aboveTheUpperBound_reverts() public {
        _report(3e18 + 1, 1e18);

        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidRate.selector, uint256(3e18 + 1)));
        this.callGetRateBounded(
            AggregatorV3Interface(address(numeratorFeed)),
            AggregatorV3Interface(address(denominatorFeed)),
            HEARTBEAT,
            0.9e18,
            3e18
        );
    }

    /// @notice Bounding a rate does not swallow a dead feed: the feed's own failure still surfaces.
    /// @dev A stale feed and an out-of-bounds rate are different facts — one is an outage, the other
    ///      a reading to disbelieve — and flattening the first into the second would have a consumer
    ///      treat a dead oracle as a live but implausible one.
    function test_getRateBounded_staleFeed_revertsAsAFeedFailure() public {
        _report(1.2e18, 1e18);
        uint256 staleTime = block.timestamp - HEARTBEAT - HEARTBEAT_TOLERANCE - 1;
        numeratorFeed.setAnswer(1.2e18, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPriceOracleErrors.StaleFeedData.selector,
                address(numeratorFeed),
                staleTime,
                block.timestamp,
                HEARTBEAT
            )
        );
        this.callGetRateBounded(
            AggregatorV3Interface(address(numeratorFeed)),
            AggregatorV3Interface(address(denominatorFeed)),
            HEARTBEAT,
            0.9e18,
            3e18
        );
    }
}
