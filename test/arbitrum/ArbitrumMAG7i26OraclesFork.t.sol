// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Oracle_stETH_MAG7i26_arbitrum} from "../../src/arbitrum/Oracle_stETH_MAG7i26_arbitrum.sol";
import {Oracle_USDE_MAG7i26_arbitrum} from "../../src/arbitrum/Oracle_USDE_MAG7i26_arbitrum.sol";

/// @notice Fork tests for Arbitrum MAG7.i26 indexed oracles
/// @dev Run with: forge test --match-path "test/arbitrum/*MAG7i26*.t.sol" --fork-url $arbitrum -vvv
///      Ensure ARBITRUM_RPC_URL environment variable is set in foundry.toml
contract ArbitrumMAG7i26OraclesForkTest is Test {
    Oracle_stETH_MAG7i26_arbitrum public oracleStETH;
    Oracle_USDE_MAG7i26_arbitrum public oracleUSDE;

    function setUp() public {
        // Deploy both MAG7.i26 oracles
        oracleStETH = new Oracle_stETH_MAG7i26_arbitrum();
        oracleUSDE = new Oracle_USDE_MAG7i26_arbitrum();
    }

    function test_stETH_MAG7i26_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleStETH.latestAnswer();
        console.log("=== stETH/MAG7.i26 Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("Index Price:", oracleStETH.INDEX_PRICE());
        console.log("");
    }

    function test_USDE_MAG7i26_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleUSDE.latestAnswer();
        console.log("=== USDE/MAG7.i26 Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("Index Price:", oracleUSDE.INDEX_PRICE());
        console.log("");
    }

    function test_AllMAG7i26Oracles_RateAndPrice() public view {
        test_stETH_MAG7i26_RateAndPrice();
        test_USDE_MAG7i26_RateAndPrice();
    }

    function test_CheckOracleMetadata() public view {
        console.log("=== Oracle Metadata ===");
        console.log("stETH/MAG7.i26 base:", oracleStETH.base());
        console.log("stETH/MAG7.i26 rateProvider:", oracleStETH.rateProvider());
        console.log("stETH/MAG7.i26 quoteName:", oracleStETH.quoteName());
        console.log("stETH/MAG7.i26 oracleName:", oracleStETH.oracleName());
        console.log("stETH/MAG7.i26 indexPrice:", oracleStETH.INDEX_PRICE());
        console.log("");
        console.log("USDE/MAG7.i26 base:", oracleUSDE.base());
        console.log("USDE/MAG7.i26 rateProvider:", oracleUSDE.rateProvider());
        console.log("USDE/MAG7.i26 quoteName:", oracleUSDE.quoteName());
        console.log("USDE/MAG7.i26 oracleName:", oracleUSDE.oracleName());
        console.log("USDE/MAG7.i26 indexPrice:", oracleUSDE.INDEX_PRICE());
        console.log("");
    }
}

