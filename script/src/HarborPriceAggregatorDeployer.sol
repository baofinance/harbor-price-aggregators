// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {FactoryDeployer, WellKnownAddress} from "@bao-script/deployment/FactoryDeployer.sol";

/// @notice Harbor-specific FactoryDeployer for price aggregator deployment.
/// @dev Mirrors HarborFactoryDeployer in harbor/script but scoped to harbor-price-aggregators.
///      All oracle deployment contracts inherit from this.
abstract contract HarborPriceAggregatorDeployer is FactoryDeployer {
    address private constant _TREASURY_OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    function treasury() public pure override returns (address) {
        return _TREASURY_OWNER;
    }

    function owner() public pure override returns (address) {
        return _TREASURY_OWNER;
    }

    function getWellKnownAddresses() public view virtual override returns (WellKnownAddress[] memory addrs) {
        addrs = new WellKnownAddress[](2);
        addrs[0] = WellKnownAddress({addr: _TREASURY_OWNER, label: "harbor_multisig"});
        addrs[1] = WellKnownAddress({addr: baoFactory(), label: "baoFactory"});
    }
}
