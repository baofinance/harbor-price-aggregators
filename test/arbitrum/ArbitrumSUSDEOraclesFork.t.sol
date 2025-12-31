// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Aggregator_USDE_AAPL_arbitrum} from "../../src/arbitrum/Aggregator_USDE_AAPL_arbitrum.sol";
import {Aggregator_USDE_AMZN_arbitrum} from "../../src/arbitrum/Aggregator_USDE_AMZN_arbitrum.sol";
import {Aggregator_USDE_GOOGL_arbitrum} from "../../src/arbitrum/Aggregator_USDE_GOOGL_arbitrum.sol";
import {Aggregator_USDE_META_arbitrum} from "../../src/arbitrum/Aggregator_USDE_META_arbitrum.sol";
import {Aggregator_USDE_MSFT_arbitrum} from "../../src/arbitrum/Aggregator_USDE_MSFT_arbitrum.sol";
import {Aggregator_USDE_NVDA_arbitrum} from "../../src/arbitrum/Aggregator_USDE_NVDA_arbitrum.sol";
import {Aggregator_USDE_SPY_arbitrum} from "../../src/arbitrum/Aggregator_USDE_SPY_arbitrum.sol";
import {Aggregator_USDE_TSLA_arbitrum} from "../../src/arbitrum/Aggregator_USDE_TSLA_arbitrum.sol";

/// @notice Fork tests for Arbitrum USDE oracles
/// @dev Run with: forge test --match-path "test/arbitrum/*USDE*.t.sol" --fork-url $arbitrum -vvv
///      Ensure ARBITRUM_RPC_URL environment variable is set in foundry.toml
contract ArbitrumUSDEOraclesForkTest is Test {
    Aggregator_USDE_AAPL_arbitrum public oracleAAPL;
    Aggregator_USDE_AMZN_arbitrum public oracleAMZN;
    Aggregator_USDE_GOOGL_arbitrum public oracleGOOGL;
    Aggregator_USDE_META_arbitrum public oracleMETA;
    Aggregator_USDE_MSFT_arbitrum public oracleMSFT;
    Aggregator_USDE_NVDA_arbitrum public oracleNVDA;
    Aggregator_USDE_SPY_arbitrum public oracleSPY;
    Aggregator_USDE_TSLA_arbitrum public oracleTSLA;

    function setUp() public {
        // Create fork - skip if RPC URL not available
        try vm.createSelectFork("arbitrum") {} catch {
            vm.skip(true);
        }

        // Deploy all oracles
        oracleAAPL = new Aggregator_USDE_AAPL_arbitrum();
        oracleAMZN = new Aggregator_USDE_AMZN_arbitrum();
        oracleGOOGL = new Aggregator_USDE_GOOGL_arbitrum();
        oracleMETA = new Aggregator_USDE_META_arbitrum();
        oracleMSFT = new Aggregator_USDE_MSFT_arbitrum();
        oracleNVDA = new Aggregator_USDE_NVDA_arbitrum();
        oracleSPY = new Aggregator_USDE_SPY_arbitrum();
        oracleTSLA = new Aggregator_USDE_TSLA_arbitrum();
    }

    function test_AAPL_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleAAPL.latestAnswer();
        console.log("=== USDE/AAPL Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_AMZN_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleAMZN.latestAnswer();
        console.log("=== USDE/AMZN Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_GOOGL_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleGOOGL.latestAnswer();
        console.log("=== USDE/GOOGL Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_META_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleMETA.latestAnswer();
        console.log("=== USDE/META Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_MSFT_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleMSFT.latestAnswer();
        console.log("=== USDE/MSFT Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_NVDA_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleNVDA.latestAnswer();
        console.log("=== USDE/NVDA Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_SPY_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleSPY.latestAnswer();
        console.log("=== USDE/SPY Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_TSLA_RateAndPrice() public view {
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = oracleTSLA.latestAnswer();
        console.log("=== USDE/TSLA Oracle ===");
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");
    }

    function test_AllOracles_RateAndPrice() public view {
        test_AAPL_RateAndPrice();
        test_AMZN_RateAndPrice();
        test_GOOGL_RateAndPrice();
        test_META_RateAndPrice();
        test_MSFT_RateAndPrice();
        test_NVDA_RateAndPrice();
        test_SPY_RateAndPrice();
        test_TSLA_RateAndPrice();
    }

    function test_CheckOracleMetadata() public view {
        console.log("=== Oracle Metadata ===");
        console.log("AAPL rateProvider:", oracleAAPL.rateProvider());
        console.log("AAPL quoteName:", oracleAAPL.quoteName());
        console.log("AAPL oracleName:", oracleAAPL.oracleName());
        console.log("");
    }
}
