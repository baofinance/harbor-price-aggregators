// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {DeployedAddresses} from "@harbor-test/DeployedAddresses.sol";

/// @title Chainlink Staleness Analysis
/// @notice Historical analysis scripts for investigating Chainlink feed staleness patterns.
/// @dev These are heavy fork-based tests - run individually with:
///      forge test --match-contract ChainlinkStalenessAnalysis --match-test <test_name> -vv
///      Use --jobs 1 (-j 1) to avoid rate limiting when running multiple.
contract ChainlinkStalenessAnalysis is Test {
    // Block range for analysis
    uint256 constant START_BLOCK = DeployedAddresses.DEPLOYMENT_BLOCK;
    uint256 constant END_BLOCK = 24_067_873; // 2025-12-22 11:32:47 UTC

    /// @notice Analyze Chainlink feed staleness patterns across many blocks
    /// @dev Run with: forge test --match-test test_analyze_feed_staleness -vv -j 1
    function test_analyze_feed_staleness() public {
        vm.createSelectFork("mainnet", END_BLOCK);

        console.log("=== Chainlink Feed Staleness Analysis ===");
        console.log("Sampling 100 blocks from %d to %d", START_BLOCK, END_BLOCK);

        // Track max overshoot for each feed (how far past heartbeat)
        int256 maxOvershootEthUsd = type(int256).min;
        int256 maxOvershootBtcUsd = type(int256).min;

        uint256 staleCountEth = 0;
        uint256 staleCountBtc = 0;
        uint256 samples = 100;
        uint256 step = (END_BLOCK - START_BLOCK) / samples;

        for (uint256 i = 0; i <= samples; i++) {
            uint256 sampleBlock = START_BLOCK + (i * step);
            vm.rollFork(sampleBlock);

            // ETH/USD (heartbeat 3600)
            (, , , uint256 ethUpdatedAt, ) = AggregatorV3Interface(ETH_USD.FEED).latestRoundData();
            int256 ethOvershoot = int256(block.timestamp) - int256(ethUpdatedAt) - 3600;
            if (ethOvershoot > maxOvershootEthUsd) maxOvershootEthUsd = ethOvershoot;
            if (ethOvershoot > 0) staleCountEth++;

            // BTC/USD (heartbeat 3600)
            (, , , uint256 btcUpdatedAt, ) = AggregatorV3Interface(BTC_USD.FEED).latestRoundData();
            int256 btcOvershoot = int256(block.timestamp) - int256(btcUpdatedAt) - 3600;
            if (btcOvershoot > maxOvershootBtcUsd) maxOvershootBtcUsd = btcOvershoot;
            if (btcOvershoot > 0) staleCountBtc++;
        }

        console.log("ETH/USD (heartbeat 3600s):");
        console.log("  stale samples: %d / %d", staleCountEth, samples + 1);
        if (maxOvershootEthUsd > 0) {
            console.log("  max overshoot: %d seconds", uint256(maxOvershootEthUsd));
        } else {
            console.log("  max overshoot: never exceeded heartbeat");
        }

        console.log("BTC/USD (heartbeat 3600s):");
        console.log("  stale samples: %d / %d", staleCountBtc, samples + 1);
        if (maxOvershootBtcUsd > 0) {
            console.log("  max overshoot: %d seconds", uint256(maxOvershootBtcUsd));
        } else {
            console.log("  max overshoot: never exceeded heartbeat");
        }

        console.log("");
        console.log("If max overshoot is small (< 60s), an absolute tolerance makes sense.");
        console.log("If max overshoot is large or proportional to heartbeat, use relative tolerance.");
    }

    /// @notice Zoom in on a specific block range to analyze staleness patterns
    /// @dev Run with: forge test --match-test test_zoom_stale_block -vv -j 1
    function test_zoom_stale_block() public {
        // The failing block from test_compare_all (before tolerance was added)
        uint256 staleBlock = 24063708;
        uint256 rangeStart = staleBlock - 50;
        uint256 rangeEnd = staleBlock + 50;

        vm.createSelectFork("mainnet", rangeEnd);

        console.log("=== Zooming in on stale block %d ===", staleBlock);
        console.log("Checking every block from %d to %d", rangeStart, rangeEnd);

        uint256 staleCount = 0;
        int256 maxOvershoot = type(int256).min;
        uint256 maxOvershootBlock = 0;

        for (uint256 blk = rangeStart; blk <= rangeEnd; blk++) {
            vm.rollFork(blk);

            // BTC/USD (heartbeat 3600) - this was the stale feed
            (, , , uint256 btcUpdatedAt, ) = AggregatorV3Interface(BTC_USD.FEED).latestRoundData();
            int256 btcAge = int256(block.timestamp) - int256(btcUpdatedAt);
            int256 overshoot = btcAge - 3600;

            if (overshoot > 0) {
                staleCount++;
                console.log("  Block %d: age=%d, overshoot=%d", blk, uint256(btcAge), uint256(overshoot));
            }

            if (overshoot > maxOvershoot) {
                maxOvershoot = overshoot;
                maxOvershootBlock = blk;
            }
        }

        console.log("");
        console.log("Summary: %d stale blocks out of %d checked", staleCount, rangeEnd - rangeStart + 1);
        if (maxOvershoot > 0) {
            console.log("Max overshoot: %d seconds at block %d", uint256(maxOvershoot), maxOvershootBlock);
        } else {
            console.log("No staleness detected in this range");
        }
    }
}
