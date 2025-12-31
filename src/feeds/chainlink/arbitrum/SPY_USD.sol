// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SPY/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for SPY/USD price feed
// solhint-disable-next-line contract-name-capwords
library SPY_USD {
    /// @notice Chainlink SPY/USD aggregator address on Arbitrum
    address internal constant FEED = 0x46306F3795342117721D8DEd50fbcF6DF2b3cc10;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
