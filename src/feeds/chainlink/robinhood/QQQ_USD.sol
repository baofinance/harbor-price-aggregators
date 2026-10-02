// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink QQQ/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized QQQ/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library QQQ_USD {
    /// @notice Chainlink QQQ/USD aggregator address on Robinhood
    address internal constant FEED = 0x80901d846d5D7B030F26B480776EE3b29374C2ae;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
