// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SPCX/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for SPCX/USD (SpaceX Class A) price feed
/// @dev ENS: spcx-usd.data.eth
// solhint-disable-next-line contract-name-capwords
library SPCX_USD {
    /// @notice Chainlink SPCX/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0x0a585B784513AB053563deE3CF830c633e4ff6c7;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
