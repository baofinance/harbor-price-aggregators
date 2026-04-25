// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {console2 as console} from "forge-std/console2.sol";
import {HarborPriceAggregatorDeployer} from "@harbor-script/src/HarborPriceAggregatorDeployer.sol";
import {DeploymentState} from "@bao-script/deployment/DeploymentState.sol";
import {DeploymentTypes} from "@bao-script/deployment/DeploymentTypes.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";

/// @notice Generic ETH price oracle deployment via BaoFactory CREATE3.
/// @dev Salt: {saltPrefix}::{peg}::ethPriceAggregator — must match what AutoCompounder_v1 predicts.
///      The peg name is read from the implementation's baseName() — no separate config needed.
abstract contract DeployEthPriceOracles is HarborPriceAggregatorDeployer {
    /// @notice Deploy a peg/ETH price oracle proxy and record it in deployment state.
    /// @param saltPrefix_ The salt prefix (e.g. "harbor_v1") — must match the minter deploy salt.
    /// @param impl The oracle implementation (e.g. address(new EthPriceAggregator_EUR_mainnet())).
    /// @param network Network name for state recording (e.g. "mainnet").
    function deployEthPriceOracle(string memory saltPrefix_, address impl, string memory network) internal {
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

        string memory peg = IHarborPriceAggregatorV3(impl).baseName();
        string memory oracleKey = _key(peg, "ethPriceAggregator");

        console.log("--- Deploying %s ---", _saltString(oracleKey));
        console.log("      Impl: %s", impl);

        _recordImplementation(
            state,
            oracleKey,
            string.concat("@harbor-price/mainnet/EthPriceAggregator_", peg, "_mainnet.sol"),
            string.concat("EthPriceAggregator_", peg, "_mainnet"),
            impl
        );
        _deployProxyAndRecord(state, oracleKey, impl, "");

        _transferAllOwnerships();
        _saveState(state);
    }
}
