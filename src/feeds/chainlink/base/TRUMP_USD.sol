// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink TRUMP/USD Feed - Base
/// @notice Feed address and heartbeat for TRUMP/USD price feed
// solhint-disable-next-line contract-name-capwords
library TRUMP_USD {
    /// @notice Chainlink TRUMP/USD aggregator address on Base
    address internal constant FEED = 0x7bAfa1Af54f17cC0775a1Cf813B9fF5dED2C51E5;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
