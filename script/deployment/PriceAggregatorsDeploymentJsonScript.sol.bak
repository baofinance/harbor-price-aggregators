// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";

import {DeploymentBase} from "@bao-script/deployment/DeploymentBase.sol";
import {DeploymentDataMemory} from "@bao-script/deployment/DeploymentDataMemory.sol";
import {DeploymentJson} from "@bao-script/deployment/DeploymentJson.sol";
import {DeploymentJsonScript} from "@bao-script/deployment/DeploymentJsonScript.sol";
import {LibString} from "@solady/utils/LibString.sol";

import {DataType} from "@bao-script/deployment/DeploymentKeys.sol";

// v3 mainnet aggregators - all config is wired in the constructor
import {Aggregator_fxUSD_ETH_mainnet} from "@harbor-price/Aggregator_fxUSD_ETH_mainnet.sol";
import {Aggregator_fxUSD_BTC_mainnet} from "@harbor-price/Aggregator_fxUSD_BTC_mainnet.sol";
import {Aggregator_fxUSD_EUR_mainnet} from "@harbor-price/Aggregator_fxUSD_EUR_mainnet.sol";
import {Aggregator_fxUSD_XAU_mainnet} from "@harbor-price/Aggregator_fxUSD_XAU_mainnet.sol";
import {Aggregator_fxUSD_MCAP_mainnet} from "@harbor-price/Aggregator_fxUSD_MCAP_mainnet.sol";
import {Aggregator_stETH_BTC_mainnet} from "@harbor-price/Aggregator_stETH_BTC_mainnet.sol";
import {Aggregator_stETH_EUR_mainnet} from "@harbor-price/Aggregator_stETH_EUR_mainnet.sol";
import {Aggregator_stETH_XAU_mainnet} from "@harbor-price/Aggregator_stETH_XAU_mainnet.sol";
import {Aggregator_stETH_MCAP_mainnet} from "@harbor-price/Aggregator_stETH_MCAP_mainnet.sol";

/**
 * @title PriceAggregatorsDeploymentJsonScript
 * @notice Harbor v3 price aggregator deployment with JSON config
 * @dev Extends DeploymentJsonScript for v3 aggregators.
 *
 *      v3 aggregators have all config baked into concrete contracts,
 *      so deployment is simple - just instantiate the right contract.
 */

