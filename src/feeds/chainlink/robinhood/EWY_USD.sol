// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink EWY/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized EWY/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library EWY_USD {
    /// @notice Chainlink EWY/USD aggregator address on Robinhood
    address internal constant FEED = 0xEFdf54610B62A7753Ec30bDc380847c12D32e1D1;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
