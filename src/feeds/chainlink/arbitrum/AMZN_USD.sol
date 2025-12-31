// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink AMZN/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for AMZN/USD price feed
// solhint-disable-next-line contract-name-capwords
library AMZN_USD {
    /// @notice Chainlink AMZN/USD aggregator address on Arbitrum
    address internal constant FEED = 0xd6a77691f071E98Df7217BED98f38ae6d2313EBA;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
