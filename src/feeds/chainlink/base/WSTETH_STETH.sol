// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink wstETH/stETH Feed - Base
/// @notice Feed address and heartbeat for wstETH/stETH rate feed
// solhint-disable-next-line contract-name-capwords
library WSTETH_STETH {
    /// @notice Chainlink wstETH/stETH aggregator address on Base
    address internal constant FEED = 0xB88BAc61a4Ca37C43a3725912B1f472c9A5bc061;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
