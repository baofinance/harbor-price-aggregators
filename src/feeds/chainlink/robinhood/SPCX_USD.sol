// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SPCX/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized SPCX/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library SPCX_USD {
    /// @notice Chainlink SPCX/USD aggregator address on Robinhood
    address internal constant FEED = 0xB265810950ba6c5C0Ff821c9963014a56fD8Bffb;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
