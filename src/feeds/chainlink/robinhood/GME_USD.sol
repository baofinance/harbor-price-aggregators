// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink GME/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized GME/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library GME_USD {
    /// @notice Chainlink GME/USD aggregator address on Robinhood
    address internal constant FEED = 0x27C71df6A64fB476468EdF256CF72c038baB5B67;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
