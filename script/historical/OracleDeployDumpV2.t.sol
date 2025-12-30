// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses} from "../../test/DeployedAddresses.sol";
import {LatestAnswerErrorClassifier} from "./LatestAnswerErrorClassifier.sol";

/// @title Oracle Deploy Dump V2
/// @notice Extracts historical oracle data to CSV by rolling back blocks on a deterministic fork
contract OracleDeployDumpV2 is Test {
    // Start at the last deployment block so all oracles exist.
    uint256 constant START_BLOCK = DeployedAddresses.DEPLOYMENT_BLOCK;

    // Fork block must be >= all per-oracle dump end blocks.
    // This is intentionally pinned to match the historical CSVs committed under results/.
    uint256 constant FORK_BLOCK = 24_060_836;

    // Per-oracle dump end blocks (must match results/*.csv in git).
    uint256 constant END_BLOCK_COMMON = 24_060_669;
    uint256 constant END_BLOCK_FXUSD_ETH = 24_060_836;
    uint256 constant END_BLOCK_STETH_MCAP = 24_060_742;

    uint256 constant SAMPLE_STEP = 300;

    function setUp() public {
        vm.createSelectFork("mainnet", FORK_BLOCK);
    }

    function _dumpOracle(address oracle, string memory name, uint256 endBlock) internal {
        string memory filename = string.concat("results/", name, ".csv");
        vm.writeFile(filename, "block,timestamp,minPrice,maxPrice,minRate,maxRate,error\n");

        uint256 currentBlock = endBlock;
        uint256 count = 0;

        while (currentBlock >= START_BLOCK) {
            vm.rollFork(currentBlock);

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

            if (stop) break;

            if (count % 100 == 0) {
                console.log("%s: %d blocks dumped", name, count);
            }

            if (currentBlock < SAMPLE_STEP) {
                break;
            }
            currentBlock -= SAMPLE_STEP;
        }
    }

    function test_dump_all_oracles() public {
        _dumpOracle(DeployedAddresses.FXUSD_ETH, "FXUSD_ETH", END_BLOCK_FXUSD_ETH);
        _dumpOracle(DeployedAddresses.FXUSD_BTC, "FXUSD_BTC", END_BLOCK_COMMON);
        _dumpOracle(DeployedAddresses.FXUSD_EUR, "FXUSD_EUR", END_BLOCK_COMMON);
        _dumpOracle(DeployedAddresses.FXUSD_XAU, "FXUSD_XAU", END_BLOCK_COMMON);
        _dumpOracle(DeployedAddresses.FXUSD_MCAP, "FXUSD_MCAP", END_BLOCK_COMMON);
        _dumpOracle(DeployedAddresses.STETH_BTC, "STETH_BTC", END_BLOCK_COMMON);
        _dumpOracle(DeployedAddresses.STETH_EUR, "STETH_EUR", END_BLOCK_COMMON);
        _dumpOracle(DeployedAddresses.STETH_XAU, "STETH_XAU", END_BLOCK_COMMON);
        _dumpOracle(DeployedAddresses.STETH_MCAP, "STETH_MCAP", END_BLOCK_STETH_MCAP);
    }
}
