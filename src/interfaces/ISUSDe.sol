// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @notice Interface for Staked USDe (sUSDe) ERC4626 vault
/// @dev sUSDe is an ERC4626 vault that wraps USDe tokens
/// @dev All required functions (asset, convertToAssets, totalAssets) are inherited from IERC4626
interface ISUSDe is IERC4626 {
    // All functions needed for rate calculation are already in IERC4626:
    // - asset() returns the underlying USDe token address
    // - convertToAssets(uint256 shares) converts shares to assets
    // - totalAssets() returns total assets managed by the vault
}
