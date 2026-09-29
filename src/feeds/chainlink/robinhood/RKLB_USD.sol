// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink RKLB/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized RKLB/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library RKLB_USD {
    /// @notice Chainlink RKLB/USD aggregator address on Robinhood
    address internal constant FEED = 0x045477BF65Aef6f4F2386ad0164579e48381CC74;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
