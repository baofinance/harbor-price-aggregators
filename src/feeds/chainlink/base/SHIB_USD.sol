// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SHIB/USD Feed - Base
/// @notice Feed address and heartbeat for SHIB/USD price feed
// solhint-disable-next-line contract-name-capwords
library SHIB_USD {
    /// @notice Chainlink SHIB/USD aggregator address on Base
    address internal constant FEED = 0xC8D5D660bb585b68fa0263EeD7B4224a5FC99669;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
