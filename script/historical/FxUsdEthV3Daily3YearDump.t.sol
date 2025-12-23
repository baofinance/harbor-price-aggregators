// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {Oracle_fxUSD_ETH} from "@harbor-price/price/oracles/Oracle_fxUSD_ETH.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {LatestAnswerErrorClassifier} from "./LatestAnswerErrorClassifier.sol";

/// @title fxUSD/ETH v3 Daily 3-Year Dump
/// @notice Deploys a fresh v3 fxUSD/ETH oracle and samples daily for ~3 years on a deterministic mainnet fork.
contract FxUsdEthV3Daily3YearDump is Test {
    // Deterministic end block (UTC 2025-12-22 11:32:47). Keep in sync with other forked harnesses if desired.
    uint256 constant END_BLOCK = 24_067_873;

    // Approximate blocks/day on Ethereum (~12s blocks).
    uint256 constant BLOCKS_PER_DAY = 7_200;
    uint256 constant DAYS = 365 * 1;

    function test_dump_fxusd_eth_v3_daily_3y() public {
        vm.createSelectFork("mainnet", END_BLOCK);

        // Deploy a fresh v3 implementation + proxy (do not use already-deployed proxies).
        Oracle_fxUSD_ETH impl = new Oracle_fxUSD_ETH(
            MainnetOracleAddresses.FXSAVE,
            MainnetOracleAddresses.ETH_USD_FEED,
            1,
            true,
            MainnetOracleAddresses.MAX_AGE,
            MainnetOracleAddresses.MAX_DEV
        );

        bytes memory initData = abi.encodeCall(HarborPriceAggregator_v3.initialize, (address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        IWrappedPriceOracle oracle = IWrappedPriceOracle(address(proxy));

        string memory filename = "results/FXUSD_ETH_v3_daily_3y.csv";
        vm.writeFile(filename, "block,timestamp,minPrice,maxPrice,minRate,maxRate,error\n");

        for (uint256 i = 0; i <= DAYS; i++) {
            uint256 sampleBlock = END_BLOCK - (i * BLOCKS_PER_DAY);
            vm.rollFork(sampleBlock);

            (
                bool stop,
                bool hasData,
                uint256 minPrice,
                uint256 maxPrice,
                uint256 minRate,
                uint256 maxRate,
                string memory err
            ) = LatestAnswerErrorClassifier.tryLatestAnswer(address(oracle));

            if (hasData) {
                vm.writeLine(
                    filename,
                    string.concat(
                        vm.toString(sampleBlock),
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
            } else {
                vm.writeLine(
                    filename,
                    string.concat(
                        vm.toString(sampleBlock),
                        ",",
                        vm.toString(block.timestamp),
                        ",0,0,0,0,",
                        err
                    )
                );
            }

            if (stop) break;
        }
    }
}
