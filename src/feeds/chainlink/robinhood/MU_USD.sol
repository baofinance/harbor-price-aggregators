// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink MU/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized MU/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library MU_USD {
    /// @notice Chainlink MU/USD aggregator address on Robinhood
    address internal constant FEED = 0x425EEFdCf05ed6526C3cE61Af99429A228a6d596;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
