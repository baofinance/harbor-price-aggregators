// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";

/// @title ChainlinkFeedLib General Tests
/// @notice Tests for basic ChainlinkFeedLib functionality (normalization, validation)
contract ChainlinkFeedLibTest is Test {
    MockAggregatorV3 feed;

    uint8 constant DECIMALS = 8;
    int256 constant PRICE = 2000e8; // $2000 with 8 decimals
    uint256 constant HEARTBEAT = 3600; // 1 hour

    function setUp() public {
        vm.warp(1735500000); // ~Dec 29, 2025
        feed = new MockAggregatorV3(DECIMALS);
    }

    /// @notice Basic price normalization works correctly
    function test_latestAnswerNormalized_basicNormalization() public {
        feed.setAnswer(PRICE, block.timestamp);

        uint256 price = ChainlinkFeedLib.latestAnswerNormalized(
            AggregatorV3Interface(address(feed)),
            DECIMALS,
            HEARTBEAT
        );

        // Price should be normalized to 18 decimals: 2000e8 -> 2000e18
        assertEq(price, 2000e18);
    }

    /// @notice Negative price correctly reverts
    function test_latestAnswerNormalized_negativePrice_reverts() public {
        feed.setAnswer(-100e8, block.timestamp);

        bool reverted = false;
        try this.callLatestAnswerNormalized(address(feed), DECIMALS) returns (uint256) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        assertTrue(reverted, "Should revert on negative price");
    }

    /// @notice Zero price is allowed (some feeds can legitimately return 0)
    function test_latestAnswerNormalized_zeroPrice_succeeds() public {
        feed.setAnswer(0, block.timestamp);

        uint256 price = ChainlinkFeedLib.latestAnswerNormalized(
            AggregatorV3Interface(address(feed)),
            DECIMALS,
            HEARTBEAT
        );

        assertEq(price, 0);
    }

    /// @notice Test normalization with different decimal values
    function test_normaliseTo18_variousDecimals() public pure {
        // 8 decimals (standard Chainlink) -> 18 decimals
        assertEq(ChainlinkFeedLib.normaliseTo18(100e8, 8), 100e18);

        // 18 decimals -> 18 decimals (no change)
        assertEq(ChainlinkFeedLib.normaliseTo18(100e18, 18), 100e18);

        // 6 decimals -> 18 decimals
        assertEq(ChainlinkFeedLib.normaliseTo18(100e6, 6), 100e18);

        // 20 decimals -> 18 decimals (scale down - Chainlink never does this, but test coverage)
        assertEq(ChainlinkFeedLib.normaliseTo18(100e20, 20), 100e18);
    }

    /// @notice Test latestAnswerNormalized with >18 decimals feed
    function test_latestAnswerNormalized_above18decimals() public {
        // Create a 20-decimal feed (hypothetical - Chainlink doesn't use >18)
        MockAggregatorV3 feed20 = new MockAggregatorV3(20);
        feed20.setAnswer(2000e20, block.timestamp); // $2000 with 20 decimals

        uint256 price = ChainlinkFeedLib.latestAnswerNormalized(AggregatorV3Interface(address(feed20)), 20, HEARTBEAT);

        // Should normalize to 18 decimals
        assertEq(price, 2000e18);
    }

    /// @notice Helper to make external call for try/catch to work with library
    function callLatestAnswerNormalized(address feedAddr, uint8 decimals) external view returns (uint256) {
        return ChainlinkFeedLib.latestAnswerNormalized(AggregatorV3Interface(feedAddr), decimals, HEARTBEAT);
    }
}
