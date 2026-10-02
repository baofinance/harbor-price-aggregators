// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink CRCL/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized CRCL/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library CRCL_USD {
    /// @notice Chainlink CRCL/USD aggregator address on Robinhood
    address internal constant FEED = 0x6652eDf64bA3731C4F2D3ce821A0Fb1f1f6b482a;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
