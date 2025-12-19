// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {HarborDoubleFeedAndRateAggregator_v1} from "../src/price/HarborDoubleFeedAndRateAggregator_v1.sol";
import {HarborSingleFeedAndRateAggregator_v1} from "../src/price/HarborSingleFeedAndRateAggregator_v1.sol";
import {HarborCustomFeedAndRateAggregator_v1} from "../src/price/HarborCustomFeedAndRateAggregator_v1.sol";

/**
 * @title Upgrade Proxy Script
 * @notice Script to upgrade deployed proxy contracts to a new implementation
 * 
 * Usage:
 *   forge script script/upgrade-proxy.s.sol:UpgradeProxyScript \
 *     --rpc-url $RPC_URL \
 *     --broadcast \
 *     --verify \
 *     --etherscan-api-key $ETHERSCAN_API_KEY \
 *     -vvvv
 * 
 * Environment variables:
 *   PROXY_ADDRESS: Address of the proxy to upgrade (required)
 *   NEW_IMPL_ADDRESS: Address of the new implementation (optional - will deploy if not provided)
 *   WSTETH: wstETH contract address (required for deploying new impl)
 *   FXSAVE: fxSAVE contract address (required for deploying new impl)
 *   SUSDE_USDE_FEED: sUSDE/USDE Chainlink feed (can be address(0))
 *   WSTETH_STETH_FEED: wstETH/stETH Chainlink feed (can be address(0))
 */
contract UpgradeProxyScript is Script {
    function setUp() public {}

    function run() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        // Determine contract type by checking which interface it implements
        // For simplicity, we'll use HarborDoubleFeedAndRateAggregator_v1 as the interface
        // since all three contracts share similar upgrade mechanisms
        
        HarborDoubleFeedAndRateAggregator_v1 proxy = HarborDoubleFeedAndRateAggregator_v1(proxyAddress);
        
        // Get the owner (who can upgrade)
        address owner = proxy.owner();
        require(owner != address(0), "Owner not set");
        
        console.log("Proxy Address:", proxyAddress);
        console.log("Current Owner:", owner);
        
        // Get current implementation address
        bytes32 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 implData = vm.load(proxyAddress, implSlot);
        address currentImpl = address(uint160(uint256(implData)));
        console.log("Current Implementation:", currentImpl);
        
        // Deploy new implementation or use provided address
        address newImpl;
        if (vm.envOr("NEW_IMPL_ADDRESS", address(0)) != address(0)) {
            newImpl = vm.envAddress("NEW_IMPL_ADDRESS");
            console.log("Using provided implementation:", newImpl);
        } else {
            // Deploy new implementation
            // Note: You'll need to determine which contract type to deploy based on the proxy
            // For now, assuming DoubleFeed (most common)
            address wsteth = vm.envAddress("WSTETH");
            address fxsave = vm.envAddress("FXSAVE");
            address susdeUsdeFeed = vm.envOr("SUSDE_USDE_FEED", address(0));
            address wstethStethFeed = vm.envOr("WSTETH_STETH_FEED", address(0));
            
            console.log("Deploying new implementation...");
            vm.startBroadcast(owner);
            HarborDoubleFeedAndRateAggregator_v1 newImplementation = new HarborDoubleFeedAndRateAggregator_v1(
                wsteth,
                fxsave,
                susdeUsdeFeed,
                wstethStethFeed
            );
            newImpl = address(newImplementation);
            vm.stopBroadcast();
            console.log("New Implementation Deployed:", newImpl);
        }
        
        require(newImpl != address(0), "New implementation address required");
        require(newImpl != currentImpl, "New implementation must be different from current");
        
        // Perform upgrade
        console.log("\n=== Upgrading Proxy ===");
        console.log("Proxy:", proxyAddress);
        console.log("From Implementation:", currentImpl);
        console.log("To Implementation:", newImpl);
        console.log("Upgrading as:", owner);
        
        vm.startBroadcast(owner);
        proxy.upgradeToAndCall(newImpl, "");
        vm.stopBroadcast();
        
        // Verify upgrade
        implData = vm.load(proxyAddress, implSlot);
        address upgradedImpl = address(uint160(uint256(implData)));
        require(upgradedImpl == newImpl, "Upgrade failed - implementation not updated");
        
        console.log("\n=== Upgrade Successful ===");
        console.log("New Implementation Address:", upgradedImpl);
        
        // Verify functionality still works
        try proxy.oracleName() returns (string memory name) {
            console.log("Oracle Name:", name);
        } catch {}
        
        try proxy.owner() returns (address ownerAfter) {
            require(ownerAfter == owner, "Owner should be preserved");
            console.log("Owner Preserved:", ownerAfter);
        } catch {}
    }
}




