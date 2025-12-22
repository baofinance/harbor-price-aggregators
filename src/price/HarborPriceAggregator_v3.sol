// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ReentrancyGuardTransientUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {BaoOwnable} from "@bao/BaoOwnable.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";

/// @notice Shared base for v3 price aggregators.
/// @dev Concrete implementations override `latestAnswer()` and implement identity getters.
abstract contract HarborPriceAggregator_v3 is
    IHarborPriceAggregatorV3,
    UUPSUpgradeable,
    ReentrancyGuardTransientUpgradeable,
    BaoOwnable
{
    /// @custom:storage-location erc7201:harbor.storage.PriceAggregatorV3
    struct HarborPriceAggregatorV3Storage {
        // Reserved for future v3 mutable state.
        uint256 _reserved0;
    }

    /// @notice The storage hash for the shared-with-proxy storage
    // chisel eval 'keccak256(abi.encode(uint256(keccak256("harbor.storage.PriceAggregatorV3")) - 1)) & ~bytes32(uint256(0xff))'
    bytes32 private constant _PRICE_AGGREGATOR_V3_STORAGE =
        0x22d39e01e70b6e32f8072ab8cd3f39c930a110555d014e358a68416cde8e3200;

    /// @notice Returns a reference to the contract state
    function _getPriceAggregatorV3Storage() private pure returns (HarborPriceAggregatorV3Storage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := _PRICE_AGGREGATOR_V3_STORAGE
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_) external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuardTransient_init();
        _initializeOwner(owner_);
    }

    function version() external pure returns (uint256) {
        return 3;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
