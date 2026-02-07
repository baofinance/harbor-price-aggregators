// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";

import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses} from "./DeployedAddresses.sol";
import {OracleComparisonBase} from "./OracleComparisonBase.sol";

import {Aggregator_fxUSD_ETH_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_ETH_mainnet.sol";
import {Aggregator_fxUSD_BTC_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_BTC_mainnet.sol";
import {Aggregator_fxUSD_EUR_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_EUR_mainnet.sol";
import {Aggregator_fxUSD_GOLD_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_GOLD_mainnet.sol";
import {Aggregator_fxUSD_MCAP_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_MCAP_mainnet.sol";
import {Aggregator_stETH_BTC_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_BTC_mainnet.sol";
import {Aggregator_stETH_EUR_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_EUR_mainnet.sol";
import {Aggregator_stETH_GOLD_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_GOLD_mainnet.sol";
import {Aggregator_stETH_MCAP_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_MCAP_mainnet.sol";

/// @title All Oracle Comparisons
/// @notice Compares deployed v3 oracles against locally built v3 oracles
/// @dev Used for regression testing after code changes
contract AllOracleComparisons is OracleComparisonBase {
    function test_compare_all_v3() public {
        vm.skip(true); // Skip on CI due to 429 rate limit issues
        console.log("=== V3 Oracle Comparisons (deployed vs local) ===");
        console.log("  deployment block: %d", START_BLOCK);
        console.log("  end: %s", _formatBlock(endBlock, endTimestamp));

        _prepareForComparison();
        _compareAllV3();
    }

    function _compareAllV3() internal {
        // ===== fxUSD oracles =====
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_BTC),
            _deployV3(address(new Aggregator_fxUSD_BTC_mainnet())),
            "FXUSD_BTC_v3"
        );

        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_ETH),
            _deployV3(address(new Aggregator_fxUSD_ETH_mainnet())),
            "FXUSD_ETH_v3"
        );

        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_EUR),
            _deployV3(address(new Aggregator_fxUSD_EUR_mainnet())),
            "FXUSD_EUR_v3"
        );

        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_XAU),
            _deployV3(address(new Aggregator_fxUSD_GOLD_mainnet())),
            "FXUSD_GOLD_v3"
        );

        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_MCAP),
            _deployV3(address(new Aggregator_fxUSD_MCAP_mainnet())),
            "FXUSD_MCAP_v3"
        );

        // ===== stETH oracles =====
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_BTC),
            _deployV3(address(new Aggregator_stETH_BTC_mainnet())),
            "STETH_BTC_v3"
        );

        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_EUR),
            _deployV3(address(new Aggregator_stETH_EUR_mainnet())),
            "STETH_EUR_v3"
        );

        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_XAU),
            _deployV3(address(new Aggregator_stETH_GOLD_mainnet())),
            "STETH_GOLD_v3"
        );

        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_MCAP),
            _deployV3(address(new Aggregator_stETH_MCAP_mainnet())),
            "STETH_MCAP_v3"
        );
    }
}
