// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink AAPL/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for AAPL/USD price feed
// solhint-disable-next-line contract-name-capwords
library AAPL_USD {
    /// @notice Chainlink AAPL/USD aggregator address on Arbitrum
    address internal constant FEED = 0x8d0CC5f38f9E802475f2CFf4F9fc7000C2E1557c;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
