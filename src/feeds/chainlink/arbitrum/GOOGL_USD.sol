// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink GOOGL/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for GOOGL/USD price feed
// solhint-disable-next-line contract-name-capwords
library GOOGL_USD {
    /// @notice Chainlink GOOGL/USD aggregator address on Arbitrum
    address internal constant FEED = 0x1D1a83331e9D255EB1Aaf75026B60dFD00A252ba;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
