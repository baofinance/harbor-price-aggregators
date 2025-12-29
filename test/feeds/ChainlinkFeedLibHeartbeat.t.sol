// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";

/// @title ChainlinkFeedLib Heartbeat Tests
/// @notice Tests for staleness/heartbeat validation in ChainlinkFeedLib
/// @dev The library applies a 42-second tolerance (HEARTBEAT_TOLERANCE) to account for block timing
contract ChainlinkFeedLibHeartbeatTest is Test {
    MockAggregatorV3 feed;

    uint8 constant DECIMALS = 8;
    uint256 constant HEARTBEAT = 3600; // 1 hour
    uint256 constant TOLERANCE = 42; // Must match ChainlinkFeedLib.HEARTBEAT_TOLERANCE
    int256 constant PRICE = 2000e8; // $2000 with 8 decimals

    function setUp() public {
        // Warp to a reasonable timestamp to avoid underflow in time calculations
        vm.warp(1735500000); // ~Dec 29, 2025
        feed = new MockAggregatorV3(DECIMALS);
    }

    /// @notice Stale data should be rejected
    function test_latestAnswerNormalized_staleData_shouldRevert() public {
        // Set price updated 1 week ago - far beyond any reasonable heartbeat
        uint256 staleTime = block.timestamp - 7 days;
        feed.setAnswer(PRICE, staleTime);

        bool reverted = false;
        try this.callLatestAnswerNormalized(address(feed), DECIMALS) returns (
            uint256
        ) {
        // Should not reach here once heartbeat checking is implemented
        }
        catch {
            reverted = true;
        }
        assertTrue(reverted, "Stale data (7 days old) should be rejected");
    }

    /// @notice Data past heartbeat + tolerance should be rejected
    function test_latestAnswerNormalized_justPastHeartbeat_shouldRevert() public {
        // Set price updated HEARTBEAT + TOLERANCE + 1 seconds ago (should be stale)
        feed.setAnswer(PRICE, block.timestamp - HEARTBEAT - TOLERANCE - 1);

        bool reverted = false;
        try this.callLatestAnswerNormalized(address(feed), DECIMALS) returns (
            uint256
        ) {
        // Should not reach here
        }
        catch {
            reverted = true;
        }
        assertTrue(reverted, "Data past heartbeat + tolerance should be rejected");
    }

    /// @notice Data within heartbeat + tolerance should be accepted
    function test_latestAnswerNormalized_withinTolerance_succeeds() public {
        // Set price updated HEARTBEAT + (TOLERANCE - 1) seconds ago (within tolerance)
        feed.setAnswer(PRICE, block.timestamp - HEARTBEAT - TOLERANCE + 1);

        uint256 price =
            ChainlinkFeedLib.latestAnswerNormalized(AggregatorV3Interface(address(feed)), DECIMALS, HEARTBEAT);
        assertEq(price, 2000e18, "Price within tolerance should be accepted");
    }

    /// @notice Feed that has never been updated should be rejected
    function test_latestAnswerNormalized_neverUpdated_shouldRevert() public view {
        // Don't call setAnswer - updatedAt remains 0
        // This is dangerous and should be rejected

        bool reverted = false;
        try this.callLatestAnswerNormalized(address(feed), DECIMALS) returns (
            uint256
        ) {
        // Should not reach here
        }
        catch {
            reverted = true;
        }
        assertTrue(reverted, "Feed with updatedAt=0 should be rejected");
    }

    /// @notice Helper to make external call for try/catch to work with library
    function callLatestAnswerNormalized(address feedAddr, uint8 decimals) external view returns (uint256) {
        return ChainlinkFeedLib.latestAnswerNormalized(AggregatorV3Interface(feedAddr), decimals, HEARTBEAT);
    }
}
