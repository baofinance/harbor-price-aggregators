// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink DOGE/USD Feed - Base
/// @notice Feed address and heartbeat for DOGE/USD price feed
// solhint-disable-next-line contract-name-capwords
library DOGE_USD {
    /// @notice Chainlink DOGE/USD aggregator address on Base
    address internal constant FEED = 0x8422f3d3CAFf15Ca682939310d6A5e619AE08e57;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
