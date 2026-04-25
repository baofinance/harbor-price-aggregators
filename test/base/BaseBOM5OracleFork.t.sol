// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Aggregator_stETH_BOM5_base} from "@harbor-price/base/Aggregator_stETH_BOM5_base.sol";

/// @notice Fork tests for Base BOM5 oracle
/// @dev Run with: forge test --match-path "test/base/*BOM5*.t.sol" --fork-url $base -vvv
///      Ensure BASE_RPC_URL environment variable is set in foundry.toml
contract BaseBOM5OracleForkTest is Test {
    Aggregator_stETH_BOM5_base public oracle;

    function setUp() public {
        vm.skip(true);
        // Create fork - skip if RPC URL not available
        try vm.createSelectFork("base") {} catch {
            vm.skip(true);
        }

        // Deploy BOM5 oracle
        oracle = new Aggregator_stETH_BOM5_base();
    }

    function test_BOM5_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracle.latestAnswer();
        console.log("=== stETH/BOM5 Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_CheckOracleMetadata() public view {
        console.log("=== Oracle Metadata ===");
        console.log("BOM5 base:", oracle.baseName());
        console.log("BOM5 rateProvider:", oracle.rateProvider());
        console.log("BOM5 quoteName:", oracle.quoteName());
        console.log("BOM5 oracleName:", oracle.oracleName());
        console.log("BOM5 feedCount:", oracle.FEED_COUNT());
        console.log("");
        console.log("Normalization Factors:");
        console.log("  DOGE:", oracle.NORM_FACTOR_0());
        console.log("  SHIB:", oracle.NORM_FACTOR_1());
        console.log("  PEPE:", oracle.NORM_FACTOR_2());
        console.log("  TRUMP:", oracle.NORM_FACTOR_3());
        console.log("  WIF:", oracle.NORM_FACTOR_4());
        console.log("");
    }
}
