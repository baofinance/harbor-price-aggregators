// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SPY/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized SPY/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library SPY_USD {
    /// @notice Chainlink SPY/USD aggregator address on Robinhood
    address internal constant FEED = 0x319724394D3A0e3669269846abE664Cd621f9f6A;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
