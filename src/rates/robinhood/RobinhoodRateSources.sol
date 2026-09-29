// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Rate Source Addresses - Robinhood Chain
/// @notice Token addresses. The syrupUSDG/USDG *rate* is Chainlink `SYRUPUSDG_USDG`, not this token:
///         `0x4085…` is a CCIP representation and `convertToAssets` reverts.
library RobinhoodRateSources {
    /// @notice syrupUSDG token on Robinhood Chain (CCIP-bridged, 6 decimals)
    address internal constant SYRUP_USDG = 0x40858070814a57FdF33a613ae84fE0a8b4a874f7;
}
