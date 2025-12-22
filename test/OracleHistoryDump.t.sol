// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses} from "./DeployedAddresses.sol";

/// @title Oracle History Dump
/// @notice Extracts historical oracle data to CSV by rolling back blocks
contract OracleHistoryDump is Test {
    uint256 constant BLOCKS_PER_DAY = 7200;

    function _dumpOracle(address oracle, string memory name) internal {
        string memory filename = string.concat("results/", name, ".csv");
        vm.writeFile(filename, "block,timestamp,minPrice,maxPrice,minRate,maxRate\n");

        uint256 currentBlock = block.number;
        uint256 count = 0;

        while (true) {
            vm.rollFork(currentBlock);

            // Check if contract exists at this block
            if (oracle.code.length == 0) {
                console.log("%s: stopped at block %d (no code) after %d samples", name, currentBlock, count);
                break;
            }

            try IWrappedPriceOracle(oracle).latestAnswer() returns (
                uint256 minPrice,
                uint256 maxPrice,
                uint256 minRate,
                uint256 maxRate
            ) {
                string memory line = string.concat(
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
                    vm.toString(maxRate)
                );
                vm.writeLine(filename, line);
                count++;

                if (count % 100 == 0) {
                    console.log("%s: %d blocks dumped", name, count);
                }

                currentBlock -= 300;
            } catch {
                console.log("%s: stopped at block %d (revert) after %d samples", name, currentBlock, count);
                break;
            }
        }
    }

    function test_dump_FXUSD_ETH() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.FXUSD_ETH, "FXUSD_ETH");
    }
    function test_dump_FXUSD_BTC() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.FXUSD_BTC, "FXUSD_BTC");
    }
    function test_dump_FXUSD_EUR() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.FXUSD_EUR, "FXUSD_EUR");
    }
    function test_dump_FXUSD_XAU() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.FXUSD_XAU, "FXUSD_XAU");
    }
    function test_dump_FXUSD_MCAP() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.FXUSD_MCAP, "FXUSD_MCAP");
    }
    function test_dump_STETH_BTC() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.STETH_BTC, "STETH_BTC");
    }
    function test_dump_STETH_EUR() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.STETH_EUR, "STETH_EUR");
    }
    function test_dump_STETH_XAU() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.STETH_XAU, "STETH_XAU");
    }
    function test_dump_STETH_MCAP() public {
        vm.skip(
            !vm.envOr("RUN_ORACLE_HISTORY_DUMP", false),
            "skipped by default (RPC throttling); set RUN_ORACLE_HISTORY_DUMP=1 to run"
        );
        vm.createSelectFork("mainnet");
        _dumpOracle(DeployedAddresses.STETH_MCAP, "STETH_MCAP");
    }
}
