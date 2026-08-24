// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Aggregator_stETH_MAG7_arbitrum} from "@harbor-price/arbitrum/Aggregator_stETH_MAG7_arbitrum.sol";
import {Aggregator_USDE_MAG7_arbitrum} from "@harbor-price/arbitrum/Aggregator_USDE_MAG7_arbitrum.sol";

/// @notice Fork tests for Arbitrum MAG7 oracles
/// @dev Run with: forge test --match-path "test/arbitrum/*MAG7*.t.sol" --fork-url $arbitrum -vvv
///      Ensure ARBITRUM_RPC_URL environment variable is set in foundry.toml
contract ArbitrumMAG7OraclesForkTest is Test {
    Aggregator_stETH_MAG7_arbitrum public oracleStETH;
    Aggregator_USDE_MAG7_arbitrum public oracleUSDE;

    function setUp() public {
        vm.skip(true);
        // Create fork - skip if RPC URL not available
        try vm.createSelectFork("arbitrum") {} catch {
            vm.skip(true);
        }

        // Deploy both MAG7 oracles
        oracleStETH = new Aggregator_stETH_MAG7_arbitrum();
        oracleUSDE = new Aggregator_USDE_MAG7_arbitrum();
    }

    function test_stETH_MAG7_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleStETH.latestAnswer();
        console.log("=== stETH/MAG7 Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_USDE_MAG7_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleUSDE.latestAnswer();
        console.log("=== USDE/MAG7 Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_AllMAG7Oracles_RateAndPrice() public view {
        test_stETH_MAG7_RateAndPrice();
        test_USDE_MAG7_RateAndPrice();
    }

    function test_CheckOracleMetadata() public view {
        console.log("=== Oracle Metadata ===");
        console.log("stETH/MAG7 rateProvider:", oracleStETH.rateProvider());
        console.log("stETH/MAG7 quoteName:", oracleStETH.quoteName());
        console.log("stETH/MAG7 oracleName:", oracleStETH.oracleName());
        console.log("stETH/MAG7 feedCount:", oracleStETH.FEED_COUNT());
        console.log("");
        console.log("USDE/MAG7 rateProvider:", oracleUSDE.rateProvider());
        console.log("USDE/MAG7 quoteName:", oracleUSDE.quoteName());
        console.log("USDE/MAG7 oracleName:", oracleUSDE.oracleName());
        console.log("USDE/MAG7 feedCount:", oracleUSDE.FEED_COUNT());
        console.log("");
    }
}
