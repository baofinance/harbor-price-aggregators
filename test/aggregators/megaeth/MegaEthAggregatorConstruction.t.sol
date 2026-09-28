// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";
import {Aggregator_USDE_BTC} from "@harbor-price/aggregators/megaeth/Aggregator_USDE_BTC.sol";
import {Aggregator_USDE_ETH} from "@harbor-price/aggregators/megaeth/Aggregator_USDE_ETH.sol";
import {Aggregator_stETH_USD} from "@harbor-price/aggregators/megaeth/Aggregator_stETH_USD.sol";

/// @title What the MegaETH formula aggregators refuse to be built with
/// @notice A wired subclass supplies these arguments from constants, so a mistake in them is fixed
///         at deployment and cannot be corrected afterwards. The constructor is therefore the only
///         place the wiring can be rejected, and it must reject every argument it cannot work
///         without — not just the first one it happens to look at.
/// @dev The formula contracts are the subject here rather than their wired subclasses, because the
///      subclasses take no arguments: the guards can only be reached through the formula.
contract MegaEthAggregatorConstructionTest is Test {
    uint256 constant HEARTBEAT = 3600;

    address rateFeed;
    address firstFeed;
    address secondFeed;

    function setUp() public {
        rateFeed = address(new MockAggregatorV3(18));
        firstFeed = address(new MockAggregatorV3(8));
        secondFeed = address(new MockAggregatorV3(8));
    }

    // =========================================================================
    // USDE/BTC — a rate feed and a price composed from two feeds
    // =========================================================================

    function test_construction_USDE_BTC_rejectsZeroRateFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_USDE_BTC(address(0), firstFeed, HEARTBEAT, secondFeed, HEARTBEAT, 1, false);
    }

    function test_construction_USDE_BTC_rejectsZeroFirstFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_USDE_BTC(rateFeed, address(0), HEARTBEAT, secondFeed, HEARTBEAT, 1, false);
    }

    function test_construction_USDE_BTC_rejectsZeroSecondFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_USDE_BTC(rateFeed, firstFeed, HEARTBEAT, address(0), HEARTBEAT, 1, false);
    }

    /// @notice A zero divisor would divide the price by nothing at all, so it is refused rather than
    ///         left to revert on the first read.
    function test_construction_USDE_BTC_rejectsZeroDivisor() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidDivisor.selector, uint256(0)));
        new Aggregator_USDE_BTC(rateFeed, firstFeed, HEARTBEAT, secondFeed, HEARTBEAT, 0, false);
    }

    // =========================================================================
    // USDE/ETH — the same shape, wired to different feeds
    // =========================================================================

    function test_construction_USDE_ETH_rejectsZeroRateFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_USDE_ETH(address(0), firstFeed, HEARTBEAT, secondFeed, HEARTBEAT, 1, false);
    }

    function test_construction_USDE_ETH_rejectsZeroFirstFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_USDE_ETH(rateFeed, address(0), HEARTBEAT, secondFeed, HEARTBEAT, 1, false);
    }

    function test_construction_USDE_ETH_rejectsZeroSecondFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_USDE_ETH(rateFeed, firstFeed, HEARTBEAT, address(0), HEARTBEAT, 1, false);
    }

    function test_construction_USDE_ETH_rejectsZeroDivisor() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidDivisor.selector, uint256(0)));
        new Aggregator_USDE_ETH(rateFeed, firstFeed, HEARTBEAT, secondFeed, HEARTBEAT, 0, false);
    }

    // =========================================================================
    // stETH/USD — a rate feed and a price composed from stETH/ETH and ETH/USD
    // =========================================================================

    function test_construction_stETH_USD_rejectsZeroRateFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_stETH_USD(address(0), firstFeed, HEARTBEAT, secondFeed, HEARTBEAT);
    }

    function test_construction_stETH_USD_rejectsZeroStethEthFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_stETH_USD(rateFeed, address(0), HEARTBEAT, secondFeed, HEARTBEAT);
    }

    function test_construction_stETH_USD_rejectsZeroEthUsdFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new Aggregator_stETH_USD(rateFeed, firstFeed, HEARTBEAT, address(0), HEARTBEAT);
    }
}
