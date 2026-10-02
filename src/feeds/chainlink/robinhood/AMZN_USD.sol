// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink AMZN/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized AMZN/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library AMZN_USD {
    /// @notice Chainlink AMZN/USD aggregator address on Robinhood
    address internal constant FEED = 0xD5a1508ceD74c084eBf3cBe853e2C968fB2a651C;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
