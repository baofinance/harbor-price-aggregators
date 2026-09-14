// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";
import {Aggregator_Peg_ETH} from "@harbor-price/aggregators/Aggregator_Peg_ETH.sol";

/// @notice A concrete Peg/ETH aggregator, so the formula's constructor can be reached at all.
/// @dev Every wired subclass of `Aggregator_Peg_ETH` passes its feeds as constants and takes no
///      arguments of its own, so none of them can present the constructor with a rejected value.
///      This subclass exists only to hand those arguments in.
contract PegEthProbe is Aggregator_Peg_ETH {
    constructor(
        address firstFeed_,
        uint256 firstHeartbeat_,
        address secondFeed_,
        uint256 secondHeartbeat_
    ) Aggregator_Peg_ETH(firstFeed_, firstHeartbeat_, secondFeed_, secondHeartbeat_) {}

    function _baseName() internal pure override returns (string memory) {
        return "PEG";
    }
}

/// @title What a Peg/ETH aggregator refuses to be built with
/// @notice Both feeds are required: the price is one divided by the other, so an aggregator missing
///         either has nothing to report and must refuse to exist rather than be deployed and fail on
///         every read.
contract AggregatorPegEthConstructionTest is Test {
    uint256 constant HEARTBEAT = 3600;

    address firstFeed;
    address secondFeed;

    function setUp() public {
        firstFeed = address(new MockAggregatorV3(8));
        secondFeed = address(new MockAggregatorV3(8));
    }

    function test_construction_rejectsZeroFirstFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new PegEthProbe(address(0), HEARTBEAT, secondFeed, HEARTBEAT);
    }

    function test_construction_rejectsZeroSecondFeed() public {
        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidAddress.selector, address(0)));
        new PegEthProbe(firstFeed, HEARTBEAT, address(0), HEARTBEAT);
    }

    /// @notice A Peg/ETH oracle has no rate to read, and says so by naming no rate provider.
    /// @dev Its rate is the constant 1, because the asset it prices is not a wrapper over anything.
    ///      A consumer that took a non-zero provider here would try to convert against a contract
    ///      that does not exist.
    function test_wiring_namesNoRateProvider() public {
        PegEthProbe probe = new PegEthProbe(firstFeed, HEARTBEAT, secondFeed, HEARTBEAT);

        assertEq(probe.rateProvider(), address(0));
    }
}
