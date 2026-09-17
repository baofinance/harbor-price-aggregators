// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";
import {Aggregator_DirectPrice_TwoFeedRate} from "@harbor-price/aggregators/Aggregator_DirectPrice_TwoFeedRate.sol";

/// @notice A concrete direct-price, two-feed-rate aggregator, so the formula's constructor can be reached at all.
/// @dev Every wired subclass passes its feeds as constants and takes no arguments of its own, so none of them
///      can present the constructor with a rejected value. This subclass exists only to hand those arguments in.
contract DirectPriceTwoFeedRateProbe is Aggregator_DirectPrice_TwoFeedRate {
    constructor(
        address rateNumFeed_,
        address rateDenomFeed_,
        uint256 rateHeartbeat_,
        address priceFeed_,
        uint256 priceHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    )
        Aggregator_DirectPrice_TwoFeedRate(
            rateNumFeed_,
            rateDenomFeed_,
            rateHeartbeat_,
            priceFeed_,
            priceHeartbeat_,
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

/// @title What a direct-price, two-feed-rate aggregator refuses to be built with
/// @notice The rate is one feed divided by another and the price is a third, divided by the divisor. An
///         aggregator missing any of them has nothing it can report, so it must refuse to exist rather than
///         be deployed and fail on every read.
contract AggregatorDirectPriceTwoFeedRateConstructionTest is Test {
    uint256 constant HEARTBEAT = 3600;

    address rateNumeratorFeed;
    address rateDenominatorFeed;
    address priceFeed;

    function setUp() public {
        rateNumeratorFeed = address(new MockAggregatorV3(8));
        rateDenominatorFeed = address(new MockAggregatorV3(8));
        priceFeed = address(new MockAggregatorV3(8));
    }

    /// @notice Construction without the rate's numerator feed is refused.
    function test_construction_rejectsZeroRateNumeratorFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new DirectPriceTwoFeedRateProbe(address(0), rateDenominatorFeed, HEARTBEAT, priceFeed, HEARTBEAT, 1, false);
    }

    /// @notice Construction without the rate's denominator feed is refused.
    function test_construction_rejectsZeroRateDenominatorFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new DirectPriceTwoFeedRateProbe(rateNumeratorFeed, address(0), HEARTBEAT, priceFeed, HEARTBEAT, 1, false);
    }

    /// @notice Construction without a price feed is refused.
    function test_construction_rejectsZeroPriceFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new DirectPriceTwoFeedRateProbe(
            rateNumeratorFeed,
            rateDenominatorFeed,
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
        new DirectPriceTwoFeedRateProbe(
            rateNumeratorFeed,
            rateDenominatorFeed,
            HEARTBEAT,
            priceFeed,
            HEARTBEAT,
            0,
            false
        );
    }
}
