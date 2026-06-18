// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink sUSDE/USD Feed - Monad
/// @notice Feed address and heartbeat for sUSDE/USD price feed
// solhint-disable-next-line contract-name-capwords
library SUSDE_USD {
    /// @notice Chainlink sUSDE/USD aggregator address on Monad
    address internal constant FEED = 0xB7E7A36A0Fc6543C10f4F9B60E942F1b628f2a13;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
