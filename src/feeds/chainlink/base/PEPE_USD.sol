// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink PEPE/USD Feed - Base
/// @notice Feed address and heartbeat for PEPE/USD price feed
// solhint-disable-next-line contract-name-capwords
library PEPE_USD {
    /// @notice Chainlink PEPE/USD aggregator address on Base
    address internal constant FEED = 0xB48ac6409C0c3718b956089b0fFE295A10ACDdad;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
