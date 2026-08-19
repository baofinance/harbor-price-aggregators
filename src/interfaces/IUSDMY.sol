// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @notice Interface for USDMY ERC4626 vault
/// @dev USDMY is an ERC4626 vault that wraps USDM tokens
/// @dev All required functions (asset, convertToAssets, totalAssets) are inherited from IERC4626
interface IUSDMY is IERC4626 {} // solhint-disable-line no-empty-blocks
