// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink PLTR/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized PLTR/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library PLTR_USD {
    /// @notice Chainlink PLTR/USD aggregator address on Robinhood
    address internal constant FEED = 0x820ABedFF239034956B7A9d2F0a331f9F075eB4c;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
