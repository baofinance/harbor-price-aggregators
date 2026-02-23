// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SOL/USD Feed - MegaETH
/// @notice Feed address and heartbeat for SOL/USD price feed
// solhint-disable-next-line contract-name-capwords
library SOL_USD {
    /// @notice Chainlink SOL/USD aggregator address on MegaETH (18 decimals)
    address internal constant FEED = 0x53c05390FdfDB63526Ac0814825093A68eaddC87;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
