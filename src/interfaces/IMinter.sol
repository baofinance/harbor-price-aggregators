// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

/// @notice Interface for Minter contracts that manage leveraged tokens
/// @dev Minter contracts track leveraged token prices relative to underlying assets
interface IMinter {
    /// @notice Return the price of a leveraged token in terms of the pegged token's underlying (18 decimals)
    /// @dev Returns leveragedToken / underlying (e.g., hsfxUSD-EUR / fxSAVE)
    /// @return nav The price of the leveraged token in terms of the underlying (18 decimals)
    function leveragedTokenPrice() external view returns (uint256 nav);
}
