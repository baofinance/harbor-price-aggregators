// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink BTC/USD Feed - MegaETH
/// @notice Feed address and heartbeat for BTC/USD price feed
// solhint-disable-next-line contract-name-capwords
library BTC_USD {
    /// @notice Chainlink BTC/USD aggregator address on MegaETH (8 decimals)
    address internal constant FEED = 0xc6E3007B597f6F5a6330d43053D1EF73cCbbE721;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
