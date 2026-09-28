// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";
import {Aggregator_DoubleFeed_TwoFeedRate} from "@harbor-price/aggregators/Aggregator_DoubleFeed_TwoFeedRate.sol";

/// @notice A concrete double-feed, two-feed-rate aggregator, so the formula's constructor can be reached at all.
/// @dev Every wired subclass passes its feeds as constants and takes no arguments of its own, so none of them
///      can present the constructor with a rejected value. This subclass exists only to hand those arguments in.
contract DoubleFeedTwoFeedRateProbe is Aggregator_DoubleFeed_TwoFeedRate {
    constructor(
        address rateNumFeed_,
        address rateDenomFeed_,
        uint256 rateHeartbeat_,
        address firstFeed_,
        uint256 firstHeartbeat_,
        address secondFeed_,
        uint256 secondHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    )
        Aggregator_DoubleFeed_TwoFeedRate(
            rateNumFeed_,
            rateDenomFeed_,
            rateHeartbeat_,
            firstFeed_,
            firstHeartbeat_,
            secondFeed_,
            secondHeartbeat_,
            priceDivisor_,
            invertPrice_
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "BASE";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "QUOTE";
    }
}

/// @title What a double-feed, two-feed-rate aggregator refuses to be built with
/// @notice The rate is one feed divided by another, and the price is a third divided by a fourth, then by the
///         divisor. An aggregator missing any of them has nothing it can report, so it must refuse to exist
///         rather than be deployed and fail on every read.
contract AggregatorDoubleFeedTwoFeedRateConstructionTest is Test {
    uint256 constant HEARTBEAT = 3600;

    address rateNumeratorFeed;
    address rateDenominatorFeed;
    address firstFeed;
    address secondFeed;

    function setUp() public {
        rateNumeratorFeed = address(new MockAggregatorV3(8));
        rateDenominatorFeed = address(new MockAggregatorV3(8));
        firstFeed = address(new MockAggregatorV3(8));
        secondFeed = address(new MockAggregatorV3(8));
    }

    /// @notice Construction without the rate's numerator feed is refused.
    function test_construction_rejectsZeroRateNumeratorFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new DoubleFeedTwoFeedRateProbe(
            address(0),
            rateDenominatorFeed,
            HEARTBEAT,
            firstFeed,
            HEARTBEAT,
            secondFeed,
            HEARTBEAT,
            1,
            false
        );
    }

    /// @notice Construction without the rate's denominator feed is refused.
    function test_construction_rejectsZeroRateDenominatorFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new DoubleFeedTwoFeedRateProbe(
            rateNumeratorFeed,
            address(0),
            HEARTBEAT,
            firstFeed,
            HEARTBEAT,
            secondFeed,
            HEARTBEAT,
            1,
            false
        );
    }

    /// @notice Construction without the price's first feed is refused.
    function test_construction_rejectsZeroFirstFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new DoubleFeedTwoFeedRateProbe(
            rateNumeratorFeed,
            rateDenominatorFeed,
            HEARTBEAT,
            address(0),
            HEARTBEAT,
            secondFeed,
            HEARTBEAT,
            1,
            false
        );
    }

    /// @notice Construction without the price's second feed is refused.
    function test_construction_rejectsZeroSecondFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new DoubleFeedTwoFeedRateProbe(
            rateNumeratorFeed,
            rateDenominatorFeed,
            HEARTBEAT,
            firstFeed,
            HEARTBEAT,
            address(0),
            HEARTBEAT,
            1,
            false
        );
    }

    /// @notice A zero divisor is refused at construction, where every read would otherwise divide by it.
    function test_construction_rejectsZeroDivisor() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidDivisor.selector, 0));
        new DoubleFeedTwoFeedRateProbe(
            rateNumeratorFeed,
            rateDenominatorFeed,
            HEARTBEAT,
            firstFeed,
            HEARTBEAT,
            secondFeed,
            HEARTBEAT,
            0,
            false
        );
    }
}
