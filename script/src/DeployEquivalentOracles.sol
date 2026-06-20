// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {console2 as console} from "forge-std/console2.sol";
import {HarborPriceAggregatorDeployer} from "@harbor-price-script/src/HarborPriceAggregatorDeployer.sol";
import {DeploymentState} from "@bao-script/deployment/DeploymentState.sol";
import {DeploymentTypes} from "@bao-script/deployment/DeploymentTypes.sol";

/// @notice Deployment of equivalent-vault valuation oracles via BaoFactory CREATE3.
/// @dev These oracles price a HarborYield equivalent vault's underlying (e.g. wstETH) against the peg.
///      They are deployed in the same salt-prefixed campaign as the rest of the protocol, so HarborYield
///      references them by predicted address (`_predictAddress(key)`). The `key` MUST match the key the
///      HarborYield config uses (e.g. "stETH::ETH::wrappedPriceAggregator").
abstract contract DeployEquivalentOracles is HarborPriceAggregatorDeployer {
    /// @notice Deploy a valuation-oracle proxy at a deterministic CREATE3 address and record it.
    /// @param saltPrefix_ The salt prefix (must match the protocol deploy salt).
    /// @param key The CREATE3 salt key (e.g. "stETH::ETH::wrappedPriceAggregator") — must match the HarborYield config.
    /// @param impl The oracle implementation (e.g. address(new Aggregator_stETH_ETH_mainnet())).
    /// @param sourcePath Source file path for state recording.
    /// @param contractName Contract name for state recording.
    /// @param network Network name for state recording (e.g. "mainnet").
    function deployEquivalentOracle(
        string memory saltPrefix_,
        string memory key,
        address impl,
        string memory sourcePath,
        string memory contractName,
        string memory network
    ) internal {
        _setSaltPrefix(saltPrefix_);

        DeploymentTypes.State memory state = _shouldPersistState()
            ? DeploymentState.load(_stateFileRead())
            : DeploymentTypes.State({
                network: network,
                saltPrefix: saltPrefix_,
                directoryPrefix: "",
                implementations: new DeploymentTypes.ImplementationRecord[](0),
                proxies: new DeploymentTypes.ProxyRecord[](0),
                baoFactory: address(0)
            });
        state.baoFactory = baoFactory();

        console.log("--- Deploying %s ---", _saltString(key));
        console.log("      Impl: %s", impl);

        _recordImplementation(state, key, sourcePath, contractName, impl);
        _deployProxyAndRecord(state, key, impl, "");

        _transferAllOwnerships();
        _saveState(state);
    }
}
