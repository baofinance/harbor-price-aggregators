// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink stETH/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for stETH/USD price feed
// solhint-disable-next-line contract-name-capwords
library STETH_USD {
    /// @notice Chainlink stETH/USD aggregator address on Arbitrum
    address internal constant FEED = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
