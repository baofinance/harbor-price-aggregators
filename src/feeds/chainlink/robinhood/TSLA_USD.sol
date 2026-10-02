// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink TSLA/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized TSLA/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library TSLA_USD {
    /// @notice Chainlink TSLA/USD aggregator address on Robinhood
    address internal constant FEED = 0x4A1166a659A55625345e9515b32adECea5547C38;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
