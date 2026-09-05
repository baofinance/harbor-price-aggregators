// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

/// @notice Interface for Minter contracts that manage leveraged tokens
/// @dev Minter contracts track leveraged token prices relative to underlying assets
interface IMinter {
    /// @notice Return the price of a leveraged token in terms of the pegged token's underlying (18 decimals)
    /// @dev Returns leveragedToken / underlying (e.g., hsfxUSD-EUR / fxSAVE).
    ///
    ///      Zero is a value, not a failure. The leveraged token is the junior claim on a market's collateral:
    ///      its price is the collateral value less the pegged value, and the Minter caps the pegged value at
    ///      the collateral value, so a fully capped market prices the leveraged token at exactly nothing.
    ///      That is the designed behaviour of a junior claim that has been wiped out.
    ///
    ///      Unavailability arrives out of band instead. The Minter reads its own price oracle through a
    ///      validating reader that reverts when the collateral price band holds a zero, so a dead feed stops
    ///      the call rather than reaching this return value. A zero returned here therefore means "worth
    ///      nothing", never "cannot tell", and the two must not be conflated by anything reading it.
    /// @return nav The price of the leveraged token in terms of the underlying (18 decimals)
    function leveragedTokenPrice() external view returns (uint256 nav);
}
