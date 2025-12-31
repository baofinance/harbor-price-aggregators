// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink wstETH/stETH Feed - Arbitrum
/// @notice Feed address and heartbeat for wstETH/stETH rate feed
// solhint-disable-next-line contract-name-capwords
library WSTETH_STETH {
    /// @notice Chainlink wstETH/stETH aggregator address on Arbitrum
    address internal constant FEED = 0xB1552C5e96B312d0Bf8b554186F846C40614a540;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
