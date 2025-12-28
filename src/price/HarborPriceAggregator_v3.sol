// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BaoFixedOwnable} from "@bao/BaoFixedOwnable.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";

/// @notice Shared base for v3 price aggregators.
/// @dev Concrete implementations override `latestAnswer()` and implement identity getters.
/// @custom:oz-upgrades-unsafe-allow constructor
abstract contract HarborPriceAggregator_v3 is IHarborPriceAggregatorV3, UUPSUpgradeable, BaoFixedOwnable {
    address private constant _OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @dev initialises this to _OWNER immediately
    constructor() BaoFixedOwnable(address(0), _OWNER, 0) {}

    function version() external pure returns (uint256) {
        return 3;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
