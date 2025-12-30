// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BaoFixedOwnable} from "@bao/BaoFixedOwnable.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";

/// @notice Shared base for v3 price aggregators.
/// @dev Concrete implementations override `latestAnswer()` and implement identity getters.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
abstract contract HarborAggregator_v3 is IHarborPriceAggregatorV3, UUPSUpgradeable, BaoFixedOwnable {
    address private constant _OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @dev initialises this to _OWNER immediately
    constructor() BaoFixedOwnable(address(0), _OWNER, 0) {
        // this may not be strictly necessary but is safer to put in place because we derive from
        // UUPSUpgradeable which derives from Initializable :-/
        _disableInitializers();
    }

    function baseName() external pure returns (string memory) {
        return _baseName();
    }

    function quoteName() external pure returns (string memory) {
        return _quoteName();
    }

    function oracleName() external pure returns (string memory) {
        return string.concat(_baseName(), "/", _quoteName());
    }

    function version() external pure returns (uint256) {
        return 3;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {} // solhint-disable-line no-empty-blocks

    function _baseName() internal pure virtual returns (string memory);

    function _quoteName() internal pure virtual returns (string memory);
}
