// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink NBIS/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized NBIS/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library NBIS_USD {
    /// @notice Chainlink NBIS/USD aggregator address on Robinhood
    address internal constant FEED = 0xE1D87B116Ba0fe898998f1D140339D1fA1E09705;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
