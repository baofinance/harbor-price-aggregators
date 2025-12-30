// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";

import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses} from "../DeployedAddresses.sol";
import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {OracleComparisonBase} from "./OracleComparisonBase.sol";

import {Aggregator_fxUSD_ETH_mainnet} from "@harbor-price/Aggregator_fxUSD_ETH_mainnet.sol";
import {Aggregator_fxUSD_BTC_mainnet} from "@harbor-price/Aggregator_fxUSD_BTC_mainnet.sol";
import {Aggregator_fxUSD_EUR_mainnet} from "@harbor-price/Aggregator_fxUSD_EUR_mainnet.sol";
import {Aggregator_fxUSD_XAU_mainnet} from "@harbor-price/Aggregator_fxUSD_XAU_mainnet.sol";
import {Aggregator_fxUSD_MCAP_mainnet} from "@harbor-price/Aggregator_fxUSD_MCAP_mainnet.sol";
import {Aggregator_stETH_BTC_mainnet} from "@harbor-price/Aggregator_stETH_BTC_mainnet.sol";
import {Aggregator_stETH_EUR_mainnet} from "@harbor-price/Aggregator_stETH_EUR_mainnet.sol";
import {Aggregator_stETH_XAU_mainnet} from "@harbor-price/Aggregator_stETH_XAU_mainnet.sol";
import {Aggregator_stETH_MCAP_mainnet} from "@harbor-price/Aggregator_stETH_MCAP_mainnet.sol";

contract AllOracleComparisons is OracleComparisonBase {
    function test_compare_all() public {
        vm.skip(true);
        console.log("=== All Oracle Comparisons ===");
        console.log("  deployment block: %d", START_BLOCK);
        console.log("  end: %s", _formatBlock(endBlock, endTimestamp));

        _prepareForComparison();
        _compareAll();
    }

    function _compareAll() internal {
        // ===== fxUSD =====
        // FXUSD / BTC (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_BTC),
            _deploySingleFeed("FxUSDToBTC", MainnetOracleAddresses.BTC_USD_FEED, 1, true),
            "FXUSD_BTC"
        );

        // FXUSD / BTC (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_BTC),
            _deployV3(address(new Aggregator_fxUSD_BTC_mainnet())),
            "FXUSD_BTC_v3"
        );

        // FXUSD / ETH (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_ETH),
            _deploySingleFeed("FxUSDToETH", MainnetOracleAddresses.ETH_USD_FEED, 1, true),
            "FXUSD_ETH"
        );

        // FXUSD / ETH (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_ETH),
            _deployV3(address(new Aggregator_fxUSD_ETH_mainnet())),
            "FXUSD_ETH_v3"
        );

        // FXUSD / ETH (local v2 vs local v3)
        _compareOracle(
            _deploySingleFeed("FxUSDToETH", MainnetOracleAddresses.ETH_USD_FEED, 1, true),
            _deployV3(address(new Aggregator_fxUSD_ETH_mainnet())),
            "FXUSD_ETH_v3_vs_v2"
        );

        // FXUSD / EUR (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_EUR),
            _deploySingleFeed("FxUSDToEUR", MainnetOracleAddresses.EUR_USD_FEED, 1, true),
            "FXUSD_EUR"
        );

        // FXUSD / EUR (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_EUR),
            _deployV3(address(new Aggregator_fxUSD_EUR_mainnet())),
            "FXUSD_EUR_v3"
        );

        // FXUSD / MCAP (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_MCAP),
            _deploySingleFeed("FxUSDToMCAP", MainnetOracleAddresses.MCAP_USD_FEED, 1e12, true),
            "FXUSD_MCAP"
        );

        // FXUSD / MCAP (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_MCAP),
            _deployV3(address(new Aggregator_fxUSD_MCAP_mainnet())),
            "FXUSD_MCAP_v3"
        );

        // FXUSD / XAU (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_XAU),
            _deploySingleFeed("FxUSDToXAU", MainnetOracleAddresses.XAU_USD_FEED, 1, true),
            "FXUSD_XAU"
        );

        // FXUSD / XAU (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.FXUSD_XAU),
            _deployV3(address(new Aggregator_fxUSD_XAU_mainnet())),
            "FXUSD_XAU_v3"
        );

        // ===== stETH =====
        // STETH / BTC (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_BTC),
            _deployDoubleFeed(
                "StETHToBTC",
                MainnetOracleAddresses.ETH_USD_FEED,
                MainnetOracleAddresses.BTC_USD_FEED,
                1,
                false
            ),
            "STETH_BTC"
        );

        // STETH / BTC (deployed v2 vs local v3)
        _compareOracleApproxPrice(
            IWrappedPriceOracle(DeployedAddresses.STETH_BTC),
            _deployV3(address(new Aggregator_stETH_BTC_mainnet())),
            "STETH_BTC_v3",
            0,
            463e13
        );

        // STETH / BTC (local v2 vs local v3)
        _compareOracle(
            _deployDoubleFeed(
                "StETHToBTC",
                MainnetOracleAddresses.STETH_USD_FEED,
                MainnetOracleAddresses.BTC_USD_FEED,
                1,
                false
            ),
            _deployV3(address(new Aggregator_stETH_BTC_mainnet())),
            "STETH_BTC_v3_vs_v2"
        );

        // STETH / EUR (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_EUR),
            _deployDoubleFeed(
                "StETHToEUR",
                MainnetOracleAddresses.ETH_USD_FEED,
                MainnetOracleAddresses.EUR_USD_FEED,
                1,
                false
            ),
            "STETH_EUR"
        );

        // STETH / EUR (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_EUR),
            _deployV3(address(new Aggregator_stETH_EUR_mainnet())),
            "STETH_EUR_v3"
        );

        // STETH / MCAP (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_MCAP),
            _deployDoubleFeed(
                "StETHToMCAP",
                MainnetOracleAddresses.ETH_USD_FEED,
                MainnetOracleAddresses.MCAP_USD_FEED,
                1e12,
                false
            ),
            "STETH_MCAP"
        );

        // STETH / MCAP (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_MCAP),
            _deployV3(address(new Aggregator_stETH_MCAP_mainnet())),
            "STETH_MCAP_v3"
        );

        // STETH / XAU (deployed v2 vs local v2)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_XAU),
            _deployDoubleFeed(
                "StETHToXAU",
                MainnetOracleAddresses.ETH_USD_FEED,
                MainnetOracleAddresses.XAU_USD_FEED,
                1,
                false
            ),
            "STETH_XAU"
        );

        // STETH / XAU (deployed v2 vs local v3)
        _compareOracle(
            IWrappedPriceOracle(DeployedAddresses.STETH_XAU),
            _deployV3(address(new Aggregator_stETH_XAU_mainnet())),
            "STETH_XAU_v3"
        );
    }
}
