// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink MSTR/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized MSTR/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library MSTR_USD {
    /// @notice Chainlink MSTR/USD aggregator address on Robinhood
    address internal constant FEED = 0x396118bdFB181e6240E74D243F266B061c0edc3D;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
