// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink META/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for META/USD price feed
// solhint-disable-next-line contract-name-capwords
library META_USD {
    /// @notice Chainlink META/USD aggregator address on Arbitrum
    address internal constant FEED = 0xcd1bd86fDc33080DCF1b5715B6FCe04eC6F85845;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
