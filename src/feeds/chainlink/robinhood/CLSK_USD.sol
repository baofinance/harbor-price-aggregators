// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink CLSK/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized CLSK/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library CLSK_USD {
    /// @notice Chainlink CLSK/USD aggregator address on Robinhood
    address internal constant FEED = 0x810c12D3a554Bc47fd39597Fe3b3AAC4941F50eF;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
