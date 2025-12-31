// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink NVDA/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for NVDA/USD price feed
// solhint-disable-next-line contract-name-capwords
library NVDA_USD {
    /// @notice Chainlink NVDA/USD aggregator address on Arbitrum
    address internal constant FEED = 0x4881A4418b5F2460B21d6F08CD5aA0678a7f262F;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
