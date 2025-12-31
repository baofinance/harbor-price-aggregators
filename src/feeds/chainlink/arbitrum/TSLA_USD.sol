// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink TSLA/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for TSLA/USD price feed
// solhint-disable-next-line contract-name-capwords
library TSLA_USD {
    /// @notice Chainlink TSLA/USD aggregator address on Arbitrum
    address internal constant FEED = 0x3609baAa0a9b1f0FE4d6CC01884585d0e191C3E3;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
