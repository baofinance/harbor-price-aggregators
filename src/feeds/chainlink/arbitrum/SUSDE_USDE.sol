// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink sUSDE/USDE Feed - Arbitrum
/// @notice Feed address and heartbeat for sUSDE/USDE rate feed
// solhint-disable-next-line contract-name-capwords
library SUSDE_USDE {
    /// @notice Chainlink sUSDE/USDE aggregator address on Arbitrum
    address internal constant FEED = 0x605EA726F0259a30db5b7c9ef39Df9fE78665C44;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
