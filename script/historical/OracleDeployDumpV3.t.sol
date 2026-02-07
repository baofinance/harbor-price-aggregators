// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {LatestAnswerErrorClassifier} from "./LatestAnswerErrorClassifier.sol";

// v3 mainnet wrappers (parameterless constructors)
import {Aggregator_fxUSD_ETH_mainnet} from "../../src/mainnet/Aggregator_fxUSD_ETH_mainnet.sol";
import {Aggregator_fxUSD_BTC_mainnet} from "../../src/mainnet/Aggregator_fxUSD_BTC_mainnet.sol";
import {Aggregator_fxUSD_EUR_mainnet} from "../../src/mainnet/Aggregator_fxUSD_EUR_mainnet.sol";
import {Aggregator_fxUSD_GOLD_mainnet} from "../../src/mainnet/Aggregator_fxUSD_GOLD_mainnet.sol";
import {Aggregator_fxUSD_MCAP_mainnet} from "../../src/mainnet/Aggregator_fxUSD_MCAP_mainnet.sol";
import {Aggregator_stETH_BTC_mainnet} from "../../src/mainnet/Aggregator_stETH_BTC_mainnet.sol";
import {Aggregator_stETH_EUR_mainnet} from "../../src/mainnet/Aggregator_stETH_EUR_mainnet.sol";
import {Aggregator_stETH_GOLD_mainnet} from "../../src/mainnet/Aggregator_stETH_GOLD_mainnet.sol";
import {Aggregator_stETH_MCAP_mainnet} from "../../src/mainnet/Aggregator_stETH_MCAP_mainnet.sol";

