// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink ETH/USD Feed - MegaETH
/// @notice Feed address and heartbeat for ETH/USD price feed
// solhint-disable-next-line contract-name-capwords
library ETH_USD {
    /// @notice Chainlink ETH/USD aggregator address on MegaETH (8 decimals)
    address internal constant FEED = 0xcA4e254D95637DE95E2a2F79244b03380d697feD;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