abstract contract PriceAggregatorsDeploymentJsonScript is DeploymentJsonScript {
    using LibString for string;

    // =========================================================================
    // Errors
    // =========================================================================

    error UnknownContractKey(string contractKey);

    // =========================================================================
    // Contract Keys
    // =========================================================================

    string public constant PREFIX = "prefix";
    string public constant TREASURY = "treasury";

    // Contract keys for each oracle
    string public constant FXUSD_ETH_FEED = "contracts.fxUSD-ETH";
    string public constant FXUSD_BTC_FEED = "contracts.fxUSD-BTC";
    string public constant FXUSD_EUR_FEED = "contracts.fxUSD-EUR";
    string public constant FXUSD_XAU_FEED = "contracts.fxUSD-GOLD";
    string public constant FXUSD_MCAP_FEED = "contracts.fxUSD-MCAP";
    string public constant STETH_BTC_FEED = "contracts.stETH-BTC";
    string public constant STETH_EUR_FEED = "contracts.stETH-EUR";
    string public constant STETH_XAU_FEED = "contracts.stETH-GOLD";
    string public constant STETH_MCAP_FEED = "contracts.stETH-MCAP";

    // ============================================================================
    // Configuration
    // ============================================================================

    constructor() {
        addStringKey(PREFIX);
        addAddressKey(TREASURY);

        // Register proxy keys for each oracle
        addProxy(FXUSD_ETH_FEED);
        addProxy(FXUSD_BTC_FEED);
        addProxy(FXUSD_EUR_FEED);
        addProxy(FXUSD_XAU_FEED);
        addProxy(FXUSD_MCAP_FEED);
        addProxy(STETH_BTC_FEED);
        addProxy(STETH_EUR_FEED);
        addProxy(STETH_XAU_FEED);
        addProxy(STETH_MCAP_FEED);
    }

    // ============================================================================
    // PriceOracle Deployment
    // ============================================================================

    /// @notice Deploy a v3 price oracle by contract key
    /// @dev v3 aggregators have all config in constructors - no initData needed
    function _deployPriceOracle(string memory contractKey) internal {
        console2.log("Deploying Price Oracle %s ...", contractKey);

        address impl;
        string memory implName;
        bytes memory creationCode;

        // v3: Each oracle is a distinct contract with config wired in mainnet wrapper
        if (contractKey.eq(FXUSD_ETH_FEED)) {
            impl = address(new Aggregator_fxUSD_ETH_mainnet());
            implName = type(Aggregator_fxUSD_ETH_mainnet).name;
            creationCode = type(Aggregator_fxUSD_ETH_mainnet).creationCode;
        } else if (contractKey.eq(FXUSD_BTC_FEED)) {
            impl = address(new Aggregator_fxUSD_BTC_mainnet());
            implName = type(Aggregator_fxUSD_BTC_mainnet).name;
            creationCode = type(Aggregator_fxUSD_BTC_mainnet).creationCode;
        } else if (contractKey.eq(FXUSD_EUR_FEED)) {
            impl = address(new Aggregator_fxUSD_EUR_mainnet());
            implName = type(Aggregator_fxUSD_EUR_mainnet).name;
            creationCode = type(Aggregator_fxUSD_EUR_mainnet).creationCode;
        } else if (contractKey.eq(FXUSD_XAU_FEED)) {
            impl = address(new Aggregator_fxUSD_XAU_mainnet());
            implName = type(Aggregator_fxUSD_XAU_mainnet).name;
            creationCode = type(Aggregator_fxUSD_XAU_mainnet).creationCode;
        } else if (contractKey.eq(FXUSD_MCAP_FEED)) {
            impl = address(new Aggregator_fxUSD_MCAP_mainnet());
            implName = type(Aggregator_fxUSD_MCAP_mainnet).name;
            creationCode = type(Aggregator_fxUSD_MCAP_mainnet).creationCode;
        } else if (contractKey.eq(STETH_BTC_FEED)) {
            impl = address(new Aggregator_stETH_BTC_mainnet());
            implName = type(Aggregator_stETH_BTC_mainnet).name;
            creationCode = type(Aggregator_stETH_BTC_mainnet).creationCode;
        } else if (contractKey.eq(STETH_EUR_FEED)) {
            impl = address(new Aggregator_stETH_EUR_mainnet());
            implName = type(Aggregator_stETH_EUR_mainnet).name;
            creationCode = type(Aggregator_stETH_EUR_mainnet).creationCode;
        } else if (contractKey.eq(STETH_XAU_FEED)) {
            impl = address(new Aggregator_stETH_XAU_mainnet());
            implName = type(Aggregator_stETH_XAU_mainnet).name;
            creationCode = type(Aggregator_stETH_XAU_mainnet).creationCode;
        } else if (contractKey.eq(STETH_MCAP_FEED)) {
            impl = address(new Aggregator_stETH_MCAP_mainnet());
            implName = type(Aggregator_stETH_MCAP_mainnet).name;
            creationCode = type(Aggregator_stETH_MCAP_mainnet).creationCode;
        } else {
            revert UnknownContractKey(contractKey);
        }

        console2.log(" - Implementation: %s at %s", implName, impl);

        // v3 has no initialize() - empty initData
        deployProxy(
            contractKey,
            "priceoracle",
            impl,
            "", // no initData
            implName,
            creationCode,
            _getAddress(SESSION_DEPLOYER)
        );
        _save();
    }
}
