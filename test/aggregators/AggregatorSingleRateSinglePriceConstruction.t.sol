// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";
import {Aggregator_SingleRate_SinglePrice} from "@harbor-price/aggregators/Aggregator_SingleRate_SinglePrice.sol";

/// @notice A concrete single-rate, single-price aggregator, so the formula's constructor can be reached at all.
/// @dev Every wired subclass passes its feeds as constants and takes no arguments of its own, so none of them
///      can present the constructor with a rejected value. This subclass exists only to hand those arguments in.
contract SingleRateSinglePriceProbe is Aggregator_SingleRate_SinglePrice {
    constructor(
        address rateFeed_,
        address priceFeed_,
        uint256 priceHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) Aggregator_SingleRate_SinglePrice(rateFeed_, priceFeed_, priceHeartbeat_, priceDivisor_, invertPrice_) {}

    function _baseName() internal pure override returns (string memory) {
        return "BASE";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "QUOTE";
    }
}

/// @title What a single-rate, single-price aggregator refuses to be built with
/// @notice The rate and the price each come from one feed, and the price is divided by the divisor. An
///         aggregator missing any of them has nothing it can report, so it must refuse to exist rather than
///         be deployed and fail on every read.
contract AggregatorSingleRateSinglePriceConstructionTest is Test {
    uint256 constant HEARTBEAT = 3600;

    address rateFeed;
    address priceFeed;

    function setUp() public {
        rateFeed = address(new MockAggregatorV3(18));
        priceFeed = address(new MockAggregatorV3(8));
    }

    /// @notice Construction without a rate feed is refused.
    function test_construction_rejectsZeroRateFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new SingleRateSinglePriceProbe(address(0), priceFeed, HEARTBEAT, 1, false);
    }

    /// @notice Construction without a price feed is refused.
    function test_construction_rejectsZeroPriceFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new SingleRateSinglePriceProbe(rateFeed, address(0), HEARTBEAT, 1, false);
    }

    /// @notice A zero divisor is refused at construction, where every read would otherwise divide by it.
    function test_construction_rejectsZeroDivisor() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidDivisor.selector, 0));
        new SingleRateSinglePriceProbe(rateFeed, priceFeed, HEARTBEAT, 0, false);
    }
}
