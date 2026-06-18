// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink ETH/USD Feed - Monad
/// @notice Feed address and heartbeat for ETH/USD price feed
// solhint-disable-next-line contract-name-capwords
library ETH_USD {
    /// @notice Chainlink ETH/USD aggregator address on Monad
    address internal constant FEED = 0x1B1414782B859871781bA3E4B0979b9ca57A0A04;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
