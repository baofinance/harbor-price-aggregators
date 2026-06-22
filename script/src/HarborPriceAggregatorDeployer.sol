// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {FactoryDeployer, WellKnownAddress} from "@bao-script/deployment/FactoryDeployer.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";

/// @notice Harbor-specific FactoryDeployer for price aggregator deployment.
/// @dev Mirrors HarborFactoryDeployer in harbor/script but scoped to harbor-price-aggregators.
///      All oracle deployment contracts inherit from this.
abstract contract HarborPriceAggregatorDeployer is FactoryDeployer {
    address private constant _TREASURY_OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @notice The CREATE3 salt key for any price aggregator, derived from the implementation's own
    ///         declared base/quote: `{baseName}::{quoteName}::wrappedPriceAggregator`. The full salt is
    ///         `{saltPrefix}::{baseName}::{quoteName}::wrappedPriceAggregator`. Every aggregator — ETH
    ///         gas-floor or equivalent-vault valuation — uses this one scheme, and consumers predict the
    ///         same address from the same `{base}::{quote}::wrappedPriceAggregator` key.
    function _aggregatorKey(address impl) internal pure returns (string memory) {
        return
            _key(
                _key(IHarborPriceAggregatorV3(impl).baseName(), IHarborPriceAggregatorV3(impl).quoteName()),
                "wrappedPriceAggregator"
            );
    }

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
