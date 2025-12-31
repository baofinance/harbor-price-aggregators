// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink USDE/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for USDE/USD price feed
// solhint-disable-next-line contract-name-capwords
library USDE_USD {
    /// @notice Chainlink USDE/USD aggregator address on Arbitrum
    address internal constant FEED = 0x88AC7Bca36567525A866138F03a6F6844868E0Bc;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
