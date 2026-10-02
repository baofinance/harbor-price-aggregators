// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink ASML/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized ASML/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library ASML_USD {
    /// @notice Chainlink ASML/USD aggregator address on Robinhood
    address internal constant FEED = 0xB4106147E8cce40b7d46124090d373A71b70f87D;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
