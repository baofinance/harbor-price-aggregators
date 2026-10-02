// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink GOOGL/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized GOOGL/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library GOOGL_USD {
    /// @notice Chainlink GOOGL/USD aggregator address on Robinhood
    address internal constant FEED = 0xF6f373a037c30F0e5010d854385cA89185AE638b;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