/// @title Oracle Deploy Dump V3
/// @notice Extracts historical oracle data by deploying v3 oracles at each block and sampling.
/// @dev Simulates what v3 oracles would have returned if deployed at each historical block.
contract OracleDeployDumpV3 is Test {
    // Block range for historical dump
    // The earliest block where all required feeds exist (adjust as needed)
    uint256 constant START_BLOCK = 21_400_000;
    // Fork block - must be >= END_BLOCK
    uint256 constant FORK_BLOCK = 24_060_836;
    // End block for the dump
    uint256 constant END_BLOCK = 24_060_836;
    // Sample every N blocks
    uint256 constant SAMPLE_STEP = 300;

    // Oracle type enum for deployment
    enum OracleType {
        FXUSD_ETH,
        FXUSD_BTC,
        FXUSD_EUR,
        FXUSD_GOLD,
        FXUSD_MCAP,
        STETH_BTC,
        STETH_EUR,
        STETH_GOLD,
        STETH_MCAP
    }

    function setUp() public {
        vm.createSelectFork("mainnet", FORK_BLOCK);
    }

    /// @dev Deploy a v3 oracle at the current block
    function _deployOracle(OracleType oracleType) internal returns (address) {
        if (oracleType == OracleType.FXUSD_ETH) return address(new Aggregator_fxUSD_ETH_mainnet());
        if (oracleType == OracleType.FXUSD_BTC) return address(new Aggregator_fxUSD_BTC_mainnet());
        if (oracleType == OracleType.FXUSD_EUR) return address(new Aggregator_fxUSD_EUR_mainnet());
        if (oracleType == OracleType.FXUSD_GOLD) return address(new Aggregator_fxUSD_GOLD_mainnet());
        if (oracleType == OracleType.FXUSD_MCAP) return address(new Aggregator_fxUSD_MCAP_mainnet());
        if (oracleType == OracleType.STETH_BTC) return address(new Aggregator_stETH_BTC_mainnet());
        if (oracleType == OracleType.STETH_EUR) return address(new Aggregator_stETH_EUR_mainnet());
        if (oracleType == OracleType.STETH_GOLD) return address(new Aggregator_stETH_GOLD_mainnet());
        if (oracleType == OracleType.STETH_MCAP) return address(new Aggregator_stETH_MCAP_mainnet());
        revert("Unknown oracle type");
    }

    function _dumpOracle(OracleType oracleType, string memory name, uint256 startBlock, uint256 endBlock) internal {
        string memory filename = string.concat("results/", name, "_v3.csv");
        vm.writeFile(filename, "block,timestamp,minPrice,maxPrice,minRate,maxRate,error\n");

        uint256 currentBlock = endBlock;
        uint256 count = 0;

        while (currentBlock >= startBlock) {
            vm.rollFork(currentBlock);

            // Deploy a fresh v3 oracle at this block
            address oracle = _deployOracle(oracleType);

            (
                bool stop,
                bool hasData,
                uint256 minPrice,
                uint256 maxPrice,
                uint256 minRate,
                uint256 maxRate,
                string memory err
            ) = LatestAnswerErrorClassifier.tryLatestAnswer(oracle);

            if (hasData) {
                vm.writeLine(
                    filename,
                    string.concat(
                        vm.toString(currentBlock),
                        ",",
                        vm.toString(block.timestamp),
                        ",",
                        vm.toString(minPrice),
                        ",",
                        vm.toString(maxPrice),
                        ",",
                        vm.toString(minRate),
                        ",",
                        vm.toString(maxRate),
                        ",",
                        err
                    )
                );
                count++;
            } else {
                vm.writeLine(
                    filename,
                    string.concat(vm.toString(currentBlock), ",", vm.toString(block.timestamp), ",0,0,0,0,", err)
                );
            }

            if (stop) {
                break;
            }

            if (count % 100 == 0) {
                console.log("%s: %d blocks dumped", name, count);
            }

            if (currentBlock < SAMPLE_STEP) {
                break;
            }
            currentBlock -= SAMPLE_STEP;
        }

        console.log("%s: finished with %d samples", name, count);
    }

    function test_dump_fxUSD_ETH() public {
        _dumpOracle(OracleType.FXUSD_ETH, "FXUSD_ETH", START_BLOCK, END_BLOCK);
    }

    function test_dump_fxUSD_BTC() public {
        _dumpOracle(OracleType.FXUSD_BTC, "FXUSD_BTC", START_BLOCK, END_BLOCK);
    }

    function test_dump_fxUSD_EUR() public {
        _dumpOracle(OracleType.FXUSD_EUR, "FXUSD_EUR", START_BLOCK, END_BLOCK);
    }

    function test_dump_fxUSD_GOLD() public {
        _dumpOracle(OracleType.FXUSD_GOLD, "FXUSD_GOLD", START_BLOCK, END_BLOCK);
    }

    function test_dump_fxUSD_MCAP() public {
        _dumpOracle(OracleType.FXUSD_MCAP, "FXUSD_MCAP", START_BLOCK, END_BLOCK);
    }

    function test_dump_stETH_BTC() public {
        _dumpOracle(OracleType.STETH_BTC, "STETH_BTC", START_BLOCK, END_BLOCK);
    }

    function test_dump_stETH_EUR() public {
        _dumpOracle(OracleType.STETH_EUR, "STETH_EUR", START_BLOCK, END_BLOCK);
    }

    function test_dump_stETH_GOLD() public {
        _dumpOracle(OracleType.STETH_GOLD, "STETH_GOLD", START_BLOCK, END_BLOCK);
    }

    function test_dump_stETH_MCAP() public {
        _dumpOracle(OracleType.STETH_MCAP, "STETH_MCAP", START_BLOCK, END_BLOCK);
    }

    function test_dump_all_oracles() public {
        _dumpOracle(OracleType.FXUSD_ETH, "FXUSD_ETH", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.FXUSD_BTC, "FXUSD_BTC", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.FXUSD_EUR, "FXUSD_EUR", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.FXUSD_GOLD, "FXUSD_GOLD", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.FXUSD_MCAP, "FXUSD_MCAP", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.STETH_BTC, "STETH_BTC", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.STETH_EUR, "STETH_EUR", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.STETH_GOLD, "STETH_GOLD", START_BLOCK, END_BLOCK);
        _dumpOracle(OracleType.STETH_MCAP, "STETH_MCAP", START_BLOCK, END_BLOCK);
    }
}
