// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink wstETH/stETH Feed - MegaETH
/// @notice Feed address and heartbeat for wstETH/stETH rate feed
// solhint-disable-next-line contract-name-capwords
library STETH_ETH {
    /// @notice Chainlink wstETH/stETH aggregator address on MegaETH
    address internal constant FEED = 0x556ccb034718065067A3d323DDe0B0A27637f5ba;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
