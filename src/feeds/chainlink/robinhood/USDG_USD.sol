// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink USDG/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood USDG/USD (Global Dollar).
/// @dev Crypto stablecoin, not `us_equities_24/5`. Heartbeat 86400; silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library USDG_USD {
    /// @notice Chainlink USDG/USD aggregator address on Robinhood
    address internal constant FEED = 0x61B7e5650328764B076A108EFF5fa7282a1B9aD2;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
