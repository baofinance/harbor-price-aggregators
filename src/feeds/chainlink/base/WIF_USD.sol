// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink WIF/USD Feed - Base
/// @notice Feed address and heartbeat for WIF/USD price feed
// solhint-disable-next-line contract-name-capwords
library WIF_USD {
    /// @notice Chainlink WIF/USD aggregator address on Base
    address internal constant FEED = 0x674940e1dBf7FD841b33156DA9A88afbD95AaFBa;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
