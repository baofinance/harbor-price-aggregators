// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SNDK/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized SNDK/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library SNDK_USD {
    /// @notice Chainlink SNDK/USD aggregator address on Robinhood
    address internal constant FEED = 0xfb133Fa4B7b385802B693a293606682Df47109A3;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
