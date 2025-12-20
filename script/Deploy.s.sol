// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {console2 as console} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {PriceAggregatorsDeploymentJsonScript} from "./deployment/PriceAggregatorsDeploymentJsonScript.sol";

contract DeployPriceOracles is PriceAggregatorsDeploymentJsonScript {
    function run(string memory network, string memory salt) public virtual {
        console.log("=== Deploying Harbor Price Oracles ===");
        console.log("Network: %s", network);
        console.log("Salt: %s", salt);
        string memory systemSalt = string.concat(salt, "::PriceOracle");
        console.log("SystemSalt: %s", systemSalt);

        // disableIncrementalLogging();

        start(network, systemSalt, "");

        _deployPriceOracle(FXUSD_ETH_FEED);
        _deployPriceOracle(FXUSD_BTC_FEED);
        _deployPriceOracle(FXUSD_EUR_FEED);
        _deployPriceOracle(FXUSD_XAU_FEED);
        _deployPriceOracle(FXUSD_MCAP_FEED);
        _deployPriceOracle(STETH_BTC_FEED);
        _deployPriceOracle(STETH_EUR_FEED);
        _deployPriceOracle(STETH_XAU_FEED);
        _deployPriceOracle(STETH_MCAP_FEED);

        finish();

        console.log("\n=== Complete ===");
    }
}
